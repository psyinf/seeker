# Devlog & Learnings

Running log of what we did, decided, and learned. Add a dated entry whenever you
complete meaningful work or hit a gotcha worth remembering. Newest entries on
top.

Entry template:

```
## YYYY-MM-DD — short title  (branch: feat/xyz)

**Did:** what changed.
**Why:** the reasoning / decision.
**Learned:** gotchas, surprises, things to remember.
**Follow-ups:** open items, if any.
```

---

## 2026-09-10 — Editor zoom, fixed cells, drive nozzle/extension  (branch: feat/ship-design-editor)

**Did:** Three editor adaptations. (1) **Zoom** — mouse wheel zooms the camera
(0.3×–4×) around the cursor; rotation moved to `R`. (2) **Fixed cells** — new
`ShipSegment.fixed`; the default Nomad marks the core and center drive fixed, and
the editor rejects removing/overwriting them ("Cell locked"). Fixed cells render
with a gold outline. (3) **Drives are two derived types** — one "Drive" palette
entry; `ShipDesign.is_drive_extension()` calls a drive a *nozzle* when nothing
sits on its exhaust side and an *extension* when another drive does, so building
forward of a nozzle extends it and building beside it starts a new column. Drives
default to venting aft.
**Why:** Matches the requested build rules: some parts are fixed but extendable,
and a "drive" is really a nozzle plus optional extensions chosen by placement, not
by the player picking a type.
**Learned:** Zoom-around-cursor = sample `get_global_mouse_position()` before and
after setting `Camera2D.zoom`, then shift the camera by the delta. Deriving
nozzle-vs-extension from neighbors (via `facing_dir`) keeps the two "types" from
ever desyncing with the layout.
**Follow-ups:** optional adjacency/connectivity enforcement (new cells must touch
the ship); wire the editor into `ModeManager`; thruster auto-placement + flight
using the derived drives.

---

## 2026-09-10 — In-game ship design editor  (branch: feat/ship-design-editor)

**Did:** Added a standalone grid **editor** for `ShipDesign`
(`scenes/ship/editor/ship_design_editor.tscn` + `.gd`, plus `editor_hover.gd`).
Left-click places the palette-selected module kind, right-click removes, mouse
wheel / R rotates the placement facing (and any directional cell under the
cursor). A code-built UI shows a 12-kind palette, live derived stats (class,
cells, mass, net power, hull HP, cargo, scan, cost) and New/Clear/Save/Load
(saves to `user://ship_designs/current.tres`). Reuses `SegmentedHull` to render
and a faint grid drawn by the root. Added `ShipDesign.place()`/`remove_at()`
mutators and `ShipSegment.is_directional()`.
**Why:** The GDD wants players to build their ship from modules; this is the
authoring surface. Kept it a self-contained scene (not yet a `ModeManager` mode)
so it can grow before we wire it into the game flow. UI is built in code to avoid
fragile `.tscn` authoring.
**Learned:** Run a specific scene with
`..\Godot_v4.6.3-stable_win64.exe --path . res://<scene>.tscn`. `_unhandled_input`
keeps palette/bar button clicks from leaking into place/remove. Hover is a child
*after* the hull so its highlight draws on top; the grid is the root's own `_draw`
so it sits behind. Load with `CACHE_MODE_IGNORE` so re-loading a saved `.tres`
doesn't hand back the cached in-memory design.
**Follow-ups:** wire the editor into `ModeManager` (or a menu); thruster
auto-placement from the hull; feed the design's aggregates into flight/combat.

---

## 2026-09-10 — Nomad-class + convex-hull outer shape  (branch: feat/ship-design-editor)

**Did:** `SegmentedHull` now draws the design's **convex hull** (cell corners →
`Geometry2D.convex_hull`) as the ship's outer silhouette beneath the module tiles
(`ShipDesign.convex_hull()`), with a TODO to derive thruster placement from that
hull. Added a `ship_class` field to `ShipDesign` and named the starter hull the
**Nomad-class** (exploration / deep-space recon); documented the class + naming
convention in [game-design.md](game-design.md).
**Why:** A single outer shape reads as one ship instead of loose tiles, and it is
derived from the design so it tracks whatever the editor produces. Ships need
distinct classes; the starter is the lonely long-haul explorer, so navigator /
guiding-light names fit (Nomad, Pathfinder, Lodestar…).
**Learned:** `Geometry2D.convex_hull` wants ≥3 points; guard degenerate designs.
Hull is drawn first so tiles layer on top and cells read as mounted.
**Follow-ups:** thruster auto-placement from the hull; the grid editor
(place/remove/rotate + palette, set `ship_class`).

---

## 2026-09-10 — Ship module types + metrics  (branch: feat/ship-design-editor)

