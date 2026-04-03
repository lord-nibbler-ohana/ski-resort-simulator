#!/usr/bin/env python3
"""
Guided trail extraction using color masks as road network + BFS pathfinding.

Strategy:
  1. Load masks, remove trail-number circles, dilate for connectivity
  2. For each known trail, find topmost/bottommost mask pixels in its zone
  3. BFS from top to bottom through the mask
  4. Extend endpoints to known lift station positions
  5. Simplify and output Vector2 arrays

Usage: python3 tools/guided_extract.py
"""

import os, sys, cv2, numpy as np
from collections import deque

MAP_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "trail_map.png")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..")


def load_mask(name):
    path = os.path.join(OUTPUT_DIR, f"debug_mask_{name}.png")
    if not os.path.exists(path):
        sys.exit(f"Missing: {path}\nRun: python3 tools/extract_trails.py --debug")
    return cv2.imread(path, cv2.IMREAD_GRAYSCALE)


def remove_circles(mask, max_area=800):
    """Remove small roughly-square blobs (numbered trail markers)."""
    nl, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    out = mask.copy()
    removed = 0
    for i in range(1, nl):
        a = stats[i, cv2.CC_STAT_AREA]
        w, h = stats[i, cv2.CC_STAT_WIDTH], stats[i, cv2.CC_STAT_HEIGHT]
        if 30 < a < max_area and max(w,h)/max(min(w,h),1) < 2.0:
            out[labels == i] = 0
            removed += 1
    return out, removed


def prepare_mask(mask, dilate_k=15):
    cleaned, n = remove_circles(mask)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (dilate_k, dilate_k))
    dilated = cv2.dilate(cleaned, kernel, iterations=1)
    return dilated, cleaned, n


def nearest_mask_px(mask, px, py, radius=400):
    h, w = mask.shape
    for r in range(0, radius, 2):
        y1, y2 = max(0, py-r), min(h, py+r+1)
        x1, x2 = max(0, px-r), min(w, px+r+1)
        region = mask[y1:y2, x1:x2]
        if region.max() > 0:
            ys, xs = np.where(region > 0)
            dists = (xs + x1 - px)**2 + (ys + y1 - py)**2
            idx = np.argmin(dists)
            return (int(xs[idx] + x1), int(ys[idx] + y1))
    return None


def astar(mask, sx, sy, ex, ey, max_steps=500000):
    """A* pathfinding through white mask pixels."""
    import heapq
    h, w = mask.shape
    if mask[sy,sx] == 0 or mask[ey,ex] == 0:
        return None
    # Priority queue: (estimated_total, steps, y, x)
    pq = [(abs(sx-ex)+abs(sy-ey), 0, sy, sx)]
    visited = np.zeros((h,w), dtype=bool)
    parent = {}
    visited[sy,sx] = True
    steps = 0
    while pq and steps < max_steps:
        _, cost, cy, cx = heapq.heappop(pq)
        steps += 1
        if abs(cx-ex) <= 2 and abs(cy-ey) <= 2:
            path = []
            while (cy,cx) in parent:
                path.append((cx,cy))
                cy,cx = parent[(cy,cx)]
            path.append((sx,sy))
            path.reverse()
            return path
        for dy,dx in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
            ny,nx = cy+dy, cx+dx
            if 0<=ny<h and 0<=nx<w and not visited[ny,nx] and mask[ny,nx]>0:
                visited[ny,nx] = True
                parent[(ny,nx)] = (cy,cx)
                new_cost = cost + 1
                heuristic = abs(nx-ex) + abs(ny-ey)
                heapq.heappush(pq, (new_cost + heuristic, new_cost, ny, nx))
    return None


def simplify(pts, epsilon=15.0):
    if len(pts) < 3: return pts
    a = np.array(pts, dtype=np.float32).reshape(-1,1,2)
    s = cv2.approxPolyDP(a, epsilon, False)
    return [(int(p[0][0]), int(p[0][1])) for p in s]


