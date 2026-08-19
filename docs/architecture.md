# Architecture

> Keep this current as the project grows. When you add or restructure a major
> system, update the relevant section in the same feature branch.

## Overview

Early scaffold. The Godot project (`project.godot`, Godot 4.6) boots a single
top-level scene that displays the player ship in a top-down view. Systems will be
added as self-contained scenes wired by signals as the game grows.

## Scene tree & entry point

- **Main scene:** `res://scenes/main/main.tscn` (set in `project.godot` →
  `run/main_scene`).
- `Main` (`Node2D`) holds a `Camera2D` centered on the origin and an instance of
  the self-contained `Ship` scene. This is the current entry point; scene
  swapping is not needed yet.

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
  nose. **Forward is -Y** (nose points up), so a later `look_at`/velocity can
  align the nose with a heading.
- Hull is tunable from the inspector (`front_length`, `tail_length`,
  `half_width`, colors, outline) and redraws live.
- Inputs: none yet (static view).
- Signals emitted/consumed: none yet.

## Data & resources

_Custom `Resource` types and where game data lives (`.tres` files)._

## Communication patterns

_How systems are decoupled — signals, EventBus autoload, direct calls. See
[guidelines.md](guidelines.md#node--scene-patterns)._

## Key decisions

_Short list of structural decisions and the "why". Detailed reasoning and
chronology go in [devlog.md](devlog.md)._

-