**Did:** Extended the segmented-ship model with **module kinds and stats**. Grew
`ShipSegment.Kind` from 5 to 12 (added DRONE_BAY, CARGO_HOLD, SHIELD, SENSOR,
FUEL_TANK, RADIATOR, ARMOR — appended to keep saved indices stable). Added
`ModuleStats` (a `Resource` baseline stat block: mass, power_draw, power_gen,
armor_hp, build_cost, crew, heat, plus cargo/scan/fuel extras) with a static
`base_stats(kind)` catalog that returns a fresh copy. `ShipSegment.stats()` looks
its baseline up; `ShipDesign` now derives totals (`total_mass`, `net_power`,
`total_hp`, `cargo_capacity_total`, `scan_range_total`, `build_cost_total`) and
exposes `core_segment()`. Gave each new kind a color in `SegmentedHull`. Captured
the design in [module-design-questionnaire.md](module-design-questionnaire.md) and
a module section in [game-design.md](game-design.md).
**Why:** The GDD's upgradable-ship pillar needs modules with real trade-offs
(mass vs. power vs. armor vs. cost). Ran a questionnaire to lock the shared stat
block and module roster. Core is the must-survive cell; armor is a special
border/shell cell. Base values are tabled so upgrades/modifiers can layer on later.
**Learned:** `base_stats` returns a *copy* on purpose so a future modifier system
can mutate per-module values without corrupting the shared baseline. crew/heat are
modelled but pinned to 0 until their systems exist — cheaper than retrofitting the
stat block later. All base numbers are placeholders to tune once flight/combat
consume them.
**Follow-ups:** modifier/upgrade data model; wire aggregates into flight (mass →
accel) and combat (HP, net power budget); armor auto-placement on the outer edge.

---

## 2026-09-10 — Segmented ship design: data model + rendering  (branch: feat/ship-design-editor)

**Did:** First PR of the ship-design feature — the **data model + renderer**, no
editor UI yet. Added `ShipSegment` (a `Resource` cell: `kind` ∈ CORE/HULL/
THRUSTER/WEAPON/REACTOR, integer `cell`, `facing`), `ShipDesign` (a `Resource`
holding `cell_size` + `Array[ShipSegment]`, with `get_segment_at`/`bounds`/
`create_default`), and `SegmentedHull` (a `@tool Node2D` that `_draw`s a design
as colored grid tiles with kind accents — thruster nozzle, weapon barrel,
reactor/core glow). Swapped `SegmentedHull` in for the diamond `ShipHull` in
`ship.tscn` so the stock ship now flies as a segmented layout.
**Why:** The GDD wants an upgradable ship built from modules; a grid/cell design
(Cosmoteer/FTL-style) is the agreed model, with an in-game editor to come. Doing
the data + rendering first (per the chunked-PR plan) gives a save/load-ready
`ShipDesign` resource that the editor and the flight model both build on.
**Learned:** Godot `Resource`s need `emit_changed()` in setters to notify; the
renderer connects `design.changed` → `queue_redraw` for live editor updates, with
a lazily-built `create_default()` fallback so there is always something to draw.
Keeping segments as pure data (no self-drawing) keeps the renderer, the future
editor, and the future physics model reading one source of truth.
**Follow-ups:** PR #2 — in-game grid editor (place/remove/rotate cells, palette,
save/load `.tres`). PR #3 — wire the design into flight/combat (per-segment mass
& center-of-mass, thrusters from THRUSTER cells, weapons from WEAPON cells).
Reconcile the old single-turret / `PropulsionConfig` FX with segment-derived
mounts.

## 2026-09-10 — Off-screen target markers (edge-marker system)  (branch: feat/ship-topdown-view)

**Did:** Added a first-class **edge-marker system** that pins directional markers
to the viewport border for off-screen targets. Two pieces: `EdgeMarker` (the
reusable visual primitive — a styleable `Node2D` that `_draw`s a triangle now,
with a `Shape` enum ready for more silhouettes) and `EdgeMarkerLayer` (a
`CanvasLayer` overlay that tracks a node **group**, converts each node to screen
space via the camera, and drives a pool of `EdgeMarker`s clamped to the border,
pointing at their targets). Targets join the `targets` group; the layer marks
them in red within `max_distance`. Wired as an `EdgeMarkers` node in
`tactical_combat.tscn`.
**Why:** The player needs to know where nearby targets are once they leave the
view. Built it group-driven and pooled so "more markers later" (waypoints,
allies, objectives) is just another layer + color, or a new `Shape` — no changes
to existing callers.
**Learned:** `get_viewport().get_canvas_transform()` maps world→screen including
the `Camera2D`, and its `affine_inverse()` recovers the view-center in world
space for the range check — no manual zoom math. A `CanvasLayer` keeps markers
screen-fixed regardless of camera pan/zoom; its `Node2D` children position in
raw screen pixels.
**Follow-ups:** Distance-fade or a count badge when many targets stack on one
edge; per-target colors/shapes when target kinds diverge.

## 2026-09-10 — Retrograde marker fires retro thrusters + align-thrust default on  (branch: feat/ship-topdown-view)

**Did:** Clicking/holding the retrograde reticle now fires the ship's weaker
**retro thrusters** (`retro_thrust_force` 400 vs main 900) opposite the velocity
to bleed off speed, and **never turns the hull**. `FlightIndicators` owns the
hit-test (`retro_click_radius`), consumes the click in `_input`, and emits
`retro_burn_requested(active)`; `TacticalCombat` wires it to the new
`Ship.set_retro_burn()`. A tap burns at least `retro_thrust_duration`; holding
burns until release or full stop. Also flipped **Align Thrust to default on**
(`require_alignment = true`, command-bar state + label match).
**Why:** First attempts used an angular cone in the ship, but a click "on" the
marker could fall just outside the cone and turn instead. Letting the marker
consume the event up front makes it impossible for the ship to read it as a turn.
**Learned:** Consuming input in `_input` + `set_input_as_handled()` runs before
any node's `_unhandled_input`, so the ship (which steers from `_unhandled_input`)
never sees the marker click — a clean way to give a HUD element first dibs without
coupling gameplay to the view. Kept decoupled: indicators emit, the mode wires.
**Follow-ups:** Expose retro force/duration on the HUD if it needs tuning.

