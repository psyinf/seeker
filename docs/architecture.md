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
- **Visual is a separate scene:** `res://scenes/ship/ship_hull.tscn` +
  `res://scenes/ship/ship_hull.gd` (`class_name ShipHull`, `@tool`), instanced
  as a child of `Ship`. It renders via `_draw` an elongated diamond (kite) whose
  longer tip is the nose, and inherits the ship's rotation. **Forward is -Y**
  (nose points up). Keeping the hull out of `ship.gd` keeps drawing and flight
  logic decoupled (no god class).
- **Propulsion FX is a separate component:** `res://scenes/ship/ship_thrusters.gd`
  (`class_name ShipThrusters`, `@tool`), a child `Node2D` placed **before** the
  hull in the tree so plumes render behind it. Each frame it reads `Ship`'s
  thruster state and `_draw`s only the nozzles that are firing. It never drives
  the flight logic.
- **Propulsion is data-driven** via serializable resources so a ship's engine
  layout can be authored in the inspector and saved/loaded as a `.tres`:
  - `res://scenes/ship/thruster_nozzle.gd` (`class_name ThrusterNozzle extends
    Resource`) — one mount: `position`, expel `direction`, plume `length`/`width`,
    `inner_color`/`outer_color`, and a `channels` flag set (`MAIN`, `ROTATION`,
    `TRANSLATION`) picking which commands fire it.
  - `res://scenes/ship/propulsion_config.gd` (`class_name PropulsionConfig extends
    Resource`) — an `Array[ThrusterNozzle]`, plus `create_default()` for the stock
    single-engine + RCS layout used when `ShipThrusters.config` is unset.
  - Firing per nozzle: `MAIN` adds `main_throttle`; `ROTATION` fires when the
    nozzle's `cross(pos, -dir)` sign matches `rcs_torque` (couples form
    automatically); `TRANSLATION` fires when `(-dir) · rcs_translation > 0`.
- **Physical flight:** movement is pure Newtonian — no drag/damping, so momentum
  is never bled off automatically. `_apply_turning` builds/sheds `angular_velocity`
  under a `turn_torque / mass` limit and brakes early to arrive on the aim without
  oscillating (momentum turning). Thrust pushes along the ship's **actual nose**
  (`Vector2.UP.rotated(rotation)`) with `thrust_force / mass`, so momentum only
  points where you want once the ship has finished rotating; speed is capped at
  `max_speed`.
