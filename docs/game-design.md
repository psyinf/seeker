# Game Design Document — Seeker

> **Status: first draft (2026-08-19).** Seeded from
> [design-questionnaire.md](design-questionnaire.md). Sections marked _TBD_ or
> listed under Open questions are still to be resolved.

## 1. High concept

You are the commander of an upgradable ship on an unknown journey through space,
seeking resources and technology to finally arrive at what you think is home.

- **Working title:** Seeker
- **Genre:** Exploration / simulation-sandbox / narrative adventure (2D top-down)
- **Platform(s):** PC (desktop), Godot 4.x
- **Target audience:** Players who enjoy slow-burn exploration and
  resource-management journeys
- **Elevator pitch:** A lonely, contemplative voyage where you manage energy and
  resources, upgrade your ship, and push through ever-greater threats to
  uncover the ship's origin — and reach home.

## 2. Pillars

- **Resource management is the core.** Every decision is about gathering and
  spending minerals, energy, and tech-fragments.
- **Meaningful upgrades.** Upgrades strengthen defense, attack, and scanning but
  cost resources and raise energy consumption — trade-offs, not free power.
- **The pull of the unknown.** Lonely, contemplative tone with tense survival
  beats; the journey is a mystery unfolding toward "home".
- **Player-set priorities.** The player chooses which systems to invest in and
  how to grow.

> If a feature threatens the resource-management/upgrade core, that pillar wins.

## 3. Core gameplay loop

**10-second loop:** check surveyed targets to travel to → react to
events / obstacles / enemies / opportunities that arise.

**Session loop:**

```
survey/scan → jump to target → encounter (collect / fight / avoid)
   → spend resources to upgrade → detect farther nodes & face bigger threats → repeat
```

Satisfaction comes from saving enough resources for the next upgrade, which
unlocks harder and more rewarding parts of the journey. A short session is a jump
or two and an encounter; the grand game is the full, multi-hour journey home.

## 4. Mechanics

**Star mechanic:** move to improve — collect resources so you can master more
challenging parts of the journey. Everything below supports it.

| Mechanic | Description | Notes |
|----------|-------------|-------|
| Navigation / travel | Jump to surveyed targets; local free-flight within a system | Exact blend of node-jump vs. free-flight is an open question |
| Scanning / surveying | Detect nodes, resources, and threats; better scanners reveal more/farther | Scanning range is a key upgrade axis |
| Resource collection | Gather minerals, energy, tech-fragments from encounters | Feeds the economy |
| Ship upgrading | Spend resources to improve defense, attack, scanning, etc. | Upgrades increase energy consumption |
| Energy management | Systems and upgrades draw energy; player balances capability vs. supply | Failure states TBD |
| Encounters / events | React to obstacles, enemies, and opportunities | Roster + resolution model TBD |
| Combat (optional) | Player *may* confront enemies/hazards for gains; not forced | Between "light threats" and "core" |

- **Real-time / turn-based:** real-time moment-to-moment (to confirm).

### 4.1 Game modes

The game is played across three distinct modes; the player moves between them.

| Mode | Scale | What you do | Status |
|------|-------|-------------|--------|
| **Tactical combat** | A single encounter/locale | Real-time, mouse-aimed Newtonian free flight: dodge, fight, collect, react to events | **Prototyped** |
| **Strategic map** | One star system | Zoomed-out travel between surveyed nodes within the current system | Planned |
| **System jump** | Between systems | Commit energy/resources to jump to the next star system | Planned |

Tactical combat is real-time; the strategic map and jump are the slower,
deliberate layers. How control passes between them (and whether the map pauses
combat) is still open.

### 4.2 Ship modules

The ship is a grid of cells; each cell is a **module** of one kind. Structural
cells hold it together, functional cells give it capabilities. See the full
catalog and base values in
[module-design-questionnaire.md](module-design-questionnaire.md).