def get_zone_extent(mask, x1, x2):
    """Get topmost and bottommost mask pixel in x-range."""
    region = mask[:, x1:x2]
    if region.max() == 0:
        return None, None
    ys, xs = np.where(region > 0)
    xs += x1
    top_y = int(ys.min())
    bot_y = int(ys.max())
    top_mask = ys < (top_y + 20)
    bot_mask = ys > (bot_y - 20)
    top_pt = (int(xs[top_mask].mean()), top_y)
    bot_pt = (int(xs[bot_mask].mean()), bot_y)
    return top_pt, bot_pt


def trace_trail(mask_d, mask_c, name, x_range, y_range=None):
    """Trace a trail through the mask in given x/y range."""
    h, w = mask_d.shape

    # Apply y-range constraint by zeroing out pixels outside range
    if y_range:
        work = mask_d.copy()
        work[:y_range[0], :] = 0
        work[y_range[1]:, :] = 0
    else:
        work = mask_d

    top, bot = get_zone_extent(work, x_range[0], x_range[1])
    if top is None:
        print(f"  {name}: no mask pixels in x={x_range}" + (f" y={y_range}" if y_range else ""))
        return None

    snap_top = nearest_mask_px(work, top[0], top[1], radius=50)
    snap_bot = nearest_mask_px(work, bot[0], bot[1], radius=50)
    if not snap_top or not snap_bot:
        return None

    path = astar(work, snap_top[0], snap_top[1], snap_bot[0], snap_bot[1])
    if path is None:
        print(f"  {name}: BFS failed {snap_top}->{snap_bot}")
        return None

    # Subsample
    step = max(1, len(path) // 150)
    sub = [path[i] for i in range(0, len(path), step)]
    if sub[-1] != path[-1]:
        sub.append(path[-1])

    # Snap to clean mask centerline
    snapped = []
    for px, py in sub:
        n = nearest_mask_px(mask_c, px, py, radius=15)
        snapped.append(n if n else (px, py))

    pts = simplify(snapped, epsilon=15.0)
    print(f"  {name}: {len(path)} raw -> {len(pts)} pts")
    return pts


# Trail definitions: name, color, x_range for zone, summit_xy, base_xy
# summit/base are where lifts start/end (from zoomed screenshots)
# Trail defs: name, color, (x_min, x_max), (y_min, y_max) or None for auto
TRAIL_DEFS = [
    # === Tjørhomfjellet ===
    ("TrailTjorhomGreen1", "green", (600, 1700), None),
    ("TrailTjorhomBlue1",  "blue",  (900, 1650), (880, 1320)),
    ("TrailTjorhomRed1",   "red",   (500, 1700), None),

    # === Hulderheimen ===
    ("TrailHulderGreen1",  "green", (0, 800), None),

    # === Nyestøl ===
    ("TrailNyestolGreen1", "green", (1700, 3200), None),
    ("TrailNyestolBlue1",  "blue",  (2000, 2300), (970, 1140)),
    ("TrailNyestolRed1",   "red",   (2800, 3300), None),

    # === Ålsheia ===
    ("TrailAlsheiaGreen1", "green", (3100, 3500), None),
    ("TrailAlsheiaBlue1",  "blue",  (3800, 4600), (620, 1700)),
    ("TrailAlsheiaBlue2",  "blue",  (4400, 5300), (920, 1800)),
    ("TrailAlsheiaRed1",   "red",   (3200, 5100), None),

    # === Connections ===
    ("TrailConnectTjorhomNyestol", "blue",  (1200, 2400), (600, 1300)),
    ("TrailConnectNyestolAlsheia", "green", (2500, 4200), None),
]


def main():
    print("Loading masks...")
    raw = {c: load_mask(c) for c in ["red", "green", "blue"]}

    masks_d, masks_c = {}, {}
    # Blue needs heavier dilation to bridge disconnected regions
    dilate_sizes = {"red": 15, "green": 15, "blue": 25}
    for c, m in raw.items():
        d, cl, n = prepare_mask(m, dilate_k=dilate_sizes[c])
        masks_d[c] = d
        masks_c[c] = cl
        print(f"  {c}: removed {n} circles, dilated {cv2.countNonZero(d)} px")

    results = []

    print("\n=== Tracing trails ===")
    for name, color, x_range, y_range in TRAIL_DEFS:
        pts = trace_trail(masks_d[color], masks_c[color], name, x_range, y_range)
        if pts and len(pts) >= 2:
            results.append((name, pts))

    # Lifts: snap endpoints to nearest mask pixels, create simple 3-point paths
    print("\n=== Lifts (endpoint snapping) ===")
    combined = np.zeros_like(raw["red"])
    for m in raw.values():
        combined |= m

    LIFTS = [
        ("LiftTjorhomChair", (1000, 1800), (1300, 380)),
        ("LiftTjorhomTbar",  (1100, 1800), (1200, 900)),
        ("LiftHulderButton", (420, 1850),  (350, 1350)),
        ("LiftNyestolTbar1", (2500, 1750), (2400, 500)),
        ("LiftNyestolTbar2", (2800, 1700), (2700, 500)),
        ("LiftAlsheiaTbar1", (4000, 1750), (3950, 450)),
        ("LiftAlsheiaTbar2", (4300, 1700), (4250, 550)),
        ("LiftAlsheiaButton",(4600, 1850), (4550, 1350)),
    ]
    for name, base, summit in LIFTS:
        sb = nearest_mask_px(combined, base[0], base[1], 300)
        ss = nearest_mask_px(combined, summit[0], summit[1], 300)
        b = sb or base
        s = ss or summit
        mid = ((b[0]+s[0])//2, (b[1]+s[1])//2)
        results.append((name, [b, mid, s]))
        print(f"  {name}: {b} -> {s}")

    # Walk paths
    WALKS = [
        ("WalkHulderheimen", [(500, 2050), (460, 1950), (420, 1850)]),
        ("WalkTjorhom", [(1100, 1950), (1050, 1880), (1000, 1800)]),
        ("WalkAlsheia", [(4100, 1880), (4050, 1820), (4000, 1750)]),
    ]
    for name, pts in WALKS:
        results.append((name, pts))

    print(f"\n=== Total: {len(results)} paths ===")

    # Format as PathBuilder code
    lines = ["# Extracted trail coordinates — paste into path_builder.gd",
             "# Generated by tools/guided_extract.py\n"]

    for name, pts in results:
        lines.append(f'\t_set_curve(node, "{name}", [')
        for i, (x,y) in enumerate(pts):
            comma = "," if i < len(pts)-1 else ""
            lines.append(f"\t\tVector2({x}, {y}){comma}")
        lines.append("\t])\n")

    out_path = os.path.join(OUTPUT_DIR, "guided_paths.gd")
    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    print(f"Output: {out_path}")

    # Visualization
    img = cv2.imread(MAP_PATH)
    color_map = {"Green": (0,220,0), "Blue": (255,150,0), "Red": (0,0,255),
                 "Connect": (0,180,255), "Lift": (60,60,60), "Walk": (50,130,200)}
    for name, pts in results:
        c = (200,200,200)
        for key, bgr in color_map.items():
            if key in name:
                c = bgr; break
        for j in range(len(pts)-1):
            cv2.line(img, pts[j], pts[j+1], c, 4)
        for pt in pts:
            cv2.circle(img, pt, 6, (0,255,255), -1)
        if pts:
            cv2.putText(img, name.replace("Trail","T").replace("Lift","L"),
                        (pts[0][0]+8, pts[0][1]-8), cv2.FONT_HERSHEY_SIMPLEX, 0.45, c, 2)

    vis = os.path.join(OUTPUT_DIR, "debug_guided_extract.png")
    cv2.imwrite(vis, img)
    print(f"Visualization: {vis}")


if __name__ == "__main__":
    main()