- **Controls (LMB), handled in `_unhandled_input`:**
  - **Click** = turn toward the point only (no thrust). The turn is *deferred* by
    `DOUBLE_CLICK_WINDOW_MS` (250 ms) so the first click of a double-click never
    rotates the ship; a second click within the window cancels it.
  - **Hold** = turn toward the cursor **and** thrust, once held past
    `hold_thrust_delay` (so a click can't sneak in a thrust blip).
  - **Double-click** = emit `context_menu_requested`; the mode opens a context
    menu at the cursor.
- **Full Stop:** `full_stop()` starts a physical retro-burn (`_apply_braking`)
  that spends `thrust_force / mass` opposite `velocity` until it settles exactly
  at rest; any manual input cancels it. This is the current "stop" order, issued
  from the context menu.
- **Mass model:** both thrust and turn are forces divided by `mass`, so
  larger-mass ships need bigger `thrust_force`/`turn_torque` for the same
  response — the hook for heavier ships carrying beefier engines.
- Tunables (`@export`): Flight — `mass`, `thrust_force`, `max_speed`,
  `hold_thrust_delay`; Turning — `turn_torque`, `max_turn_speed`,
  `angular_damping`. Hull dimensions/colors live on the `ShipHull` scene.
- **Turrets are separate components:** `res://scenes/ship/ship_turret.gd`
  (`class_name ShipTurret`, `@tool`), instanced as child(ren) of `Ship` and
  drawn **on top** of the hull. Each turret aims **independently at the mouse**
  in world space (barrel = local -Y), slews toward it at `slew_speed`, and gates
  its own `fire_rate`. On fire it spawns its `projectile_scene` at the barrel
  tip along its aim and emits `projectile_fired(projectile)`; it never adds the
  bolt to the tree itself. Weapon params (`projectile_scene`, `fire_rate`,
  `projectile_speed`) are per-turret exports, so different/multiple turrets are
  just more `ShipTurret` nodes with different values — no code changes. Two
  runtime fields let the ship/fire-control drive it: `base_velocity` (platform
  momentum added to every bolt) and `aim_override` (a world aim direction that
  supersedes mouse-tracking; `Vector2.ZERO` = aim at the cursor). Exposes
  `muzzle_position()` for the fire-control geometry.
- **Firing (RMB):** `Ship._ready` collects every `ShipTurret` child and connects
  their `projectile_fired`. **RMB** (in `_unhandled_input`) toggles `firing` on
  all turrets via `_set_firing`; the ship relays each turret's shot up through
  its own `projectile_fired`. `TacticalCombat` adds the bolt to the **world**
  node (not the ship) so it flies free of the ship's transform. Each frame the
  ship copies its `velocity` into every turret's `base_velocity`, so bolts
  inherit the hull's momentum (Newtonian: a shot fired while moving drifts).
- **Projectile:** `res://scenes/ship/projectile.tscn` + `projectile.gd`
  (`class_name Projectile`) — a self-drawing bolt that travels at its `launch()`
  velocity in a straight line and `queue_free`s after `lifetime`. `launch()` is
  fed muzzle velocity **plus** the turret's `base_velocity`.
- **Fire control (module, no hardware):** `res://scenes/ship/fire_control.gd`
  (`class_name FireControl`, `@tool`), a child `Node2D` of `Ship` with
  `top_level = true` so its overlay draws in world space. `Ship._ready` grabs it
  and calls `setup(self, turrets)`. Its `mode` is `FireControl.Mode`
  (`NONE`/`MK1`/`MK2`); the ship sets it via `set_fire_control_mode(int)`.
  **Mk1** aims turrets at the cursor and draws where the momentum-drifted bolt
  actually lands (trajectory + impact reticle + dashed drift line). **Mk2**
  solves the lead angle (`_firing_solution`: choose a barrel direction so
  `muzzle_velocity + platform_velocity` points at the cursor) and writes it to
  each turret's `aim_override`, drawing a green locked reticle (red when the ship
  outruns the muzzle and no solution exists). Emits `mode_changed(int)`.
- Public: state `velocity`, `aim_direction`, `angular_velocity`; per-frame
  thruster state `main_throttle`, `rcs_torque`, `rcs_translation` (read by
  `ShipThrusters`); method `full_stop()`; signals `context_menu_requested`,
  `projectile_fired`.
- Inputs: **LMB** click / hold / double-click (flight, see above); **RMB** hold
  = fire turrets. Signals: `context_menu_requested`, `projectile_fired`.

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

### Command bar
- Scenes/scripts: `res://scenes/ui/command_bar.tscn` + `command_bar.gd`
  (`class_name CommandBar`, a `CanvasLayer`).
- A bottom bar (`PanelContainer` anchored to the bottom edge); the root
  `Control` uses `mouse_filter = IGNORE` so only its buttons capture clicks and
  the play area stays interactive. Hosts the **fire-control selector**: a button
  that cycles None -> Mk1 -> Mk2, shows the active module in its label, and emits
  `fire_control_mode_changed(int)`. `TacticalCombat` wires that signal to
  `Ship.set_fire_control_mode`.

### Context menu
- Scenes/scripts: `res://scenes/ui/context_menu.tscn` + `context_menu.gd`
  (`class_name ContextMenu`, a `CanvasLayer`).
- Opened at the cursor on a ship double-click. A full-screen `Catcher` `Control`
  behind the panel blocks flight clicks while open and dismisses on a click
  outside. Emits orders as signals (`full_stop_requested`); `TacticalCombat`
  wires the ship's `context_menu_requested` → `open_at_mouse` and the menu's
  `full_stop_requested` → `ship.full_stop`, so the ship stays UI-free.

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