## 2026-09-10 — Align-thrust HUD toggle + retrograde reticle  (branch: feat/ship-topdown-view)

**Did:** Surfaced the `require_alignment` flight mode as an **Align Thrust** toggle
in the command bar (wired through `TacticalCombat` to `Ship.set_require_alignment`).
Added a **retrograde marker** to the flight indicators: a fixed-distance cue
opposite the velocity showing where to point the nose for a thrust-to-stop burn.
Started as a plain dot, then upgraded to an anti-aliased **ring-with-spokes
reticle** (classic navball retrograde look) built in code from `Line2D`s, with
tunable radius/width/spoke/color exports.
**Why:** Align-thrust wanted a runtime toggle, not just an inspector flag. The
retrograde cue makes point-then-burn stopping readable — the velocity arrow shows
*how much* speed to kill, the reticle shows *which way* to face.
**Learned:** The marker only needs the direction, so it sits at a fixed distance
and the speed magnitude is left to the prograde arrow — keeps the HUD uncluttered.
`Line2D` with `closed = true` + `antialiased = true` makes a clean ring without
custom `_draw`.
**Follow-ups:** Could add a matching prograde reticle if the arrows feel busy.

## 2026-09-10 — Click-along-heading thrust tap  (branch: feat/ship-topdown-view)

**Did:** A quick LMB click whose direction is within `tap_thrust_tolerance_deg`
(20°) of the ship's current heading now fires an immediate forward thrust burst
for `tap_thrust_duration` (0.15 s) instead of deferring a (redundant) turn. Off-
heading clicks keep the existing turn deferred by `DOUBLE_CLICK_WINDOW_MS`. A
double-click still opens the context menu and now also cancels any nudge the
first click started; a fresh press supersedes a lingering tap burn.
**Why:** The 250 ms double-click window is only there to hide a *visible rotation*
before the menu. When the nose already points where you click there's nothing to
turn, so waiting felt dead — a tap should just add speed along the heading.
**Learned:** The nudge has to run through `_physics_process` (via a countdown
timer), not be applied in `_unhandled_input`, so the thruster FX `main_throttle`
plume shows and the impulse is frame-rate independent.
**Follow-ups:** Expose the tap tolerance/duration on the HUD if it needs tuning.

## 2026-09-09 — Align-gated thrust mode  (branch: feat/ship-topdown-view)

**Did:** Added a `require_alignment` flight toggle (with `alignment_tolerance_deg`)
to `Ship`. When on, the main engine only fires once the nose is within tolerance
of the aim direction, so a held LMB turns the ship first and thrusts only after
it lines up. When off, thrust keeps applying along the current heading while
still turning (previous behaviour, still the default).
**Why:** Accelerating along the main engine means off-axis presses shove the ship
sideways-ish during the turn; the new mode gives clean point-then-burn flight.
**Learned:** The heading/aim gap is just `Vector2.UP.rotated(rotation).angle_to(aim_direction)`;
gating the existing thrust block on it keeps the turn/settle logic untouched.
**Follow-ups:** Could expose the toggle in the HUD instead of only the inspector. (done, below)

## 2026-09-09 — Align-thrust HUD toggle + retrograde marker  (branch: feat/ship-topdown-view)

**Did:** Surfaced the align-thrust mode as an "Align Thrust: On/Off" button in
`CommandBar` (new `align_thrust_toggled` signal → `Ship.set_require_alignment`,
wired in `TacticalCombat`). Added a red **retrograde marker** to
`FlightIndicators`: a fixed-length arrow pointing opposite the velocity — the
heading to hold the nose on and burn to cancel speed and stop. It shows/hides
with the prograde arrow (only while moving).
**Why:** The align toggle belongs on the HUD, not just the inspector; the retro
marker tells the player exactly where to point for a thrust-to-stop, which pairs
with align-thrust to turn "stop" into aim-at-marker-and-hold.
**Learned:** Retrograde is just `velocity.angle() + PI`; a fixed length reads as
a "point here" cue rather than a magnitude (unlike the scaled prograde arrow).
**Follow-ups:** Could auto-hold the retro burn (one-click Full Stop already does
the physics; this marker is the manual-flight equivalent).

## 2026-09-09 — Shootable targets, swept-ray hits, Mk1 fix, 3-tier fire control  (branch: feat/ship-topdown-view)

