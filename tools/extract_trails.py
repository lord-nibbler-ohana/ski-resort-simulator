#!/usr/bin/env python3
"""
Extract trail paths from Sirdal Fjellpark trail map using color thresholding.

Strategy: for each color mask, skeletonize, find endpoints (1-neighbor pixels),
then trace from each endpoint through the skeleton graph to find full trail paths.

Usage:  python3 tools/extract_trails.py [--debug]
"""

import sys
import os
import cv2
import numpy as np

MAP_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "trail_map.png")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..")
DEBUG = "--debug" in sys.argv


def load_map():
    img = cv2.imread(MAP_PATH)
    if img is None:
        sys.exit(f"ERROR: Could not load {MAP_PATH}")
    print(f"Map: {img.shape[1]}x{img.shape[0]}")
    return img


def create_mask(hsv, h_ranges, s_range, v_range):
    mask = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for hl, hh in h_ranges:
        mask |= cv2.inRange(hsv, np.array([hl, s_range[0], v_range[0]]),
                                  np.array([hh, s_range[1], v_range[1]]))
    return mask


def mask_non_trail(mask, shape):
    h, w = shape[:2]
    mask[int(h * 0.82):, :] = 0
    mask[int(h * 0.70):, int(w * 0.85):] = 0
    mask[:6, :] = 0; mask[:, :6] = 0; mask[:, w-6:] = 0
    return mask


def cleanup(mask, close_k=7, open_k=3):
    kc = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (close_k, close_k))
    ko = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (open_k, open_k))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kc, iterations=2)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, ko, iterations=1)
    return mask


def skeletonize(mask):
    skel = np.zeros_like(mask)
    elem = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
    work = mask.copy()
    while True:
        eroded = cv2.erode(work, elem)
        skel |= cv2.subtract(work, cv2.dilate(eroded, elem))
        work = eroded
        if cv2.countNonZero(work) == 0:
            break
    return skel


def neighbor_count_map(skel):
    """For each skeleton pixel, count its 8-connected skeleton neighbors."""
    kernel = np.ones((3, 3), dtype=np.uint8)
    kernel[1, 1] = 0
    binary = (skel > 0).astype(np.uint8)
    return cv2.filter2D(binary, -1, kernel) * binary


def find_endpoints(skel):
    """Find skeleton pixels with exactly 1 neighbor (line endpoints)."""
    nc = neighbor_count_map(skel)
    ys, xs = np.where(nc == 1)
    return list(zip(ys.tolist(), xs.tolist()))


def trace_from_endpoint(skel_binary, start_yx, visited_global=None):
    """Walk along the skeleton from an endpoint, returning ordered (y,x) points.
    Follows the path until hitting a dead end or an already-visited pixel.
    At junctions, picks the neighbor closest to the current direction."""
    h, w = skel_binary.shape
    visited = set()
    path = [start_yx]
    visited.add(start_yx)
    if visited_global:
        visited_global.add(start_yx)

    while True:
        cy, cx = path[-1]
        # Find unvisited skeleton neighbors
        neighbors = []
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                if dy == 0 and dx == 0:
                    continue
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and skel_binary[ny, nx] > 0:
                    if (ny, nx) not in visited:
                        neighbors.append((ny, nx))

        if not neighbors:
            break

        if len(neighbors) == 1:
            nxt = neighbors[0]
        else:
            # At a junction: pick neighbor most aligned with current direction
            if len(path) >= 2:
                dy_cur = path[-1][0] - path[-2][0]
                dx_cur = path[-1][1] - path[-2][1]
                mag = max(np.sqrt(dy_cur**2 + dx_cur**2), 0.001)
                dy_cur /= mag; dx_cur /= mag
            else:
                dy_cur, dx_cur = 1.0, 0.0  # default: downward

            best_dot = -999
            nxt = neighbors[0]
            for ny, nx in neighbors:
                dy_n = ny - cy; dx_n = nx - cx
                mag_n = max(np.sqrt(dy_n**2 + dx_n**2), 0.001)
                dot = (dy_n/mag_n) * dy_cur + (dx_n/mag_n) * dx_cur
                if dot > best_dot:
                    best_dot = dot
                    nxt = (ny, nx)

        path.append(nxt)
        visited.add(nxt)
        if visited_global is not None:
            visited_global.add(nxt)

    return path


def subsample_path(path_yx, every=5):
    """Take every Nth point to reduce density before simplification."""
    if len(path_yx) <= every * 2:
        return path_yx
    result = [path_yx[0]]
    for i in range(every, len(path_yx) - 1, every):
        result.append(path_yx[i])
    result.append(path_yx[-1])
    return result


def simplify_to_xy(path_yx, epsilon=10.0):
    """Douglas-Peucker simplification, returns [(x,y), ...]."""
    if len(path_yx) < 2:
        return []
    pts = np.array([[p[1], p[0]] for p in path_yx], dtype=np.float32).reshape(-1, 1, 2)
    simplified = cv2.approxPolyDP(pts, epsilon, closed=False)
    return [(int(p[0][0]), int(p[0][1])) for p in simplified]


def thinness(area, bw, bh):
    return area / max(bw * bh, 1)


