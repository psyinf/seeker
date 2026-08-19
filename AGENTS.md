# Project: Seeker (Godot game)

A game built with the [Godot Engine](https://godotengine.org/). The Godot
executable lives in the repository root — invoke it directly to run, export, or
script the editor (see [docs/guidelines.md](docs/guidelines.md#running-godot)).

> This file is the always-on briefing for AI coding agents. Keep it short and
> link to the docs below instead of duplicating their content.

## Documentation map

| Topic | File | Use it for |
|-------|------|-----------|
| Godot conventions & best practices | [docs/guidelines.md](docs/guidelines.md) | How we write GDScript, structure scenes, name things |
| Development workflow | [docs/workflow.md](docs/workflow.md) | Branches, commits, PRs, CI, and the local debugging loop |
| Game design / concept | [docs/game-design.md](docs/game-design.md) | What the game *is* (filled in later) |
| Architecture | [docs/architecture.md](docs/architecture.md) | How the project is wired together |
| Devlog & learnings | [docs/devlog.md](docs/devlog.md) | Decisions made, things learned, gotchas hit |

## Working agreement (read before making changes)

- **Feature branches.** Never commit directly to `main`. Create a branch per
  feature/fix (e.g. `feat/player-movement`, `fix/save-load`). Do not push or
  force-push without the user's say-so. See
  [docs/workflow.md](docs/workflow.md) for branch/commit/PR conventions.
- **Prepare, don't push.** Report changed files, verification result, and a
  *suggested* commit message; only stage/commit/push/open a PR when explicitly
  asked — see [docs/workflow.md](docs/workflow.md#core-behavior-for-humans-and-ai-agents).
- **Document as you go.** When you finish a meaningful change, update the
  relevant doc in the same branch:
  - new/changed structure → [docs/architecture.md](docs/architecture.md)
  - a decision, a fix, or a lesson learned → [docs/devlog.md](docs/devlog.md)
  - a new convention → [docs/guidelines.md](docs/guidelines.md)
- **Follow the guidelines.** Apply [docs/guidelines.md](docs/guidelines.md) for
  all Godot/GDScript work. If you deviate, note why in the devlog.
- **Verify before committing.** Open the project in Godot (or run headless) to
  confirm it loads without script/scene errors — see
  [docs/guidelines.md](docs/guidelines.md#running-godot).

## Conventions at a glance

- Engine: **Godot 4.x**, language **GDScript** (use C# only where a doc says so).
- **Communicate via events** — local signals or an `EventBus` autoload; don't
  couple systems with direct references.
- **No god classes** — one responsibility per script; split large nodes into
  smaller scenes/components wired by signals.
- **Assets live in a git submodule**, not the main code repo.
- See [docs/guidelines.md](docs/guidelines.md) for file layout, naming, and
  patterns — that file is the source of truth and grows over the project.

## Future tooling

When recurring needs appear, propose dedicated agents/skills (e.g. a
debug-helper, a test-runner, an export/build helper) rather than ad-hoc steps.