**Did:** Added shootable `Target`/`TargetField` (see prior entry). Switched bolt
hit detection to a **per-frame swept ray** (`intersect_ray`, `collide_with_areas`,
targets layer) because fast bolts tunnelled past the small `Area2D` targets. Fixed
Mk1 prediction: flight time now uses the bolt's **closing speed along the aim**
(`muzzle_speed + velocity·aim`) so the impact reticle matches where shots really
pass through while maneuvering. Reworked fire control into three tiers — **Mk1**
predict, **Mk2** lead **pip** (shows where to point, player still aims), **Mk3**
auto-aim (old Mk2). Command bar now cycles None→Mk1→Mk2→Mk3.
**Why:** Targets that fly-through-but-shoot need hit detection off the ship's
(non-existent) body; a swept ray is tunnel-proof and needs no projectile body.
The user wanted an assist ladder: see-your-drift → see-where-to-aim → auto-aim.
**Learned:** Godot `Area2D` overlaps are sampled per physics frame, so a
1100–1700 px/s bolt skips a 16 px target between ticks — ray-sweeping the step is
the robust fix. For a momentum-carried bolt, the lead error scales with flight
time, and flight time must divide by the **closing** speed (`speed + v·aim`), not
the muzzle speed, or the predicted lead reads low.
**Follow-ups:** Mk2 pip is circular (cursor is both target and aim) — fine as a
manual indicator; revisit if we add designated targets. Score/FX on kills.

---


**Did:** Added `Target` (`res://scenes/combat/target.tscn`, `class_name Target`,
`@tool`) — a self-drawing `Area2D` on a new **targets** collision layer (4) that
flashes on `hit()`, tracks `hit_points`, and emits `destroyed(at)` before freeing
itself. Gave `Projectile` a `Hitbox` `Area2D` (layer 2 = projectiles, mask 4 =
targets) that calls `hit()` and despawns on overlap. Added `TargetField`
(`class_name TargetField`), a spawner that scatters `count` targets uniformly
across an annulus around its origin on `_ready`, and instanced it in
`TacticalCombat`.
**Why:** The user wanted random things to shoot that the ship does **not**
collide with. Since the ship is a plain `Node2D` with no physics body, putting
hit detection entirely on `Area2D` layers means bolts register hits while the
ship simply flies through — no movement blocking, no extra ship collision code.
**Learned:** Only one side of an `Area2D` pair needs `monitoring`; the bolt
monitors (mask 4) and the target is merely `monitorable`, so targets can keep
`monitoring = false`. Uniform scatter across an annulus needs
`r = sqrt(lerp(min², max²))`, not a linear radius (which clumps toward the
center).
**Follow-ups:** Score/impact FX on `target_destroyed`; targets are static (no
drift) for now.

---


**Did:** Bolts now inherit the ship's momentum — `Ship` copies `velocity` into
each turret's new `base_velocity` every frame, and `ShipTurret._fire` launches
`dir * projectile_speed + base_velocity`. Added `fire_control.gd`
(`class_name FireControl`, `@tool`, `top_level`) as a child module of `Ship` with
no visual hardware. **Mk1** aims turrets at the cursor and draws where the
drifted bolt actually lands (trajectory + impact reticle + dashed drift). **Mk2**
solves the lead angle and writes it to each turret's new `aim_override`, drawing
a green locked reticle (red = no solution). The command bar gained a button that
cycles None -> Mk1 -> Mk2 and emits `fire_control_mode_changed`; `TacticalCombat`
wires it to `Ship.set_fire_control_mode`.
**Why:** The user asked for a reconfigurable fire-control module that shows and
then assists the firing solution. That is only meaningful once shots inherit ship
momentum (otherwise a shot always hits exactly where the barrel points), so we
switched bolts to Newtonian first. Keeping the computer as its own signal-wired
component (not baked into `Ship` or `ShipTurret`) matches the one-responsibility
split — turrets fire, the module advises/aims.
**Learned:** Drawing world-space overlays from a node parented to the *rotating*
ship is painful; setting `top_level = true` on `FireControl` detaches its
transform so `_draw` uses world coordinates directly. The lead solve is the
standard stationary-target intercept: pick barrel direction so
`muzzle_velocity + platform_velocity` points at the target; it has no solution
when the platform outruns the muzzle (negative discriminant) — surfaced as a red
reticle rather than a silent miss.
**Follow-ups:** Bolts still have no collision/damage, so "land" is a predicted
point, not an impact on a target. A future Mk1 could also draw the reachable
firing-envelope arc. Fire-control mode isn't persisted in a save yet.

## 2026-09-09 — Mouse-aimed turret + RMB firing  (branch: feat/ship-topdown-view)

**Did:** Added `ship_turret.gd` (`class_name ShipTurret`, `@tool`), instanced on
`Ship` above the hull. It aims independently at the mouse in world space, slews
at `slew_speed`, and fires bolts at its own `fire_rate`. Firing is RMB: `Ship`
collects its `ShipTurret` children in `_ready`, RMB in `_unhandled_input` toggles
`firing` on all of them (`_set_firing`), and the ship relays each turret's
`projectile_fired` up; `TacticalCombat` adds the bolt to the world node. New
`Projectile` scene (`projectile.gd`) is a straight-line bolt that despawns after
`lifetime`.
**Why:** The user wants a turret that tracks the cursor and fires on RMB, and
**multiple/different turrets later**. Making each turret own its aim + fire rate
and emit a spawn signal means adding a turret is just instancing another
`ShipTurret` node — no wiring changes (guidelines: one responsibility, decouple
via signals).
**Learned:** Because the turret is a child of the rotating `Ship`, aiming uses
`global_rotation` (not local `rotation`) so it ignores the hull's heading; barrel
forward is local -Y, so the aim angle needs a `+PI/2` offset. Spawning the bolt
into the world (not under the ship) keeps its own momentum; the turret emits the
node and lets the mode parent it, so the turret never needs a world reference.
**Follow-ups:** Bolts have no collision/damage yet; no muzzle flash; ship
velocity isn't inherited by bolts. A per-turret `.tres` weapon config (like
`PropulsionConfig`) is the likely next step for different turret types.

