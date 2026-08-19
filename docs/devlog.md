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

## 2026-08-19 — Development workflow doc  (branch: docs/workflow)

**Did:** Added [workflow.md](workflow.md) — branch naming, Conventional Commits +
SemVer bump mapping, PR hygiene (`gh`, temp-file bodies, `| cat`), CI-failure
triage, and a local quick-change debugging loop. Wired it into
[AGENTS.md](../AGENTS.md) (doc map + "prepare, don't push") and cross-linked the
debugging loop from [guidelines.md](guidelines.md).

**Why:** Extracted the genuinely reusable, tool-agnostic ideas from an internal
plugin marketplace (`Hillrom-Enterprise/surgical-skills`) without taking a
dependency on it — the doc is self-contained repo text. Deliberately dropped the
Jira/Atlassian/Baxter-specific parts, which don't apply to this project.

**Learned:** The reusable core of that "workflow" skill is Conventional Commits,
SemVer, PR/CI hygiene, and the debug loop; everything Jira was org-specific.
Keeping it as plain docs (not a plugin) means zero external dependency.

**Follow-ups:** Kept in sync with the godot-project-template copy; revisit if we
adopt a test framework or actually set up CI.

---

**Did:** Ran the design questionnaire with the user and filled in
[design-questionnaire.md](design-questionnaire.md), then wrote the first draft of
[game-design.md](game-design.md) from those answers.

**Why:** Lock the concept and an MVP before writing code. Seeker is a 2D top-down
space journey: command an upgradable ship, manage minerals/energy/tech-fragments,
survey and jump between nodes, and upgrade to face bigger threats on the way
"home" (the ship's origin). Tone: lonely/contemplative with tense survival beats.
Persistent progression; optional combat. MVP = travel between nodes, hit an
event, collect, and buy one capability-changing upgrade.

**Learned:** Core pillar is resource management → upgrades (which cost resources
and raise energy use). Several unknowns remain: travel model (node-jump vs.
free-flight blend), encounter resolution (real-time vs. paused), energy model and
failure states, enemy/event roster.

**Follow-ups:** Resolve the open questions in the GDD; then scaffold the first
gameplay feature (candidate: node star-map + jump). Art/audio stay placeholder.

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
