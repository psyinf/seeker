# Seeker — Design Questionnaire

> Filled in during the first design session (2026-08-19). Answers here feed
> directly into [game-design.md](game-design.md). Gaps are flagged under
> **Open questions**.

## 0. Warm-up (the one-liner)

- **Pitch:** You are the commander of an upgradable ship on an unknown journey
  through space, seeking resources and technology to finally arrive at what you
  think is home.
- **Feeling:** Lonely and contemplative, with tense survival moments — the pull
  of the unknown and the quiet satisfaction of mastering the journey.
- **Like, but…:** Exploration/management in the spirit of FTL and Out There, but
  more sim/sandbox and narrative — the story evolves toward finding the ship's
  origin/maker.

## 1. High concept

- **Genres:** Metroidvania / exploration, Simulation / sandbox, Adventure /
  narrative.
- **Platform(s):** PC (desktop), built in **Godot 4.x**.
- **Target audience:** Players who enjoy slow-burn exploration and
  resource-management journeys.
- **Session length:** A session can be minutes, but the grand game is a long,
  multi-hour journey.
- **Perspective / dimension:** 2D top-down.

## 2. Pillars

- **Resource management is the core.** Everything revolves around gathering and
  spending resources.
- **Meaningful upgrades.** Upgrades improve defense, attack, and scanning — but
  they consume energy and cost resources to build.
- **The pull of the unknown.** Lonely, contemplative tone punctuated by tense
  survival encounters.
- **Player-set priorities.** The player decides which systems to invest in.

## 3. Core gameplay loop

- **10-second loop:** Check surveyed targets to travel to; react to
  events / obstacles / enemies / opportunities that arise.
- **Repeating loop:** travel → encounter (collect / fight / avoid) → spend
  resources to upgrade → detect farther nodes and face bigger threats → repeat.
- **What makes it satisfying:** Saving enough resources to unlock the next
  upgrade, which in turn opens up harder, more rewarding parts of the journey.
- **Session start/end:** Begins at a node; a short session is a jump or two and
  an encounter; the long game is the full journey home.

## 4. Mechanics

- **Star mechanic:** Move to improve and collect resources so you can master
  more challenging parts of the journey.
- **Core mechanics:** navigation/travel (jump to surveyed targets + local
  free-flight), scanning/surveying, resource collection, ship upgrading, energy
  management, event/encounter reactions, light optional combat.
- **Combat:** Between "light threats" and "core" — the player *can* choose to
  confront enemies/hazards for gains, but it isn't forced.
- **Real-time / turn-based:** Real-time moment-to-moment (to be confirmed).

## 5. World & setting

- **Setting:** Deep space, an unknown journey. Tone: lonely / contemplative with
  tense / survival beats.
- **Narrative premise:** The story evolves toward discovering the ship's
  origin / maker — the "home" the commander is seeking.
- **What the player is seeking:** The ship's origin/home; mechanically,
  resources and tech-fragments that enable breakthroughs to get there.

## 6. Player & entities

- **Player controls:** A single upgradable ship.
- **Core verbs:** survey/scan, jump/travel, collect, upgrade, manage energy,
  optionally engage threats.
- **Entities (rough):** resource sources (minerals/energy), tech-fragment
  sources, hazards/obstacles, enemies, and opportunity events. (Exact roster is
  an open question.)

## 7. Controls & input

- **Primary input:** Keyboard + mouse (PC). _Mapping TBD._
- **Accessibility:** Not yet specified — flag for later (remappable keys,
  colorblind palette).

## 8. Progression & economy

- **Progression type:** Persistent progression — save enough resources to
  upgrade and thereby face higher threats.
- **Resources:** **minerals**, **energy**, and **tech-fragments** (tech-fragments
  drive tech-progress needed for breakthroughs).
- **Upgrades:** Defense, attack, scanning, and more — the player chooses the
  priority. Upgrades cost resources and increase energy consumption.
- **Difficulty curve:** Threat level scales as the player pushes farther;
  upgrades keep pace. Adjustable difficulty TBD.

## 9. UI / UX

- **HUD always shows:** energy level, hull/health, resource counts, and an
  event log / alerts.
- **Menus (MVP):** main menu, pause, settings (to confirm), plus ship/upgrade
  view.
- **Feedback:** TBD (hit effects, alerts, sound cues).

## 10. Art & audio direction

- **Visual style:** Placeholder for now.
- **Palette / music / SFX:** TBD.
- **Assets:** Placeholder-for-now; real direction decided later.

## 11. Scope & milestones

- **MVP / vertical slice:** Travel to the next star/node to encounter
  opportunities to collect, upgrade, and become able to detect more nodes or
  face bigger threats. Concretely: jump between nodes, hit at least one event,
  collect resources, and spend them on at least one upgrade that visibly changes
  capability (e.g. scanning range or defense).
- **Explicitly out of MVP:** Full narrative, full enemy roster, final art/audio.
- **Deadline / budget:** None stated.
- **Team:** Solo project.

## 12. Open questions

- Exact travel model: how do local free-flight and node-jumping combine?
- Real-time vs. paused/tactical encounters — how do combat/events resolve?
- Enemy / event roster and how many distinct types for the MVP.
- Energy model details: generation vs. consumption, and failure states.
- Control mapping and accessibility options.
- Art & audio direction (currently placeholder).

---

### How we'll use this

These answers seed [game-design.md](game-design.md). The MVP scope is locked to
the node-travel + collect + upgrade loop; open questions above become the design
agenda for the next passes.