---

## 2026-09-09 — Data-driven propulsion + RCS settle fix  (branch: feat/ship-topdown-view)

**Did:** Moved the thruster nozzle layout out of `ship_thrusters.gd` hard-coded
arrays into serializable resources: `ThrusterNozzle` (`Resource`: position,
expel direction, plume size/colors, a `channels` flag set of MAIN/ROTATION/
TRANSLATION) and `PropulsionConfig` (`Resource`: `Array[ThrusterNozzle]` +
`create_default()`). `ShipThrusters` now takes an `@export var config:
PropulsionConfig`, falling back to the default when unset, and derives each
nozzle's firing generically from its channels. Also fixed the RCS jets looking
"always on": the turn controller now snaps to the aim and zeroes spin once within
`SETTLE_ANGLE`/`SETTLE_SPEED`, so `rcs_torque` drops to 0 at rest instead of
chattering.
**Why:** The nozzle set should be authorable data that can be saved/loaded (ship
loadouts, save games), not baked into the FX script — the FX is just a renderer
of a `PropulsionConfig`. The settle deadzone removes a limit-cycle where the
controller kept issuing full-strength micro-corrections near the target.
**Learned:** A typed `Array[ThrusterNozzle]` export is inspector-editable and
serializes cleanly to `.tres`; `@export_flags("Main","Rotation","Translation")`
lines up bit values 1/2/4 with the `Channel` enum, so one nozzle can answer
several command channels (e.g. the main engine is just a nozzle with the MAIN
flag). Default positions are now absolute px (matching the stock hull) rather
than hull-relative, which is the right trade for serializable data.
**Follow-ups:** Could ship an actual `default_propulsion.tres` and per-hull
configs; still no rear-firing RCS for pure backward-drift braking.

---

## 2026-09-09 — Thruster FX: main engine + control thrusters  (branch: feat/ship-topdown-view)

**Did:** Added `ship_thrusters.gd` (`class_name ShipThrusters`, `@tool`), a
child `Node2D` in `ship.tscn` placed before `ShipHull` so plumes draw behind the
ship. It reads new per-frame state on `Ship` — `main_throttle` (forward thrust),
`rcs_torque` (signed rotation command), `rcs_translation` (local retro-burn dir)
— and `_draw`s a main-engine plume off the tail plus a set of control-thruster
(RCS) jets. `ship.gd` now sets that state where it already computes thrust,
turning, and braking (no new physics).
**Why:** The user asked for visible thrusting/rotation via a main engine and
control thrusters. Deriving the visuals from existing state keeps the FX a pure,
decoupled reader (guidelines: one responsibility, communicate via read-only
state, no god class).
**Learned:** RCS nozzle firing is derived generically: for each nozzle the
reaction force is `-expel_dir`; it fires when its `cross(pos, force)` sign
matches the commanded torque, or when `force · rcs_translation > 0`. This makes
the four lateral nozzles form correct rotation couples automatically, and the
nose nozzle brakes forward drift — no hand-picked per-direction cases. RCS only
fires while *changing* angular velocity (the clamped `step`), so a coasting turn
shows no jets, which reads as correct Newtonian behavior.
**Follow-ups:** No rear-firing RCS, so braking pure backward drift has no jet
(rare); main engine covers forward. Could add smoke/particles or a throttle ramp
later.

---

## 2026-09-09 — Ship visual split into its own ShipHull scene  (branch: feat/ship-topdown-view)

**Did:** Extracted the ship's hull drawing out of `ship.gd` into a standalone
`res://scenes/ship/ship_hull.tscn` + `ship_hull.gd` (`class_name ShipHull`,
`@tool`), instanced as a child of `Ship`. The hull's `@export` dimensions/colors
and `_draw`/`_hull_points` moved with it; `Ship` now owns only flight logic and
no longer defines the visual tunables. `ship.tscn` instances the hull child.
**Why:** `ship.gd` was mixing rendering with physics — a step toward a god
class. A separate scene keeps drawing and flight decoupled and lets the visual
be swapped/edited independently (guidelines: no god classes, one responsibility).
**Learned:** The hull is a child `Node2D`, so it inherits `Ship.rotation` for
free and draws in local space (nose at -Y) — no extra wiring needed.
**Follow-ups:** Later the hull can grow thruster/engine sub-nodes or swap art per
ship size without touching the flight code.

---

## 2026-09-09 — Physical flight + LMB command scheme (cruise removed)  (branch: feat/ship-topdown-view)

