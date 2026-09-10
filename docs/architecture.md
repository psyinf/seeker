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
  `TacticalCombat` (`Node2D`) owning a `Camera2D`, the `Ship`, `FlightIndicators`,
  an `EdgeMarkers` overlay (off-screen target markers) and `SpaceGrid` scenes. It
  only keeps the camera centered on the ship.

## Autoloads (singletons)

| Name | Script | Responsibility |
|------|--------|----------------|
|      |        |                |

## Major systems

_One subsection per system (input, player, combat, save/load, UI, audio, ...).
For each: what it does, key scenes/scripts, and how it talks to other systems._

### Modes
- Script: `res://scripts/mode_manager.gd` (`class_name ModeManager`).
- Holds a `Mode` enum (`TACTICAL_COMBAT`, `STRATEGIC_MAP`, `SYSTEM_JUMP`,
  `SHIP_EDITOR`) and a `PackedScene` per mode (`@export`). `switch_to(mode,
  payload := null)` frees the current mode node, instances the new one as its
  child, calls `setup(payload)` on it when the method exists and a payload is
  given, then emits `mode_changed`.
- `tactical_combat_scene` and `ship_editor_scene` are assigned; `main.tscn` boots
  into `SHIP_EDITOR` (`initial_mode = 3`). The strategic/jump scenes are still
  placeholders. The editor's **Test Flight** hands its `ShipDesign` to tactical
  combat via `switch_to(TACTICAL_COMBAT, design)`, and tactical combat's **Back to
  Designer** button returns it via `switch_to(SHIP_EDITOR, design)` — a symmetric
  round trip carried by the payload.

### Ship (player)
- Scenes/scripts: `res://scenes/ship/ship.tscn` + `res://scenes/ship/ship.gd`
  (`class_name Ship`, `@tool`).
- **Visual is a separate scene:** `res://scenes/ship/ship_hull.tscn` +
  `res://scenes/ship/ship_hull.gd` (`class_name ShipHull`, `@tool`), instanced
  as a child of `Ship`. It renders via `_draw` an elongated diamond (kite) whose
  longer tip is the nose, and inherits the ship's rotation. **Forward is -Y**
  (nose points up). Keeping the hull out of `ship.gd` keeps drawing and flight
  logic decoupled (no god class). _The stock ship now uses the segmented hull
  below instead; `ShipHull` remains as the simple single-piece primitive._
