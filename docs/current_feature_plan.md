# Current feature plan

> **Anchor for in-progress feature work.** This is the single source of truth for
> what we're building *right now* and how. Update it as the plan changes; when a
> feature ships, summarize the outcome in [devlog.md](devlog.md) and repoint this
> file at the next feature.

- **Active feature:** Strategic map mode (in-system travel)
- **Branch:** `feat/strategic-map` (stacked on `feat/ship-topdown-view`, PR #1)
- **Status:** scaffolding — placeholder mode + mode switching in place

## Goal

Add the **strategic map** game mode: a zoomed-out view of the current star system
where the player picks where to travel. It is the deliberate counterpart to the
real-time tactical combat mode. See game-design [§4.1](game-design.md).

## Design decisions

- **Content:** a graph of star-system **nodes** connected by **links**. The
  player selects a node to set it as the travel target.
- **Travel model:** travel along links **and** freely by clicking anywhere in the
  system. → *Free click-travel is planned but NOT to be built yet; design so it
  slots in later.*
- **State:** **full scene swap** between modes for now — no shared state. A
  `GameState` autoload (current system, chosen target, ship status) comes later,
  once persistence across modes is actually needed.
- **Mode transition:** entering/leaving the map is an **in-world trigger** (e.g.
  an action/menu), not a raw key. The current **Tab** toggle in `ModeManager` is
  a temporary dev shortcut until the real trigger exists.

## Increment plan

1. [ ] Render system nodes + links (static layout).
2. [ ] Hover/select a node → highlight; mark it as the travel target.
3. [ ] Travel along links to the selected target.
4. [ ] *(planned)* Free click-to-travel to any point (not links-only).
5. [ ] *(later)* `GameState` autoload to persist target/system across modes.
6. [ ] *(later)* Replace the Tab toggle with an in-world enter/exit trigger.

## Open questions

- Node layout: authored per system, or generated?
- What does "arrive at a node" hand off to (back into tactical combat)?
- How the map represents distance/energy cost of a jump.