**Did:** Pivoted the flight model to pure Newtonian and reworked the controls.
Removed automatic linear `damping` (space is frictionless; momentum persists) and
tore out the whole cruise/dial-a-velocity system (state, autopilot, and the pink
gauge in `FlightIndicators`). New LMB scheme in `Ship._unhandled_input`:
- **Click** = turn toward the point only (no thrust), *deferred* by
  `DOUBLE_CLICK_WINDOW_MS` (250 ms) so it can be told apart from a double-click.
- **Hold** = turn + thrust once held past `hold_thrust_delay` (0.15 s).
- **Double-click** = emit `context_menu_requested`; the mode opens a context menu.
Added a `ContextMenu` (`CanvasLayer`) at the cursor with **Full Stop** → a
physical retro-burn (`Ship.full_stop`/`_apply_braking`, spends `thrust_force/mass`
opposite velocity until at rest). The command bar was kept but emptied as a
placeholder for a future auto-decelerate toggle.

**Why (decisions):**
- The target feel is *physical movement in space*: you thrust, you drift, nothing
  slows you but your own engines. Artificial `damping` contradicted that.
- Mouse buttons: **RMB is reserved for other actions**, so "stop" is an *order*
  from a menu rather than a held mouse button. Double-click opens that menu.
- Click-vs-hold split lets you re-orient without accelerating (click) or fly
  (hold) on one button; the double-click menu hosts discrete ship orders.
- Stop is modelled as real retro-thrust (mass-scaled), keeping the physics honest
  and reusing the mass hook (heavier ships stop slower).

**Learned:** The first click of a double-click is indistinguishable from a single
click until the second click arrives, so a single-click turn must be **deferred**
by the double-click window and cancelled if the second click lands — otherwise the
ship visibly rotates before the menu opens. Cost: ~250 ms latency on a pure
turn-click (tunable via `DOUBLE_CLICK_WINDOW_MS`). Keep world-click handling in
`_unhandled_input` so `CanvasLayer` UI (menu/bar) consumes its own clicks first.

**Follow-ups:** Add the auto-decelerate / flight-assist toggle to the command bar;
flesh out the context menu with more orders (match velocity, orbit, align); tune
`hold_thrust_delay` and the double-click window for feel.

---

## 2026-09-09 — Cruise armed via a command bar toggle  (branch: feat/ship-topdown-view)

**Did:** Gated cruise dialing behind a new `Ship.cruise_armed` flag and added a
bottom **command bar** (`scenes/ui/command_bar.tscn`, `class_name CommandBar`, a
`CanvasLayer`) with a **Cruise** toggle. The bar emits `cruise_armed_changed`;
`TacticalCombat` wires it to `ship.cruise_armed` in `_ready`. While armed, an LMB
**press-and-drag** dials the course (dropped the double-click requirement); the
ship now reads it in `_unhandled_input` so the toggle button's clicks don't leak
into the world. Turning the toggle off releases the active cruise. Also fixed the
earlier conflict where LMB was bound to `thrust` (removed it from the action).

**Why:** The player wanted cruise to be switched on explicitly rather than firing
on any double-click, surfaced as a button in a bottom command bar. Routing the
toggle through a signal keeps the UI decoupled from the ship (guidelines: no
direct cross-system references), and it's the first real use for a `CanvasLayer`
HUD in the tactical mode.

**Learned:** Use `_unhandled_input` (not `_input`) for world clicks when a
`Control`/`CanvasLayer` UI is present — GUI consumes handled events, so button
presses won't start a dial, while clicks in the `mouse_filter = IGNORE` play area
still fall through. Adding a new `class_name` (CommandBar) outside the editor
needs the global class cache regenerated (`--editor --headless --quit`) or the
`as CommandBar` cast fails to parse and the scene won't load.

**Follow-ups:** More command-bar actions (stop, jump, scan) as modes arrive;
consider an `EventBus` autoload once several systems emit/consume these toggles.

---

## 2026-09-09 — Cruise: double-click-and-hold dialed speed + gauge  (branch: feat/ship-topdown-view)

**Did:** Added a set-and-forget cruise command to `Ship`. **Double-click-and-hold**
LMB live-dials a commanded velocity — direction toward the cursor, speed from the
cursor distance (`cruise_full_speed_distance` away = `max_speed`); release commits.
`_apply_cruise_thrust` autopilots: aims along the command and thrusts forward once
roughly aligned (`cruise_thrust_alignment`) until along-track speed reaches the
target. A plain hold-aim or `thrust` cancels it. New public state `cruise_target`/
`cruise_active`. `FlightIndicators` now `_draw`s a pink cruise gauge (faint track =
max speed, filled segment = dialed fraction) along the commanded heading.

**Why:** The player wanted to point-and-set a travel vector with a readable
throttle rather than hold thrust manually. Distance-dials-speed reuses the cursor
we already track; the gauge makes "what fraction of max" legible. Detecting the
gesture via `InputEventMouseButton.double_click` + a `_dialing` flag cleanly
separates it from single-hold manual aim.

**Learned:** The first click of a double briefly satisfies `is_mouse_button_pressed`
(single hold-aim), so cruise handling keys off the `double_click` event and a
`_dialing` flag instead of polling the button. Forward-only thrust can't brake, so
dialing a slower speed relies on `damping` to coast down — fine now, but a
retro/lateral thruster is the honest fix later.

