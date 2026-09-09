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
