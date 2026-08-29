# Architecture

> Keep this current as the project grows. When you add or restructure a major
> system, update the relevant section in the same feature branch.

## Overview

Early scaffold. The Godot project (`project.godot`, Godot 4.6, Forward+) boots a
single top-level scene: the player ship flying in a top-down view with mouse-aimed
Newtonian free flight, heading/velocity indicators, a camera that follows the
ship, and a shader-drawn reference grid. Systems are self-contained scenes wired
by node references (and, later, signals) as the game grows.

## Scene tree & entry point

- **Main scene:** `res://scenes/main/main.tscn` (set in `project.godot` →
  `run/main_scene`).
- `Main` (`Node2D`, `main.gd`) owns a `Camera2D`, the self-contained `Ship`
  scene, a `FlightIndicators` scene, and a `SpaceGrid` scene. `Main` only keeps
  the camera centered on the ship each frame. This is the current entry point;
  scene swapping is not needed yet.

## Autoloads (singletons)

| Name | Script | Responsibility |
|------|--------|----------------|
|      |        |                |

## Major systems

_One subsection per system (input, player, combat, save/load, UI, audio, ...).
For each: what it does, key scenes/scripts, and how it talks to other systems._

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