- **Segmented ship design (data-driven, grid-based):** ships are authored as a
  grid of cells so they can later be built in-game and drive per-part physics.
  - `res://scenes/ship/ship_segment.gd` (`class_name ShipSegment extends
    Resource`, `@tool`) — one cell: a `kind` (CORE, HULL, ARMOR, THRUSTER,
    WEAPON, REACTOR, DRONE_BAY, CARGO_HOLD, SHIELD, SENSOR, FUEL_TANK, RADIATOR),
    an integer `cell` coordinate (+X right, +Y aft), and a `facing` for
    directional parts (`facing_dir()` gives the local unit vector; UP = -Y =
    forward). `stats()` returns its baseline `ModuleStats`; `is_directional(kind)`
    flags kinds whose facing matters (thruster/weapon). A `fixed` cell (the core,
    the initial drive) can't be removed or overwritten in the editor — the player
    builds around it.
  - `res://scenes/ship/ship_design.gd` (`class_name ShipDesign extends Resource`,
    `@tool`) — the whole ship: `ship_class` (hull class name, e.g. "Nomad"),
    `cell_size` (px per cell) + `Array[ShipSegment]`, with `get_segment_at()`,
    `place()`/`remove_at()` (editor mutators), `bounds()`, `convex_hull()` (outer
    silhouette from cell corners), `core_segment()`, derived totals
    (`total_mass`, `power_generation_total`/`power_draw_total`/`net_power`,
    `total_hp`, `cargo_capacity_total`, `scan_range_total`, `build_cost_total`),
    `is_drive_extension()` (a drive cell is a nozzle unless another drive sits on
    its exhaust side, in which case it's an extension — the type is derived from
    placement, never chosen), and `create_default()` (the stock **Nomad-class**
    starter, with core + center drive `fixed`). It also carries a `footprint`
    (`Array[Vector2i]`) — the buildable cells that define the hull class; the
    outer silhouette (`convex_hull()`) is drawn from the footprint (falling back
    to occupied cells when unset), so emptying a cell keeps its shell. Mutators
    `add_to_footprint`/`remove_from_footprint` (hull authoring), `is_in_footprint`
    (buildable test), and `clear_modules` (wipe the loadout, keep hull + fixed).
    It also carries `rcs_mounts` (`Array[ThrusterNozzle]`) — the hull class's fixed
    maneuvering/retro jet points (not player-placed); the renderer draws a marker
    per mount and `Ship` fires them in flight. This is the save/load unit for a
    layout (`.tres`).
  - `res://scenes/ship/module_stats.gd` (`class_name ModuleStats extends
    Resource`, `@tool`) — baseline stat block per kind (mass, power draw/gen,
    armor HP, build cost, crew/heat = 0 for now, plus cargo/scan/fuel extras).
    `base_stats(kind)` returns a fresh copy so upgrades/modifiers can layer on.
  - `res://scenes/ship/segmented_hull.gd` (`class_name SegmentedHull extends
    Node2D`, `@tool`) — draws a `ShipDesign`: the convex-hull outer silhouette
    beneath a colored square per cell plus a kind accent (thruster nozzle, weapon
    barrel, reactor/core glow) and a small static marker per `rcs_mounts` entry.
    Pure rendering, no flight logic; falls back to `create_default()` when its
    `design` is unset. It replaces `ShipHull` in `ship.tscn` as the stock visual.
  - **In-game editor:** `res://scenes/ship/editor/ship_design_editor.tscn` +
    `ship_design_editor.gd` (a `Node2D` controller) — grid editor:
    left-click places the palette-selected kind, right-click removes, `R` rotates
    facing, the mouse wheel zooms the camera (around the cursor). Fixed cells
    reject place/remove. **Normal mode only builds within the class's hull
    footprint** (placing outside is rejected — "Outside hull"); pressing `H`
    toggles **hull-design mode** (LMB extends / RMB trims the footprint = a new
    hull type) when the editor's `allow_hull_design` export is on, so a shipped
    build can lock players to module placement. The single **Drive** palette
    entry places thruster cells whose nozzle/extension role is derived by
    placement. A code-built UI shows a module palette, live derived stats, and
    New/Clear/Save/Load/Test Flight (Clear keeps the hull + fixed cells; saves to
    `user://ship_designs/current.tres`). It reuses `SegmentedHull` (child `Hull`)
    to render and `editor_hover.gd` (child `Hover`) to highlight the cursor cell
    (yellow place / red overwrite / grey outside-hull / cyan hull-design).
    Wired into `ModeManager` as the `SHIP_EDITOR` mode; its **Test Flight** button
    switches to tactical combat carrying the current design (still runs
    standalone too — Test Flight then reports it needs a `ModeManager`).
  - **Not yet wired to flight/combat** — mass, thrust, and weapons still come from
    the existing `Ship`/turret/thruster systems. Per-segment physics is the
    planned follow-up.
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
  its own `fire_rate`. On fire it spawns its weapon's round at the barrel tip
  along its aim and emits `projectile_fired(projectile)`; it never adds the bolt
  to the tree itself. The turret carries a `WeaponConfig` (`weapon`); an assigned
  config syncs its `fire_rate`/`projectile_speed` and supplies the round scene,
  damage, color and recoil (falling back to the per-turret
  `projectile_scene`/`fire_rate`/`projectile_speed` exports, defaulting to an
  autocannon when unset). Different/multiple turrets are just more `ShipTurret`
  nodes with different weapons — no code changes. Two runtime fields let the
  ship/fire-control drive it: `base_velocity` (platform momentum added to every
  bolt) and `aim_override` (a world aim direction that supersedes mouse-tracking;
  `Vector2.ZERO` = aim at the cursor). Exposes `muzzle_position()` for the
  fire-control geometry. On each projectile shot it emits `recoil_applied(impulse)`
  (opposite the muzzle) for the ship to absorb.
