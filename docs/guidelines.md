# Godot Development Guidelines

Living document of conventions and best practices for this project. Start with
the generic Godot guidance below and refine it as the project teaches us more.
When a rule changes, update it here and note the change in
[devlog.md](devlog.md).

- **Engine:** Godot 4.x
- **Language:** GDScript by default
- **Style baseline:** [Official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
  and [Best practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)

### Core principles

The sections further down are the *how*. These principles are the *why* — the
handful of ideas everything else follows from. When a concrete rule and a
principle seem to conflict, favor the principle and fix (or note) the rule.

1. **Decouple through events.** Systems should not know about each other's
   internals. Talk through signals locally and an `EventBus` autoload globally,
   so any system can be built, changed, or tested in isolation.
   → [Events & signals](#events--signals)
2. **One responsibility per unit.** Every script/scene does one thing well. Grow
   behavior by *adding* small pieces, not by *enlarging* existing ones — no god
   classes. → [Single responsibility](#single-responsibility--no-god-classes)
3. **Compose, don't inherit.** Build entities from small, reusable nodes/scenes
   wired together, rather than deep inheritance hierarchies.
   → [Node & scene patterns](#node--scene-patterns)
4. **Scenes are self-contained.** A scene owns its own tree and can run on its
   own; it exposes intent via signals and `@export`, not by reaching into
   neighbors. *Signals up, calls down.* → [Node & scene patterns](#node--scene-patterns)
5. **Data over code.** Model tunables and content as editable `Resource` data
   (`.tres`), not hardcoded constants, so designers can change the game without
   touching scripts. → [Resources & data](#resources--data)
6. **Be explicit.** Prefer typed, greppable, editor-visible code (static types,
   `@export`, named signals) over clever implicit behavior. Clarity beats
   brevity. → [GDScript style](#gdscript-style)
7. **Keep the repo light.** Code and scene/resource files stay in the main repo;
   raw binary assets live in the submodule. History stays reviewable.
   → [Assets](#assets-git-submodule--lfs)
8. **Verify continuously, document as you go.** After a non-trivial change, do a
   headless run to catch errors, and update the relevant doc in the same branch.
   → [Running Godot](#running-godot)

The first three are **non-negotiable** for this project; the rest are strong
defaults — deviate only with a reason noted in [devlog.md](devlog.md).

---

## Running Godot

The Godot executable is in the repository root. Useful invocations (replace
`Godot.exe` with the actual filename):

```powershell
# Open the project in the editor
./Godot.exe --editor --path .

# Run the main scene
./Godot.exe --path .

# Run a specific scene
./Godot.exe --path . res://path/to/scene.tscn

# Headless run (CI / quick error check, no window)
./Godot.exe --headless --path . --quit

# Run a one-off script (tools, tests)
./Godot.exe --headless --path . --script res://tools/my_script.gd
```

> After any non-trivial change, do a headless run to catch parse/load errors
> before committing.

---

## Project structure

Organize by feature/domain, not by file type. Keep scenes self-contained.

```
res://
  scenes/        # .tscn scenes, grouped by feature (player/, ui/, levels/)
  scripts/       # shared/global scripts not tied to one scene
  autoload/      # singletons registered as Autoload (GameState, EventBus, ...)
  assets/        # GIT SUBMODULE — art, audio, fonts (see "Assets" below)
  resources/     # custom Resource data (.tres) and Resource scripts
  addons/        # third-party plugins
  tests/         # test scenes/scripts
```

- Co-locate a scene's script with its `.tscn` (e.g. `player.tscn` +
  `player.gd`).
- Each scene should be runnable on its own where practical.
- See Godot's [Project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
  and [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html).

---

## Assets (git submodule + LFS)

Keep large binary assets (art, audio, models, fonts) **out of the main code
repo** so history stays light and code reviews stay readable.

**Chosen approach:** a dedicated **assets repo mounted as a git submodule** at
`res://assets/`, with **Git LFS enabled inside that assets repo** for binaries.
Submodule = clean separation and fast code clones; LFS = keeps even the assets
repo's history light. Use both together.

Rules:

- **Pin deliberately.** A submodule records an exact commit. Bump it in its own
  commit (e.g. `chore: bump assets to <sha>`) so asset updates are reviewable
  and revertible.
- **Commit in the submodule first**, push it, *then* bump the pointer in the
  main repo. Never point at an unpushed asset commit.
- **Pointer bump = separate commit** from code changes.
- Code and `.tres`/`.tscn` files stay in the **main** repo; only **raw** asset
  files (`.png`, `.wav`, `.ogg`, `.glb`, `.fbx`, …) live in the submodule.
- **Stable folder layout** in the assets repo — Godot stores resource paths, so
  moving files breaks references. Decide the structure early.
- LFS-track binaries via the assets repo's `.gitattributes`.

Commands:

```powershell
# Clone the project with assets
git clone --recurse-submodules <url>

# After pulling code that bumped the submodule
git submodule update --init --recursive

# Optional: auto-update submodules on pull/checkout
git config submodule.recurse true
```

- **Open item:** create the assets submodule repo, enable Git LFS in it, define
  the `.gitattributes` tracked patterns, and add it here with
  `git submodule add <assets-url> assets`. A ready-to-copy LFS config is in
  [assets-gitattributes.template](assets-gitattributes.template) — copy it to
  the assets repo root as `.gitattributes`.

---

## Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Files & folders | `snake_case` | `player_controller.gd`, `main_menu.tscn` |
| Classes (`class_name`) | `PascalCase` | `class_name PlayerController` |
| Nodes in the tree | `PascalCase` | `PlayerSprite`, `HealthBar` |
| Functions & variables | `snake_case` | `func take_damage(amount):` |
| Private members | leading `_` | `var _velocity`, `func _on_timer()` |
| Constants & enums | `CONSTANT_CASE` | `const MAX_SPEED = 400` |
| Signals | past tense `snake_case` | `signal health_changed(new_value)` |
| Booleans | `is_`/`has_`/`can_` prefix | `is_alive`, `can_jump` |

---

## GDScript style

- Always declare types: `var speed: float = 200.0`, `func heal(amount: int) -> void:`.
  Typed code is faster and catches errors early.
- Use tabs for indentation (Godot default).
- Prefer `@onready var node := $Path` over fetching nodes repeatedly.
- Put `class_name`, then `extends`, then signals, then constants, then exported
  vars, then regular vars, then `_ready`/lifecycle, then methods.
- Use `@export` to expose tunables to the editor instead of hardcoding.
- Avoid `get_node()` with long string paths in hot loops; cache references.

---

## Node & scene patterns

- **Composition over inheritance.** Build behavior from small nodes/scenes
  rather than deep script inheritance.
- **Signals up, calls down.** A child emits a signal; the parent decides what to
  do. Parents may call into children directly. Avoid children reaching up into
  parents.
- Keep global state in **Autoload singletons** (e.g. `GameState`), not scattered
  static vars. See [Autoloads vs regular nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_regular_nodes.html).
- Free nodes with `queue_free()`, not `free()`, during normal gameplay.
- Use **groups** (`add_to_group`) for "all enemies"-style queries.

---

## Events & signals

**Systems communicate through events, not direct references.** This keeps
systems independent and testable.

- **Local communication:** use a node's own `signal`s. A child emits; the parent
  (or whoever owns it) connects and reacts. *Signals up, calls down.*
- **Cross-cutting / global events:** route through an **`EventBus` autoload** —
  a singleton that only declares signals and is emitted/connected from anywhere
  (e.g. `EventBus.player_died`, `EventBus.score_changed`).
- Name signals in **past tense**: `health_changed`, `enemy_spawned`,
  `level_completed`.
- Connect in code with `EventBus.player_died.connect(_on_player_died)`; prefer
  this over editor connections for global events so usage is greppable.
- **Always disconnect** signals you connected manually when the listener is
  freed, and check `is_instance_valid()` before using a possibly-freed emitter.
- Don't overuse the bus: if two nodes have a clear parent/child relationship,
  use a local signal or direct call instead. The bus is for genuinely decoupled
  systems.
- Reference: [Godot interfaces](https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_interfaces.html).

```gdscript
# autoload/event_bus.gd  (registered as Autoload "EventBus")
extends Node

signal player_died
signal score_changed(new_score: int)
```

---

## Single responsibility / no god classes

Keep scripts small and focused. A class that knows about "everything" becomes a
maintenance and merge-conflict magnet.

- **One responsibility per script.** If a script handles movement *and* combat
  *and* inventory *and* UI, split it.
- **Split by composition:** add child nodes/scenes each owning one concern
  (e.g. `HealthComponent`, `MovementComponent`, `HitboxComponent`) and wire them
  with signals. Prefer this over one large `player.gd`.
- **Rules of thumb** (guidelines, not hard limits): a script doing more than a
  handful of distinct jobs, or growing past a few hundred lines, is a signal to
  refactor. Don't preemptively over-split tiny scripts either.
- **Autoloads stay thin.** `GameState`/`EventBus` hold state or signals, not
  gameplay logic.
- Put shared pure logic in small helper classes/`Resource`s rather than a
  catch-all "utils god file".
- References:
  [OO principles in Godot](https://docs.godotengine.org/en/stable/tutorials/best_practices/what_are_godot_classes.html),
  [Scenes vs scripts](https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html),
  [Logic preferences](https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html).

---

## Resources & data

- Model reusable data (items, stats, level configs) as custom `Resource`
  subclasses saved as `.tres`. This keeps data editable in the inspector and out
  of code.
- Prefer `preload()` for assets known at compile time, `load()` for dynamic.
- `.tres`/`.tscn` files live in the main repo; the **raw assets they point at**
  live in the [assets submodule](#assets-git-submodule--lfs).
- Reference: [Data preferences](https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html).

---

## Performance & safety

- Do per-frame work in `_process`; physics/movement in `_physics_process`.
- Don't allocate in tight loops; reuse arrays/objects where possible.
- Guard nullable node references; check `is_instance_valid()` before using a
  node that may have been freed.
- Disconnect signals when freeing objects that connected them manually.

---

## Version control

- Commit the Godot project files: `project.godot`, `.tscn`, `.tres`, `.gd`,
  `*.import`.
- Use a Godot `.gitignore` (ignore `.godot/`, `export_presets.cfg` secrets,
  build output). Add one before the first commit if missing.
- **Raw assets go in the [assets submodule](#assets-git-submodule--lfs)**, not the
  main repo. Bump the submodule pointer in its own commit.
- Keep scene/script changes reviewable — large binary churn stays in the
  submodule.
- Reference: [Version control systems](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html).

---

## Testing & debugging (to formalize)

- Quick check: headless run (above) to catch load errors.
- Consider [GUT](https://github.com/bitwes/Gut) or
  [GdUnit4](https://github.com/MikeSchulze/gdUnit4) for unit tests once the
  codebase warrants it.
- When we settle on a workflow, capture it here and consider a dedicated
  test/debug agent.

---

## Open conventions (decide as we go)

- [ ] Confirm exact Godot version (`project.godot` → `config/features`).
- [ ] GDScript-only, or GDScript + C# for hot paths?
- [ ] Test framework choice (GUT vs GdUnit4).
- [ ] Input map naming scheme.
- [ ] Localization approach (if any).
- [ ] Create the **assets submodule** repo (plain git vs Git LFS) and wire it up.
