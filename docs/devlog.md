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