- **Weapons are data:** `res://scenes/ship/weapon_config.gd` (`class_name
  WeaponConfig extends Resource`, `@tool`) — a weapon's stat block: `kind`
  (`PROJECTILE`/`GUIDED`/`BEAM`), `projectile_speed`, `damage`, `ammo_mass`,
  `fire_rate` (cadence), `homing_turn_rate`, `beam_range`, `projectile_color` and
  `projectile_scene`. `recoil()` = `projectile_speed × ammo_mass` for
  projectiles, 0 for guided/beam. Static presets `railgun()` (slow cadence, huge
  speed + damage, heavy recoil), `autocannon()` (fast cadence, small damage, light
  recoil), `missile()` (guided, homing, heavy warhead) and `laser()` (BEAM,
  continuous hitscan, per-second damage, no recoil). `from_name(StringName)` maps
  a preset name → config, so the choice serializes as a small `StringName` on the
  segment while live stats stay in code. `Ship._build_turrets` builds each turret
  from its cell's `ShipSegment.weapon`.
- **Choosing a weapon:** each WEAPON cell stores its preset in
  `ShipSegment.weapon` (a `StringName`, default `autocannon`, saved with the
  design). The editor's **Combat** category lists each weapon as its own placeable
  part (`CATEGORIES` entries carry an optional 3rd element = preset name);
  `_select_part`/`_place` pass the selected weapon into `ShipDesign.place(kind,
  cell, facing, weapon)`, which applies it only to WEAPON cells.
- **Firing (RMB):** `Ship._ready` collects every `ShipTurret` child and connects
  their `projectile_fired` and `recoil_applied`. **RMB** (in `_unhandled_input`)
  toggles `firing` on all turrets via `_set_firing`; the ship relays each turret's
  shot up through its own `projectile_fired`. `TacticalCombat` adds the bolt to
  the **world** node (not the ship) so it flies free of the ship's transform. Each
  frame the ship copies its `velocity` into every turret's `base_velocity`, so
  bolts inherit the hull's momentum (Newtonian: a shot fired while moving drifts).
- **Recoil vs. RCS:** each turret's `recoil_applied` feeds `Ship.apply_recoil`,
  which adds the delta-v (`impulse / mass`) to `velocity` immediately and logs it
  as `_recoil_debt`. `_compensate_recoil` (each physics frame) has the RCS cancel
  up to `rcs_recoil_compensation` px/s of that debt, restoring velocity and firing
  the translation thrusters (FX). Recoil arriving faster than the RCS can null
  leaves a residual kick — heavy/many weapons overwhelm station-keeping.
- **Projectile:** `res://scenes/ship/projectile.tscn` + `projectile.gd`
  (`class_name Projectile`) — a self-drawing bolt that travels at its `launch()`
  velocity in a straight line and `queue_free`s after `lifetime`. `launch()` is
  fed muzzle velocity **plus** the turret's `base_velocity`. Each physics frame it
  calls the `_steer()` hook (no-op for dumb bolts) then **ray-sweeps** its step
  (`intersect_ray`, `collide_with_areas`, mask **4 = targets**, bodies off) so
  fast bolts can't tunnel past a small target; on a hit it calls `hit(damage)` on
  the target and despawns. The ship has no physics body, so bolts pass through it.
- **Missile (guided):** `res://scenes/ship/missile.tscn` + `missile.gd`
  (`class_name Missile extends Projectile`) — overrides `_steer()` to home on the
  nearest target (`intersect_shape` on the targets layer within `seek_radius`),
  bending `_velocity` toward it at `turn_rate` while holding `cruise_speed`.
  Reuses the base sweep/damage/despawn; the turret sets its speed/turn/damage.
- **Beam (energy):** a BEAM weapon has no projectile. While firing, the turret
  ray-casts along its barrel up to `beam_range` (`_process_beam`), burns the first
  target hit for `damage × delta` (per-second), records the reach and draws the
  beam in `_draw`. No recoil (energy, no ammo mass).
