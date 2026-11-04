# Instructions for coding agents

This file is for any coding agent working on this repository, whichever tool runs it. It holds the rules that last. **What is happening right now is in [docs/handoff.md](docs/handoff.md): read that next.** Do not put progress here.

## What this is

*DAGON: Beneath the Black Tide*, a short 2D horror game for GitHub Game Off 2026 (theme: SHIFT). Godot 4.7.2, with gameplay in C++20 through GDExtension.

| To learn | Read |
|---|---|
| What the game is | [docs/gdd.md](docs/gdd.md) |
| How it is built, and the cinematic contract | [docs/architecture.md](docs/architecture.md) |
| Why it is that way | [docs/decisions.md](docs/decisions.md), numbered and cited as D1, D2, ... |
| What each milestone holds, and when | [docs/roadmap.md](docs/roadmap.md) |
| What could go wrong | [docs/risks.md](docs/risks.md) |
| Building, and versions | [README.md](README.md), [docs/toolchain.md](docs/toolchain.md) |
| Releases | [docs/release.md](docs/release.md) |
| Jam rules and AI disclosure | [docs/jam.md](docs/jam.md) |
| Past reviews, and the form a review package takes | [docs/reviews/](docs/reviews/) |

## Working rules

**Honesty about what happened**
- Never claim a review, owner acceptance, physical-device validation or audio-quality approval that did not happen. Record the owner's words as the owner's, limited to what they said.
- Green CI is technical evidence. It does not establish gameplay quality.
- Do not label a scripted or developer-informed run as a first-time playtest. Say who or what ran each result, on which commit.
- Deferred checks stay deferred until someone actually does them. Do not infer a pass from something nearby.
- Keep placeholder work described as placeholder. Plumbing is not finished production.

**Other people's work**
- Preserve unrelated and uncommitted work. Look before deleting or overwriting.
- Do not change the owner's active desktop keyboard layout, and do not interfere with their desktop during automated gameplay tests. Graphical runs belong on a private display, such as Xvfb, or on CI. Reading the current layout is fine.

**Git**
- `main` is the only long-lived branch. Work on temporary feature branches, through pull requests. GitHub refuses direct pushes to `main`, even for admins (D47).
- The order is: review, CI on GCC, Clang and MSVC, owner acceptance, squash merge, CI on the resulting `main` commit, then delete the branch and prune (D43). After a squash there is no ancestry, so check the pull request's merged state rather than `git branch --merged`.
- A hold on one task, such as "stop for review", takes precedence over this general authorization to merge.
- Use the owner's existing Git identity. Add no AI author or co-author trailers, and no "generated with" footers. AI use is disclosed separately, in the README and [docs/jam.md](docs/jam.md) §5.
- Never force-push `main`.

**Releases**
- Do not publish a release or a tag, or submit to itch.io, without the gates in [docs/release.md](docs/release.md) and the owner's authorization. Reaching a milestone publishes nothing.

**Testing**
- Reuse valid evidence, and name the commit it covers. Repeat a broad campaign only when a change, a failure or an unresolved risk justifies it.
- Run `tools/run_godot_checks.sh` rather than the test runner alone: only the script applies the check for unexpected errors.
- A test that sets out to cause an error names it with `h.expect_error(text)` (D53).

**Scope**
- Before adding anything, check the milestone's scope in the roadmap and any exclusions in the handoff. If it needs more than was approved, write down a small concrete proposal and its schedule cost for the owner, and carry on with authorized work meanwhile.
- Duration is not the goal in itself. Do not lengthen play by slowing movement, forcing waits, adding empty corridors or adding more text.

## The handoff

[docs/handoff.md](docs/handoff.md) records the changing state: milestone, commits, scope, results and next action.

- Update it before stopping, before handing off, and when approaching a usage or context limit.
- Each result in it names the commit it covers.
- Temporary paths and task identifiers in it may be gone by the time they are read. Check before relying on them, and prefer what is pushed.
- It never holds credentials or tokens. Nor does anything else here.

## Code conventions

- C++ is in namespace `dagon`, tabs, formatted by `.clang-format`. `src/core/` is plain C++ with no Godot, tested natively with doctest in `tests/unit/`.
- A gameplay consequence belongs in C++. An animation clip is only a picture of it, so that a missing or stuck clip cannot stop the game (architecture §5).
- Scene connections are not made from inside instanced scenes (D37).
- Comments explain why, and only when the code cannot.
- Decisions that change how something works go in `docs/decisions.md` as the next D-number.
