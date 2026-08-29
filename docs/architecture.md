# Architecture

> Keep this current as the project grows. When you add or restructure a major
> system, update the relevant section in the same feature branch.

## Overview

Early scaffold. The Godot project (`project.godot`, Godot 4.6, Forward+) boots a
single top-level scene whose only job is to host a **`ModeManager`**. The manager
swaps between self-contained **game modes**; the first and only built mode is
**tactical combat** (real-time, mouse-aimed Newtonian free flight with
heading/velocity indicators, a following camera, and a shader reference grid).
Strategic-map and system-jump modes are scaffolded but not yet built. Systems are
self-contained scenes wired by node references (and, later, signals).

## Scene tree & entry point

- **Main scene:** `res://scenes/main/main.tscn` (set in `project.godot` →
  `run/main_scene`). It holds a `Main` root and a `ModeManager` child; the
  manager instances the active mode scene as its own child.
- **Tactical combat mode** (`res://scenes/modes/tactical_combat/`): a
  `TacticalCombat` (`Node2D`) owning a `Camera2D`, the `Ship`, `FlightIndicators`
  and `SpaceGrid` scenes. It only keeps the camera centered on the ship.

## Autoloads (singletons)

| Name | Script | Responsibility |
|------|--------|----------------|
|      |        |                |

## Major systems

_One subsection per system (input, player, combat, save/load, UI, audio, ...).
For each: what it does, key scenes/scripts, and how it talks to other systems._

### Modes
- Script: `res://scripts/mode_manager.gd` (`class_name ModeManager`).
- Holds a `Mode` enum (`TACTICAL_COMBAT`, `STRATEGIC_MAP`, `SYSTEM_JUMP`) and a
  `PackedScene` per mode (`@export`). `switch_to(mode)` frees the current mode
  node and instances the new one as its child, then emits `mode_changed`.
- Only `tactical_combat_scene` is assigned today; the others are placeholders.

### Ship (player)
- Scenes/scripts: `res://scenes/ship/ship.tscn` + `res://scenes/ship/ship.gd`
  (`class_name Ship`, `@tool`).
- Rendered via `_draw` as an elongated diamond (kite): the longer tip is the
  nose. **Forward is -Y** (nose points up).
- **Free flight:** in `_physics_process`, while the **left mouse button** is held
  the ship aims at the cursor (`aim_direction`) and rotates to face it. The
  `thrust` input action accelerates along `aim_direction`; velocity integrates
  with a `damping` factor and is capped at `max_speed` (Newtonian drift).
- Tunables (`@export`): hull dimensions/colors, `thrust_accel`, `max_speed`,
  `damping`.
- Public state read by others: `velocity`, `aim_direction`.
- Inputs: `thrust` (left mouse / Space / W). Signals: none yet.

### Flight indicators
- Scenes/scripts: `res://scenes/main/flight_indicators.tscn` +
  `flight_indicators.gd` (`class_name FlightIndicators`), composing two
  `VectorArrow` instances.
- Follows the ship and orients two arrows: **aim** (amber, desired heading) and
  **velocity** (green, prograde; hidden below `velocity_min_speed`). Reads the
  ship's public state via an injected `ship_path`; it never drives the ship.
- `VectorArrow` (`res://scenes/main/vector_arrow.tscn` + `vector_arrow.gd`) is a
  reusable arrow built from a `Line2D` shaft + `Polygon2D` head, oriented by
  `rotation` and sized by `length` — no custom `_draw`.

### Space grid
- Scenes/scripts: `res://scenes/main/space_grid.tscn` + `space_grid.gd`
  (`class_name SpaceGrid`) + `space_grid.gdshader`.
- A `CanvasLayer` (layer -1) with a full-screen `ColorRect` whose `canvas_item`
  shader draws a world-fixed grid; `space_grid.gd` feeds a `world_offset` uniform
  from the camera each frame so the grid scrolls with movement. Assumes zoom 1.

## Data & resources

_Custom `Resource` types and where game data lives (`.tres` files)._

## Communication patterns

_How systems are decoupled — signals, EventBus autoload, direct calls. See
[guidelines.md](guidelines.md#node--scene-patterns)._

- Cross-scene references are injected as `@export var *_path: NodePath` and
  resolved in `_ready` with `get_node_or_null(...)`. Readers (indicators, grid,
  camera follow) only **read** their target's public state — one-way, no
  coupling back.

## Key decisions

_Short list of structural decisions and the "why". Detailed reasoning and
chronology go in [devlog.md](devlog.md)._

- **Node refs via `NodePath` exports, not typed node exports.** Hand-authored
  `.tscn` node-object exports (`@export var x: SomeNode`) did not bind; exporting
  a `NodePath` and resolving in `_ready` is reliable and headless-safe.
- **Visuals as scene nodes, not `_draw`.** Heading vectors are `Line2D` +
  `Polygon2D` (`VectorArrow`); the reference grid is a shader on a `ColorRect`.
- **Newtonian free flight**, mouse aims only while the left button is held so the
  ship can coast on a fixed heading.