def extract_trails(img, hsv, color_name, h_ranges, s_range, v_range,
                   close_k=7, min_path_len=80, max_thinness=1.0, epsilon=12.0):
    """Full pipeline: mask → skeleton → trace from endpoints → simplify."""
    print(f"\n--- {color_name} ---")
    mask = create_mask(hsv, h_ranges, s_range, v_range)
    mask = mask_non_trail(mask, img.shape)
    raw = cv2.countNonZero(mask)
    print(f"  Raw: {raw} px ({100*raw/(img.shape[0]*img.shape[1]):.2f}%)")

    mask = cleanup(mask, close_k=close_k)

    # Filter fat blobs (lakes etc) if thinness limit set
    if max_thinness < 1.0:
        nl, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
        for i in range(1, nl):
            a = stats[i, cv2.CC_STAT_AREA]
            bw, bh = stats[i, cv2.CC_STAT_WIDTH], stats[i, cv2.CC_STAT_HEIGHT]
            if thinness(a, bw, bh) > max_thinness and a > 500:
                mask[labels == i] = 0

    cleaned = cv2.countNonZero(mask)
    print(f"  Cleaned: {cleaned} px")
    if cleaned < 50:
        return [], mask

    skel = skeletonize(mask)
    skel_binary = (skel > 0).astype(np.uint8)
    skel_px = cv2.countNonZero(skel)
    print(f"  Skeleton: {skel_px} px")

    # Find all endpoints
    endpoints = find_endpoints(skel)
    print(f"  Endpoints: {len(endpoints)}")

    # Trace from each endpoint
    raw_paths = []
    visited_global = set()
    # Sort endpoints by y (trace from summits first — lower y)
    endpoints.sort(key=lambda p: p[0])

    for ep in endpoints:
        if ep in visited_global:
            continue
        path = trace_from_endpoint(skel_binary, ep, visited_global)
        if len(path) >= min_path_len:
            raw_paths.append(path)

    print(f"  Raw paths (len>={min_path_len}): {len(raw_paths)}")

    # Subsample + simplify
    paths = []
    for i, rp in enumerate(raw_paths):
        sub = subsample_path(rp, every=3)
        simplified = simplify_to_xy(sub, epsilon=epsilon)
        if len(simplified) >= 2:
            # Compute bounding box
            xs = [p[0] for p in simplified]
            ys = [p[1] for p in simplified]
            paths.append({
                "name": f"{color_name}_{i+1}",
                "points": simplified,
                "pixel_length": len(rp),
                "bbox": (min(xs), min(ys), max(xs)-min(xs), max(ys)-min(ys)),
                "centroid": (np.mean(xs), np.mean(ys)),
            })

    # Sort by pixel length (longest first)
    paths.sort(key=lambda p: p["pixel_length"], reverse=True)
    for i, p in enumerate(paths):
        p["name"] = f"{color_name}_{i+1}"

    print(f"  Final: {len(paths)} paths")
    for p in paths:
        cx, cy = p["centroid"]
        print(f"    {p['name']}: {len(p['points'])} pts, {p['pixel_length']}px, "
              f"centroid=({int(cx)},{int(cy)})")

    return paths, mask


def save_vis(img, all_paths, filename):
    vis = img.copy()
    bgr = {"Red": (0,0,255), "Green": (0,220,0), "Blue": (255,150,0)}
    for color, paths in all_paths.items():
        c = bgr.get(color, (200,200,0))
        for p in paths:
            pts = p["points"]
            for j in range(len(pts)-1):
                cv2.line(vis, pts[j], pts[j+1], c, 4)
            for pt in pts:
                cv2.circle(vis, pt, 7, (0,255,255), -1)
            if pts:
                cv2.putText(vis, p["name"], (pts[0][0]+10, pts[0][1]-10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, c, 2)
    out = os.path.join(OUTPUT_DIR, filename)
    cv2.imwrite(out, vis)
    print(f"\nSaved: {out}")


def format_gdscript(all_paths):
    lines = ["# Auto-extracted trail coordinates from trail map",
             "# Generated by tools/extract_trails.py\n"]
    for color, paths in all_paths.items():
        lines.append(f"# === {color} ({len(paths)}) ===\n")
        for p in paths:
            cx, cy = p["centroid"]
            lines.append(f'# {p["name"]} — {p["pixel_length"]}px, '
                         f'centroid({int(cx)},{int(cy)})')
            lines.append(f'_set_curve(node, "TODO", [')
            for i, (x, y) in enumerate(p["points"]):
                comma = "," if i < len(p["points"])-1 else ""
                lines.append(f"\tVector2({x}, {y}){comma}")
            lines.append("])\n")
    return "\n".join(lines)


def main():
    img = load_map()
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    all_paths = {}; all_masks = {}

    r, rm = extract_trails(img, hsv, "Red",
        h_ranges=[(0,10),(170,180)], s_range=(150,255), v_range=(180,255),
        close_k=7, min_path_len=60, max_thinness=1.0, epsilon=12.0)
    all_paths["Red"] = r; all_masks["Red"] = rm

    g, gm = extract_trails(img, hsv, "Green",
        h_ranges=[(40,65)], s_range=(100,255), v_range=(100,255),
        close_k=9, min_path_len=60, max_thinness=1.0, epsilon=12.0)
    all_paths["Green"] = g; all_masks["Green"] = gm

    b, bm = extract_trails(img, hsv, "Blue",
        h_ranges=[(95,120)], s_range=(120,255), v_range=(80,230),
        close_k=5, min_path_len=60, max_thinness=0.15, epsilon=12.0)
    all_paths["Blue"] = b; all_masks["Blue"] = bm

    total = sum(len(v) for v in all_paths.values())
    print(f"\n=== Total: {total} paths ===")

    out = os.path.join(OUTPUT_DIR, "extracted_paths.gd")
    with open(out, "w") as f:
        f.write(format_gdscript(all_paths))
    print(f"GDScript: {out}")
    save_vis(img, all_paths, "debug_extract_all.png")

    if DEBUG:
        for name, mask in all_masks.items():
            p = os.path.join(OUTPUT_DIR, f"debug_mask_{name.lower()}.png")
            cv2.imwrite(p, mask); print(f"Mask: {p}")


if __name__ == "__main__":
    main()
