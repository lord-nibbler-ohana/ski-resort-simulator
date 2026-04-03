# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the game
godot

# Run all tests headless (38 tests, GUT v9.6.0)
godot --headless -s addons/gut/gut_cmdln.gd

# Run a single test file
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_resort_data.gd

# Run tests with JUnit XML output
godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=res://test_results.xml

# Import assets (regenerate .godot cache)
godot --headless --import
```

GUT config: `.gutconfig.json` at project root. Test dirs: `res://tests/unit`, `res://tests/integration`. Files must be prefixed `test_`.

## Architecture

### Autoload initialization order (defined in project.godot)

```
PathRegistry → SkierPool → LiftQueueManager → WeatherSystem → Spawner → SimulationManager
```

### Startup flow (main.gd._ready)

1. `SimulationManager._ready()` calls `ResortData.initialize()` — builds static lift/trail/parking definitions
2. `PathBuilder.build_all_paths()` — creates Path2D curves from hardcoded pixel coordinates
3. `PathRegistry.register_paths_container()` — scans and indexes all Path2D nodes by name
4. `LiftQueueManager.initialize_queues()` — creates empty FIFO queue per lift

### Skier lifecycle (state machine in skier.gd)

```
INACTIVE → WALKING → QUEUING → RIDING_LIFT → AT_SUMMIT → SKIING_DOWN → AT_BASE
                                                                          ↓
                                                              QUEUING (loop) or INACTIVE (leave)
```

Each transition **reparents** the Skier (which extends PathFollow2D) to a new Path2D via `PathRegistry.reparent_to_path()`, resetting `progress_ratio = 0.0`. This is the core movement mechanic — `_process()` advances `progress` along whatever Path2D the skier is currently a child of.

### System responsibilities

- **PathRegistry** — stores Path2D references by name, handles reparenting
- **PathBuilder** (static) — generates Curve2D paths from pixel coordinate arrays at startup
- **SkierPool** — object pool (200 pre-allocated), acquire/release avoids GC pressure
- **Spawner** — timer-based car generation (3-8s interval), weighted occupant distribution (mode=2), group creation
- **LiftQueueManager** — per-lift FIFO queues, capacity enforcement, group boarding, routes skiers to trails on arrival at summit
- **WeatherSystem** — wind/temp/visibility simulation, emits `chairlift_stopped`/`chairlift_resumed` signals when wind crosses 15 m/s threshold
- **SimulationManager** — sim speed control, group wait tracking, global stats

### Data model (data/)

`ResortData` is a static registry initialized once. It holds arrays of `LiftDefinition`, `TrailDefinition`, and `ParkingDefinition` resources. Each definition references Path2D node names (matching PathBuilder) and connected lift/trail IDs (forming a graph). Elevation data is real (560m base to 928m summit).

## Key patterns

**Speed conversion:** `kmh * MAP_PIXELS_PER_KM / 3600.0 * GAME_SPEED_MULTIPLIER` where map is 5551px wide (~2km), multiplier is 1.0 (real-time at 1x sim speed). Use sim speed 2x/4x/8x for faster viewing.

**Trail difficulty speeds:** GREEN=12, BLUE=22, RED=32 km/h base, multiplied by skier skill (0.6x beginner to 1.6x expert). Snowboarders get 0.9x penalty. Max effective speed ~50 km/h (expert on red).

**Stop points:** Skiers stop 2-6 times per run (skill-dependent: beginners 4-6, experts 2-3). Each stop lasts 5-15 seconds (sim-time). Stop points are random positions along the trail (progress_ratio 0.1–0.9).

**Adding lifts/trails:** Update both `ResortData._create_lifts/trails()` (data) and `PathBuilder._build_lift/trail_paths()` (geometry). Path node names must match between the two.

**Group system:** Cars with 2+ occupants have 60% chance of forming a group. Group members wait for each other at trail bottoms (10s timeout). Chairlifts load up to 4 group members together.

## Gotchas

- `PathFollow2D.progress_ratio` errors if the node isn't a child of a Path2D in the scene tree. Tests that call `start_skiing()`/`start_riding_lift()` must parent the skier to a test Path2D first.
- Y-axis increases downward (Godot 2D). Summit positions have lower Y values than base.
- Weather only affects the chairlift (type CHAIRLIFT). T-bars and button lifts always run.
- If a path node name in ResortData doesn't match a PathBuilder path, skiers on that route get released to the pool silently.
