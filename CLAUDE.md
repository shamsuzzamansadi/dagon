# Claude Code

Read [AGENTS.md](AGENTS.md) first: it holds this project's rules for every agent. Then read [docs/handoff.md](docs/handoff.md) for the current state. Do not copy rules from there to here.

Claude-specific notes only:

- `.claude/settings.json` turns off commit and pull request attribution. Leave it that way.
- When a session resumes after a limit or a summary, background tasks may not have finished and their results may not have been read. Check the real state before continuing, and update the handoff before stopping.
- A background waiter that polls with `pgrep -f <text>` matches its own command line and never ends. Use a pattern that cannot match itself, such as `breakage[.]py`.
- On this machine the working copy is on a Windows mount, where builds are slow. Long builds and tests have been run from a native Linux clone, pushing to the same branch. The handoff names the current one. Pull into the working copy afterwards, without disturbing other work there.