**Follow-ups:** Retro/lateral thrust so cruise can actively decelerate/strafe;
tune `cruise_full_speed_distance` for camera zoom; maybe show a numeric %% on the
gauge.

---

## 2026-09-09 — Momentum-based turning + mass model  (branch: feat/ship-topdown-view)

**Did:** Replaced the ship's instant snap-to-aim rotation with momentum turning.
`Ship` now integrates `angular_velocity`: `_apply_turning` steers toward the aim
angle under an `angular_accel = turn_torque / mass` limit and brakes early
(`sqrt(2·a·error)`) so it arrives without oscillating, capped by `max_turn_speed`
and bled by `angular_damping`. Thrust now pushes along the ship's **actual nose**
(`Vector2.UP.rotated(rotation)`) instead of the aim vector, and is a force:
`accel = thrust_force / mass`. Replaced the `thrust_accel` export with `mass` +
`thrust_force` (Flight group) and added a Turning group (`turn_torque`,
`max_turn_speed`, `angular_damping`). New public state: `angular_velocity`.

**Why:** The player wanted turning to carry momentum like acceleration does, and
to set up **physical behavior** where larger-mass ships need more thrust. Dividing
both thrust and torque by `mass` makes that scaling fall out naturally, and
thrusting along the real heading (not the aim) means the ship must finish rotating
before its momentum points where you want — the core of the drift feel.

**Learned:** Applying thrust along the nose instead of the aim is what actually
makes rotation *matter*; with aim-thrust the heading lag would be cosmetic. The
"brake early" arrive formula avoids a PID/oscillation without tuning. Couldn't run
the headless load check this session — the Godot executable named in `AGENTS.md`
isn't present in this checkout — but GDScript static analysis is clean.

**Follow-ups:** Verify feel in-editor and tune default `turn_torque`/
`max_turn_speed`. Consider deriving moment of inertia from hull size (not just
mass) once ship sizes vary, and a reverse/retro-thrust or lateral thrusters.

---

## 2026-08-29 — Mode system; free flight becomes tactical combat  (branch: feat/ship-topdown-view)

**Did:** Introduced a lightweight `ModeManager` (`scripts/mode_manager.gd`) with a
`Mode` enum (`TACTICAL_COMBAT`, `STRATEGIC_MAP`, `SYSTEM_JUMP`), a `PackedScene`
per mode, `switch_to(mode)`, and a `mode_changed` signal. Moved the free-flight
gameplay into a self-contained `TacticalCombat` mode scene
(`scenes/modes/tactical_combat/`); `main.tscn` is now just a `Main` root + the
manager, and the old `main.gd` was removed (camera-follow moved into the mode).
Defined the three modes in the GDD (§4.1).

**Why:** The player asked to reframe the current movement as the **tactical
combat** mode — the real-time layer — distinct from a **strategic map** (travel
within a system) and a **system jump** (between systems). Scaffolding the manager
now keeps each mode a swappable, self-contained scene and answers part of the
GDD's travel-model question.

**Learned:** Mode scenes swap cleanly by instancing under a plain `Node` manager;
Node2D modes render fine beneath it. Only `tactical_combat_scene` is assigned;
the other two `PackedScene` slots are intentionally empty placeholders.

**Follow-ups:** Build the strategic map (in-system node travel) and system-jump
modes; decide how control passes between modes (and whether the map pauses
combat). Shared state (current system, ship status) will want a `GameState`
autoload once a second mode exists.

---

## 2026-08-29 — Mouse-aimed free flight + heading indicators  (branch: feat/ship-topdown-view)

**Did:** Added Newtonian free flight to `Ship`: hold **left mouse** to aim at the
cursor and thrust (`thrust` action = LMB / Space / W), with `thrust_accel`,
`max_speed`, and `damping` tunables; exposes `velocity` and `aim_direction`.
Added a `FlightIndicators` scene showing two `VectorArrow`s — amber aim (desired
heading) and green velocity (prograde). Built `VectorArrow` from `Line2D` +
`Polygon2D` (no `_draw`). Added a `Camera2D` follow (in `main.gd`) and a
world-fixed reference grid rendered by a `canvas_item` shader on a full-screen
`ColorRect` (`SpaceGrid`, `CanvasLayer` layer -1).

**Why:** Movement is the prerequisite for the rest of the loop and answers the
GDD's open "travel model" question toward free-flight. Mouse-only aiming lets the
ship coast on a heading. Indicators/grid make the drift readable.

**Learned (important gotchas):**
- **Global class cache:** editing files outside the editor left
  `.godot/global_script_class_cache.cfg` missing, so `@export var ship: Ship`
  failed to parse ("Could not find type Ship") and the main scene never
  instantiated — the window sat on the boot splash. Fix: regenerate the cache
  (`Godot --path . --editor --headless --quit`); don't rely on it for headless.
- **Node exports from hand-written `.tscn` didn't bind** (all resolved to null).
  Switched to `@export var *_path: NodePath` + `get_node_or_null` in `_ready` —
  reliable.
- Not a renderer problem (chased Forward+/Vulkan first — the machine also has a
  broken Vulkan SDK layer install spamming loader errors, but that was a red
  herring). Verified by screenshotting `get_viewport().get_texture()`.

