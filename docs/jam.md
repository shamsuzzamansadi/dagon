# Jam Context: GitHub Game Off 2026

Jam page: https://itch.io/jam/game-off-2026. Last checked 2026-10-28.

**How this was checked:** the itch.io pages return HTTP 403 to automated
fetching, and I did not try to bypass that. The facts below come from search
excerpts of the official jam page, and they match the project owner's reading
of the page. Re-read the page in a browser on 2026-11-01 after the theme
announcement.

## 1. Confirmed requirements

| Item | Value |
|---|---|
| Host | GitHub & Lee Reilly |
| Development period | The month of November 2026 |
| Theme announcement | 2026-11-01 |
| Submission window (itch.io) | 2026-11-01 21:37 UTC → **2026-12-01 21:37 UTC** (13:37 PST, 22:37 Europe/Berlin) |
| Source code | Must be in a **public GitHub repository**, pushed before the deadline |
| Submission | On itch.io |
| Tools | Any languages, engines and libraries |
| Judging categories | Overall, Gameplay, Graphics, Audio, Innovation, **Theme Interpretation** |
| Voting ends | 2027-01-01 13:37 PST |

## 2. Unresolved points (not assumed either way)

| Topic | What is known | What is open |
|---|---|---|
| **Theme** | It is announced 2026-11-01. | The theme itself, and how strictly it is judged beyond the "Theme Interpretation" category. |
| **Pre-existing work and existing projects** | A participant asked in [topic 7170868](https://itch.io/jam/game-off-2026/topic/7170868/there-a-theme). The project owner reports no host answer. Earlier editions' FAQ (Game Off 2024) allowed pre-made code and assets with attribution, and discouraged resubmitting old projects with minor changes. **That is not a 2026 rule.** | Whether pre-jam design documents, a toolchain probe, or a template-derived repository skeleton are acceptable in 2026. |
| **Template reuse** | Libraries and engines are allowed. godot-cpp is MIT; godot-cpp-template is Unlicense (public domain) boilerplate. | Whether template boilerplate counts as "pre-existing project" work. **Unresolved. Not treated as either permitted or prohibited.** Its use will be disclosed in the README regardless. |
| **AI disclosure** | In [topic 7079155](https://itch.io/jam/game-off-2026/topic/7079155/will-there-be-a-way-to-separate-ai-generated-games), the host said the submission form will identify AI use, and the granularity was still under consideration. I have not read that post directly; this is from the project owner's reading plus a secondary write-up. No AI ban has been found. | The final form options. **Do not anticipate them.** Answer whatever the form asks, accurately, using §5. Community opinions in that thread are not rules. |
| Asset and code licensing | No requirement found beyond a public repository. | Re-check on 2026-11-01. |

## 3. Our conservative schedule policy

This is our own choice. It is not a claim that the organizer bans
preparation.

- **No gameplay implementation before the jam starts and the theme has been
  checked for fit.**
- Before the start, work is limited to planning documents and the toolchain
  evidence in `docs/evidence/`, which is a probe and not game code.
- **Repository:** https://github.com/shamsuzzamansadi/dagon. The owner
  created it on 2026-10-28 at 06:35 UTC. It is public, with default branch
  `main`. On 2026-10-28 it was **empty: no commits, so no AI co-author
  trailers to check.**
  - No game code is pushed before the jam starts.
  - The pre-jam documents and toolchain evidence go into the first commits,
    dated honestly. The README discloses what existed before the jam (§6).
- **Commit authorship:** commits use the owner's own Git identity. They carry
  no AI author, co-author or `Co-authored-by` trailers, and no automatic
  assistant footers in commits or PR descriptions. Claude Code's attribution
  is disabled in `.claude/settings.json`. This is separate from, and does not
  replace, the AI-use disclosure in the README, this document (§5) and the
  submission form.

## 4. Theme-fit gate (before M1)

On 2026-11-01, after the announcement:

1. Read the official theme statement in a browser (project owner), and record
   it here verbatim.
2. Write a short theme-fit note here: how DAGON's mechanics or story, not just
   its title, express the theme.
3. If the fit needs **substantial** changes to the core loop, the act
   structure or the puzzle, bring the owner a concise proposal before writing
   any code. Small changes (a renamed act, a new clue motif) are recorded here
   and in `gdd.md`.
4. Re-check §2 for any new official rulings.
5. Only then start M1.

## 5. AI-assisted workflow record (for honest disclosure)

| Role | Who / what | Scope |
|---|---|---|
| Direction, decisions, playtesting, final approval, upload and submission | Human project owner | All |
| Architecture, documentation, C++ code, tests, CI configuration | **Claude (Anthropic), via Claude Code**, working under the owner's direction | Expected to author most source code and documents |
| Independent design and code review | **ChatGPT (OpenAI)**, relayed by the owner | Review only |
| Placeholder art and audio | Silhouette polygons and shaders made in the editor or by scripts, and procedurally generated audio, produced with AI assistance | First playable |
| Final assets | Decided before M4 | Each asset's provenance (human, AI-assisted, or third-party CC0/OFL) recorded in `CREDITS.md` |

On the submission form, choose the option that most accurately matches this
table. If the form only offers yes/no, the answer is **yes**.

## 6. Pre-jam work log

| Date | Work | Kind |
|---|---|---|
| 2026-10-28 | GDD, architecture, toolchain, roadmap, risks, decisions; two review rounds | Planning documents |
| 2026-10-28 | Toolchain probe: C++20 GDExtension load test and import-crash investigation, plus the reproducible package and `reproduce.sh` (`docs/evidence/import-crash/`) | Toolchain evidence, not game code |
| 2026-10-28 06:35 UTC | Owner created the empty public GitHub repository | Repository setup |
| — | **No gameplay implementation before the jam start and theme-fit gate** | — |
