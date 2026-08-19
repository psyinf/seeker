# Development Workflow

How a change moves from idea to merged code: branch → implement → verify →
commit → PR → CI. Adapted for a solo/small-team Godot project — no issue-tracker
integration required, but it plays nicely with GitHub issues if you use them.

> These are conventions, not a straitjacket. Deviate with a reason and note it in
> [devlog.md](devlog.md).

## Core behavior (for humans and AI agents)

- **Prepare, don't push.** By default, report the files changed, the verification
  result, and a *suggested* commit message or PR body. Perform a Git or PR action
  (stage, commit, push, open/update PR) only when explicitly asked to.
- **Confirm before anything hard to undo.** Deleting branches, force-pushing,
  history rewrites, and destructive resets are confirmed first, never done as a
  shortcut.
- **Repository rules win.** [AGENTS.md](../AGENTS.md) and
  [guidelines.md](guidelines.md) are the source of truth; follow them over any
  general habit.
- **Verify before you commit.** Run the project (headless is fine) so it loads
  without script/scene errors — see
  [guidelines.md](guidelines.md#running-godot).

---

## Branches

- **Never commit directly to `main`.** One branch per feature/fix.
- Name it `<type>/<short-kebab-desc>`, where `<type>` matches the commit types
  below: `feat/star-map`, `fix/save-load`, `docs/workflow-notes`,
  `refactor/event-bus`.
- Keep it short, lowercase, letters/numbers/hyphens only.
- If you track work in GitHub issues, you may append the number:
  `feat/star-map-42`.

---

## Commits — Conventional Commits

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Rules

- **Description ≤ ~10 words** (aim for ≤ 5), imperative mood, lowercase, no
  trailing period. Communicate intent, not mechanics.
- **Scope** = the code area/domain touched (e.g. `player`, `ui`, `starmap`).
  Optional but encouraged.
- Reference a GitHub issue in the footer if relevant: `Refs: #42` or
  `Closes #42`.

### Types

| Type | Use for |
|------|---------|
| `feat` | New behavior/capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Internal restructuring, no behavior change |
| `perf` | Performance improvement |
| `test` | Tests added/updated |
| `chore` | Maintenance / non-gameplay (e.g. `chore: bump assets to <sha>`) |
| `build` / `ci` | Build, export, or CI changes |

### Breaking changes

- Mark with `!`: `feat(save)!: change save format`, **or** a footer
  `BREAKING CHANGE: <what and how to migrate>`.

### Version bump mapping (if/when you tag releases)

Per [SemVer 2.0.0](https://semver.org/) (`MAJOR.MINOR.PATCH`):

| Commit signal | Bump |
|---|---|
| `fix` | PATCH |
| `feat` | MINOR |
| `!` or `BREAKING CHANGE` footer | MAJOR |
| other types | no automatic bump |

---

## Pull requests (GitHub `gh`)

Only when asked. The `gh` CLI auto-detects the repo from the git remote.

- **Suppress the pager** by piping through `cat`: `gh pr view | cat`.
- **Multi-line bodies via a temp file** to avoid shell-escaping pain — never a
  fragile inline heredoc:

  ```bash
  # write the body to tmp/pr-body.md first, then:
  gh pr create --title "feat(starmap): node-jump travel" --body-file tmp/pr-body.md --base main | cat
  rm tmp/pr-body.md
  ```

- **PR body content:** a clear objective (what and why), a summary of changes by
  area/file, and the testing/verification approach. Link related issues.

Common commands:

```bash
git branch --show-current
git diff main...HEAD --name-status
gh pr create --fill | cat
gh pr view <n> | cat
gh pr status | cat
```

- **Merging:** only when explicitly instructed. Prefer **rebase** over merge
  commits/squashes: `gh pr merge <n> --rebase | cat`.

---

## Debugging CI failures

```bash
gh run list --limit 10 | cat            # did the same tests pass on main recently?
gh run view <run-id> --log-failed | cat # just the failed steps
gh run view --job=<job-id> --log | cat  # full log for one job
gh run rerun <run-id> --failed | cat    # re-run only failed jobs (transient?)
```

If the same tests passed on `main` recently, the failure is likely
PR-related or transient rather than a broken pipeline.

---

## Local debugging loop (quick-change workflow)

A fast, disciplined loop for isolating a bug:

1. **Form a specific hypothesis** about where and why it fails.
2. **Add a targeted trace** at the suspected boundary — `print()` /
   `push_warning()` / `push_error()` to Godot's Output/stderr. Never spam a data
   channel a tool parses (e.g. stdout of a `--script` that emits structured
   output).
3. **Re-run the narrowest thing** that reproduces it — a single scene or a
   headless run (`Godot.exe --headless --path . --quit`).
4. **Iterate** until the root cause is isolated; classify it (logic bug, unclear
   API contract, bad data/resource, flaky test).
5. **Apply the minimal fix** and re-run to confirm.
6. **Remove all temporary debug scaffolding** — prints, dummy nodes, commented
   experiments.
7. If the cause was non-obvious, **capture the lesson** in
   [devlog.md](devlog.md).

---

## When work is ready

Report: files changed, verification result (what you ran and that it loaded
clean), a suggested Conventional Commit message, and — if a PR is wanted — a
proposed body. Then let the user decide what to actually run.