**Follow-ups:** Resolve remaining GDD questions (energy model, encounters). Grid
shader assumes camera zoom 1. Introduce `EventBus`/`GameState` with the first
stateful system (scanning/nodes).

---

## 2026-08-19 — First gameplay scaffold: top-down ship view  (branch: feat/ship-topdown-view)

**Did:** Scaffolded the Godot 4.6 project (`project.godot`, `icon.svg`) with a
`Main` scene (`Camera2D` + `Ship` instance) as the entry point, and a
self-contained `Ship` scene/script. `Ship` (`@tool`, `class_name Ship`) draws an
elongated diamond via `_draw`, longer nose marking the front; hull dimensions and
colors are `@export`ed and redraw live. Verified with a headless import + run
(clean).

**Why:** First small, visible step toward the top-down space game — establish the
project, a runnable main scene, and the player ship as a self-contained,
composable, tunable scene per the guidelines.

**Learned:** Forward = -Y reads naturally as "up" in a top-down view and keeps
room for `look_at`/velocity-based heading later. `.tscn`/script uids are
generated by Godot on first import, so path-based `ext_resource` refs load fine
without hand-writing uids. Held off on `EventBus`/`GameState` autoloads until a
stateful system actually needs them (avoid empty scaffolding).

**Follow-ups:** Add ship movement/rotation input; introduce `EventBus`/`GameState`
with the first stateful system; replace the placeholder hull with real art from
the assets submodule later.

---

## 2026-08-19 — Development workflow doc  (branch: docs/workflow)

**Did:** Added [workflow.md](workflow.md) — branch naming, Conventional Commits +
SemVer bump mapping, PR hygiene (`gh`, temp-file bodies, `| cat`), CI-failure
triage, and a local quick-change debugging loop. Wired it into
[AGENTS.md](../AGENTS.md) (doc map + "prepare, don't push") and cross-linked the
debugging loop from [guidelines.md](guidelines.md).

**Why:** Extracted the genuinely reusable, tool-agnostic ideas from an internal
plugin marketplace (`Hillrom-Enterprise/surgical-skills`) without taking a
dependency on it — the doc is self-contained repo text. Deliberately dropped the
Jira/Atlassian/Baxter-specific parts, which don't apply to this project.

**Learned:** The reusable core of that "workflow" skill is Conventional Commits,
SemVer, PR/CI hygiene, and the debug loop; everything Jira was org-specific.
Keeping it as plain docs (not a plugin) means zero external dependency.

**Follow-ups:** Kept in sync with the godot-project-template copy; revisit if we
adopt a test framework or actually set up CI.

---

**Did:** Ran the design questionnaire with the user and filled in
[design-questionnaire.md](design-questionnaire.md), then wrote the first draft of
[game-design.md](game-design.md) from those answers.

**Why:** Lock the concept and an MVP before writing code. Seeker is a 2D top-down
space journey: command an upgradable ship, manage minerals/energy/tech-fragments,
survey and jump between nodes, and upgrade to face bigger threats on the way
"home" (the ship's origin). Tone: lonely/contemplative with tense survival beats.
Persistent progression; optional combat. MVP = travel between nodes, hit an
event, collect, and buy one capability-changing upgrade.

**Learned:** Core pillar is resource management → upgrades (which cost resources
and raise energy use). Several unknowns remain: travel model (node-jump vs.
free-flight blend), encounter resolution (real-time vs. paused), energy model and
failure states, enemy/event roster.

**Follow-ups:** Resolve the open questions in the GDD; then scaffold the first
gameplay feature (candidate: node star-map + jump). Art/audio stay placeholder.

---

## 2026-06-17 — Reusable template + assets/VCS setup  (branch: main)

**Did:** Added a [README.md](../README.md) framing the repo as a reusable
Godot + AI-agent project template ("Use this template" on GitHub). Added a Godot
4 [.gitignore](../.gitignore) and a Git LFS
[assets-gitattributes.template](assets-gitattributes.template) for the assets
submodule. Expanded [guidelines.md](guidelines.md) with Events & signals,
single-responsibility/no-god-classes, and the submodule + LFS asset strategy.

**Why:** The scaffolding generalizes well, so it's worth packaging as a template
others (and future projects) can start from. Chose **git submodule + Git LFS
inside the assets repo** as the asset strategy — submodule for clean separation,
LFS to keep the assets repo's history light.

**Learned:** Submodule and LFS are complementary, not either/or. The assets
`.gitattributes` is kept as a `.template` so it won't collide with
`git submodule add assets` later.

**Follow-ups:** Add a LICENSE before publishing the template; create the assets
submodule repo and wire it up; initialize the Godot project.

---

## 2026-06-17 — Project scaffolding  (branch: main)

**Did:** Added agent instructions ([AGENTS.md](../AGENTS.md)) and documentation
scaffolding: [guidelines.md](guidelines.md), [game-design.md](game-design.md),
[architecture.md](architecture.md), and this devlog.

**Why:** Establish conventions and a feature-branch + document-as-you-go
workflow before building the game.

**Learned:** Workspace starts empty; Godot project files and the engine
executable to be added next.

**Follow-ups:** Initialize the Godot project, confirm engine version, add a
Godot `.gitignore`, fill in the game design doc.