- **Fire control (module, no hardware):** `res://scenes/ship/fire_control.gd`
  (`class_name FireControl`, `@tool`), a child `Node2D` of `Ship` with
  `top_level = true` so its overlay draws in world space. `Ship._ready` grabs it
  and calls `setup(self, turrets)`. Its `mode` is `FireControl.Mode`
  (`NONE`/`MK1`/`MK2`/`MK3`); the ship sets it via `set_fire_control_mode(int)`.
  **Mk1** aims turrets at the cursor and draws where the momentum-drifted bolt
  actually passes (trajectory + impact reticle + dashed drift line); flight time
  uses the bolt's closing speed along the aim (`muzzle_speed + velocity·aim`) so
  the lead matches real impact while maneuvering. **Mk2** draws only that same
  pass-through point as a clean green **lead pip** (no trajectory clutter) and
  leaves the turrets tracking the mouse — the player flies the pip onto the
  target to hit; aim stays manual. **Mk3** solves the lead angle
  (`_firing_solution`) and applies it to each turret's `aim_override`, auto-slewing
  them, drawing a green locked reticle (red when the ship outruns the
  muzzle and no solution exists). Emits `mode_changed(int)`. The shared
  `_predicted_impact()` helper feeds both Mk1 and Mk2.
- Public: state `velocity`, `aim_direction`, `angular_velocity`; per-frame
  thruster state `main_throttle`, `rcs_torque`, `rcs_translation` (read by
  `ShipThrusters`); method `full_stop()`; signals `context_menu_requested`,
  `projectile_fired`.
- Inputs: **LMB** click / hold / double-click (flight, see above); **RMB** hold
  = fire turrets. Signals: `context_menu_requested`, `projectile_fired`.

### Targets
- **Target:** `res://scenes/combat/target.tscn` + `target.gd`
  (`class_name Target`, `@tool`) — a self-drawing `Area2D` on collision layer
  **4 = targets** (mask 0, `monitoring = false`), so turret bolts detect it but
  the ship (no physics body) flies straight through: targets never block flight.
  It flashes on `hit()`, decrements `hit_points`, and on reaching zero emits
  `destroyed(at)` and frees itself. `_ready` syncs the collision circle to the
  drawn `radius`.
- **TargetField:** `res://scenes/combat/target_field.gd` (`class_name
  TargetField`) — a spawner `Node2D` that, on `_ready`, scatters `count` targets
  uniformly across an annulus (`min_radius`..`max_radius`) around its origin
  (`spawn_seed` 0 = random each run). Relays each kill up via
  `target_destroyed(at)`. Owns spawning only. Instanced in `TacticalCombat` with
  its `target_scene` pointing at `target.tscn`.

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

### Edge markers (off-screen targets)
- Scripts: `res://scenes/main/edge_marker_layer.gd` (`class_name EdgeMarkerLayer`,
  a `CanvasLayer`) + `res://scenes/main/edge_marker.gd` (`class_name EdgeMarker`,
  a `Node2D`). In `tactical_combat.tscn` as the `EdgeMarkers` node.
- Purpose-built to be extended: `EdgeMarker` is the **visual primitive** — it
  `_draw`s a triangle now, styleable by `color`/`marker_size`, with a `Shape`
  enum ready for more silhouettes. `EdgeMarkerLayer` is the **overlay manager**:
  it tracks a node **group** (`target_group`, default `targets`), and for every
  member that is off-screen (and within `max_distance`) it drives a pooled
  `EdgeMarker` clamped to the viewport border, rotated to point at the target.
- Decoupled: nodes opt in by joining the group (targets carry `groups=["targets"]`
  in `target.tscn`); the layer never references spawners. Adding another marker
  kind = another layer (different group/color) or a new `Shape`.
- Screen mapping uses `get_viewport().get_canvas_transform()` for world→screen
  (camera-aware); its `affine_inverse()` recovers the view center in world space
  for the range check. The `CanvasLayer` keeps markers screen-fixed under pan/zoom.

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