- **Core** is always present and must survive — losing it ends the ship.
- **Armor** is a special border/shell cell; interior cells are regular modules.
- Every module shares a stat block: **mass, power draw, power generation,
  internal armor (HP), build cost**, plus **crew** and **heat** (modelled but 0
  for now). Module-specific extras add cargo, scan range, or fuel capacity.
- Base stats live in a static table keyed by kind
  ([module_stats.gd](../scenes/ship/module_stats.gd)); upgrades/modifiers layer
  on top later.
- The ship derives totals from its modules: total mass, net power (generation −
  draw), total HP, cargo capacity, and scan range.

| Kind | Role |
|------|------|
| Core | Command cell; must survive |
| Hull | Structural filler |
| Armor | Tough border/shell cell |
| Thruster | Propulsion |
| Weapon | Offense |
| Reactor | Power generation |
| Drone bay | Launches drones |
| Cargo hold | Resource storage |
| Shield generator | Defensive field |
| Sensor / scanner | Survey/scan range |
| Fuel tank | Jump fuel storage |
| Radiator / heat sink | Heat management (inert until heat exists) |

### 4.3 Ship classes

A ship's **class** names its hull and hints at its role. The starter hull is the
**Nomad-class** — an exploration / deep-space recon ship (self-reliant long-haul
wanderer), stored as `ShipDesign.ship_class`.

Naming convention: recon/explorer hulls take **navigator / guiding-light** names
(Nomad, Pathfinder, Lodestar, Wayfarer); later combat and hauler classes use their
own themes so a class name reads its role at a glance.

### 4.4 Heat vs. armor (design tension) — concept

Once **armor plating** and the **heat system** are both live, the ship's outer
shell has to serve two jobs at once, and they fight each other:

- **Armor wants coverage.** Protection comes from wrapping the hull in tough
  plating — the more of the border you armor, the harder the ship is to crack.
- **Heat wants exposure.** Reactors, thrusters, weapons and shields dump heat;
  radiators shed it, but they need **exposed surface** (edge cells radiating to
  space) to do so. Plating over that surface insulates the ship and chokes its
  cooling.

So armoring the shell trades away radiating surface. The intended consequences:

- A **heavily armored** ship is tanky but runs **hot** — it must throttle
  power-hungry systems, add interior radiators (mass/cost), or accept heat
  build-up that degrades performance or forces cool-down pauses.
- A **lightly armored** ship dissipates heat freely and can run its systems hard,
  but its shell cracks quickly under fire.
- **Radiators are a targetable weak point:** exposed to work, so they invite
  enemy fire; losing them spikes the ship's heat.

