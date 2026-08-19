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

- Travel model: how do local free-flight and node-jumping combine?
- Encounter resolution: real-time vs. paused/tactical for combat and events?
- Enemy / event roster and how many distinct types for the MVP.
- Energy model: generation vs. consumption, and failure states.
- Control mapping and accessibility options.
- Art & audio direction (currently placeholder).
