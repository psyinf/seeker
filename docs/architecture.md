# Architecture

> Keep this current as the project grows. When you add or restructure a major
> system, update the relevant section in the same feature branch.

## Overview

_High-level description of how the game is structured. Fill in once the first
systems exist._

## Scene tree & entry point

- **Main scene:** _(set in `project.godot` → `run/main_scene`)_
- _Describe the top-level scene composition and how scenes are loaded/swapped._

## Autoloads (singletons)

| Name | Script | Responsibility |
|------|--------|----------------|
|      |        |                |

## Major systems

_One subsection per system (input, player, combat, save/load, UI, audio, ...).
For each: what it does, key scenes/scripts, and how it talks to other systems._

### (example) Player
- Scenes/scripts:
- Inputs:
- Signals emitted/consumed:

## Data & resources

_Custom `Resource` types and where game data lives (`.tres` files)._

## Communication patterns

_How systems are decoupled — signals, EventBus autoload, direct calls. See
[guidelines.md](guidelines.md#node--scene-patterns)._

## Key decisions

_Short list of structural decisions and the "why". Detailed reasoning and
chronology go in [devlog.md](devlog.md)._

-