This turns hull layout into a real decision (where to armor, where to leave
radiating gaps, how to route heat) rather than "armor everything". Rough knobs
to model when the loops go live: armor plating reduces the effective radiating
surface of the cells it covers; a ship's heat balance is `heat produced −
heat dissipated`, and going over budget applies penalties (reduced power,
accuracy, or forced throttling) rather than an instant fail. Numbers TBD.

### 4.5 Weapons — first pass

Weapons are data-driven stat blocks (`WeaponConfig`) mounted on turrets. Three
firing models exist, sharing the same properties (**speed, damage, recoil,
cadence**):

- **Projectile** — dumb bolts fired at a muzzle speed; they inherit the ship's
  momentum (Newtonian). Recoil is real: `recoil = projectile speed × ammo mass`
  (the round's momentum leaving the barrel).
- **Guided** — missiles that soft-launch and home on the nearest target at a
  limited turn rate. Negligible recoil.
- **Energy (beam)** — a continuous hitscan laser that burns whatever the barrel
  line touches within range; draws power instead of ammo, so **no recoil**. Damage
  is per-second while the beam stays on target.

Ready-made presets:

| Preset | Kind | Cadence | Speed | Damage | Recoil |
|--------|------|---------|-------|--------|--------|
| **Railgun** | Projectile | ~1/s | massive | massive | heavy |
| **Autocannon** | Projectile | high | moderate | small | light |
| **Missile** | Guided | slow | slow (homes) | heavy | none |
| **Laser** | Energy/beam | continuous | instant | moderate/s | none |

**Recoil vs. RCS.** Each projectile shot kicks the ship opposite the muzzle. The
RCS continuously fights to null the accumulated kick (`rcs_recoil_compensation`,
px/s of delta-v per second). Firing within that budget is fully absorbed; heavy
or many weapons firing at once **overwhelm** the RCS and the leftover kick shoves
the ship — a real trade-off between firepower and station-keeping.

**Choosing a weapon.** The ship editor's **Combat** category lists each weapon as
a placeable part (Autocannon / Railgun / Missile / Laser); the chosen preset is
stored per WEAPON cell (`ShipSegment.weapon`) and saved with the design, so a cell
fires the weapon you picked for it.

## 5. World & setting


- **Setting:** deep space, an unknown journey. Tone: lonely / contemplative with
  tense / survival beats.
- **Narrative premise:** the story evolves toward discovering the ship's
  origin / maker — the "home" the commander is seeking.
- **What the player seeks:** the ship's origin/home; mechanically, resources and
  tech-fragments that enable breakthroughs to get there.
- **Factions / characters / locations:** _TBD._

## 6. Player & entities

- **Player controls:** a single upgradable ship.
- **Core verbs:** survey/scan, jump/travel, collect, upgrade, manage energy,
  optionally engage threats.
- **Entities (rough):** resource sources (minerals/energy), tech-fragment
  sources, hazards/obstacles, enemies, opportunity events. Exact roster and
  count are open questions.

## 7. Controls & input

- **Primary input:** keyboard + mouse (PC).
- **Mapping:** _TBD._
- **Accessibility:** remappable keys and colorblind palette flagged for later.

## 8. Progression & economy

- **Progression type:** persistent — save enough resources to upgrade and thereby
  face higher threats.
- **Resources:**
  - **Minerals** — primary building material for upgrades.
  - **Energy** — powers systems; consumed by upgrades.
  - **Tech-fragments** — drive tech-progress needed for breakthroughs.
- **Upgrades:** defense, attack, scanning, and more; player chooses priority.
  Each upgrade costs resources and raises energy consumption.
- **Difficulty curve:** threat scales as the player pushes farther; upgrades keep
  pace. Adjustable difficulty _TBD_.

## 9. UI / UX

- **HUD (always visible):** energy level, hull/health, resource counts, and an
  event log / alerts.
- **Menus (MVP):** main menu, pause, settings (to confirm), ship/upgrade view.
- **Feedback:** _TBD_ (hit effects, alerts, sound cues).

## 10. Art & audio direction

- **Visual style:** placeholder for now; 2D top-down.
- **Palette / music / SFX:** _TBD._
- **Assets:** placeholder-for-now; real direction decided later.

## 11. Scope & milestones

- **MVP / vertical slice:** travel to the next star/node to encounter
  opportunities to collect, upgrade, and become able to detect more nodes or
  face bigger threats. Concretely: jump between nodes, hit at least one event,
  collect resources, and spend them on at least one upgrade that visibly changes
  capability (e.g. scanning range or defense).
- **Later:** full narrative, full enemy/event roster, final art & audio,
  adjustable difficulty, accessibility options.

## 12. Open questions

- Travel model: how do local free-flight and node-jumping combine? — *partly
  settled: three modes (tactical combat / strategic map / system jump), see 4.1.
  Remaining: how control passes between them and whether the map pauses combat.*
- Encounter resolution: real-time vs. paused/tactical for combat and events?
- Enemy / event roster and how many distinct types for the MVP.
- Energy model: generation vs. consumption, and failure states.
- Control mapping and accessibility options.
- Art & audio direction (currently placeholder).
