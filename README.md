# Seeker — Godot game

A starter template for [Godot 4.x](https://godotengine.org/) games built
**with AI coding agents in the loop**. It ships the conventions, documentation
scaffolding, and Git/asset setup so you can start building features on day one
instead of bikeshedding structure.

> Using this as a base? On GitHub, click **Use this template** to create your own
> repo, then work through [Getting started](#getting-started) below.

## What's inside

| File / folder | What it gives you |
|---------------|-------------------|
| [AGENTS.md](AGENTS.md) | Always-on briefing for AI coding agents — working agreement and a map to the docs. |
| [docs/guidelines.md](docs/guidelines.md) | Godot/GDScript conventions: structure, naming, events, anti-god-class rules, assets, version control. The source of truth. |
| [docs/game-design.md](docs/game-design.md) | Empty, structured game design document to fill in. |
| [docs/architecture.md](docs/architecture.md) | Skeleton for documenting systems as you build them. |
| [docs/devlog.md](docs/devlog.md) | Running log of decisions and lessons learned. |
| [.gitignore](.gitignore) | Godot 4 ignores (engine cache, exports, secrets, OS noise). |
| [docs/assets-gitattributes.template](docs/assets-gitattributes.template) | Git LFS patterns for the separate assets repo. |

## Principles

The distilled *why* behind the conventions (full list + rationale in
[docs/guidelines.md](docs/guidelines.md#core-principles)):

- **Decouple through events** — local signals or an `EventBus` autoload; no
  tight coupling between systems.
- **One responsibility per unit** — no god classes; grow behavior by adding
  small pieces, not enlarging existing ones.
- **Compose, don't inherit** — build entities from small, reusable
  nodes/scenes wired together.
- **Scenes are self-contained** — expose intent via signals/`@export`; *signals
  up, calls down*.
- **Data over code** — model tunables/content as editable `Resource` (`.tres`),
  not hardcoded constants.
- **Be explicit** — typed, greppable, editor-visible code over clever implicit
  behavior.
- **Keep the repo light** — code/scenes in the main repo; raw assets in a
  submodule (with Git LFS).
- **Verify + document continuously** — feature branches, a headless run before
  committing, and doc updates in the same branch.

The first three are non-negotiable; the rest are strong defaults.

## Getting started

1. **Create your repo** from this template (GitHub → *Use this template*), or
   clone it.
2. **Add the Godot engine** executable to the repo root (or install Godot 4.x
   separately) — see [running Godot](docs/guidelines.md#running-godot).
3. **Initialize the Godot project** (open the folder in Godot, or add a
   `project.godot`). Commit the project files.
4. **Set up the assets submodule** when you have assets to add:
   ```sh
   # in a separate assets repo:
   git lfs install
   # copy docs/assets-gitattributes.template -> .gitattributes, commit
   # back in this repo:
   git submodule add <assets-url> assets
   ```
5. **Fill in** [docs/game-design.md](docs/game-design.md) and start building on a
   feature branch.

## Workflow

- Branch per feature/fix (`feat/...`, `fix/...`); never push to `main` without
  the user's say-so.
- When you finish a meaningful change, update the relevant doc in the same
  branch (architecture, devlog, or guidelines).
- Verify the project loads (a [headless run](docs/guidelines.md#running-godot))
  before committing.

## License

[MIT](LICENSE) © psyinf. Note the asset submodule may carry its own license —
keep third-party asset licensing separate from this code license.
