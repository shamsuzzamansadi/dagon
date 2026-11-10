# Jam Context: GitHub Game Off 2026

Jam page: https://itch.io/jam/game-off-2026. Last checked 2026-11-02.

**How this was checked:**
- Read directly on 2026-11-02: the
  [GitHub theme announcement](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/).
- **Not readable from the development environment:** the itch.io jam page and
  [FAQ](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq)
  return HTTP 403 to automated fetching, and that was not bypassed. FAQ facts
  below were checked directly by the independent reviewer and relayed by the
  project owner; they are marked *(FAQ, relayed)*.

## 1. Confirmed requirements

| Item | Value | Source |
|---|---|---|
| Host | GitHub & Lee Reilly | Jam page |
| **Theme** | **SHIFT.** "How you interpret the theme is entirely up to you." | Announcement |
| Submission window (itch.io) | Closes **2026-12-01 21:37 UTC** (13:37 PST, 22:37 Europe/Berlin) | Announcement |
| Source code | Must live in a GitHub repository, pushed before the deadline | Announcement |
| Tools | Any languages, engines and libraries | Jam page |
| Judging categories | Overall, Gameplay, Graphics, Audio, Innovation, **Theme Interpretation** | Jam page |
| Voting ends | 2027-01-01 13:37 PST | Announcement |
| **Templates and starter projects** | Welcome | Announcement; FAQ, relayed |
| **Reusable code** | Permitted | FAQ, relayed |
| **Pre-jam repository and environment preparation** | Permitted | FAQ, relayed |
| **Most game development** | Must occur during the jam | FAQ, relayed |
| **AI-assisted development** | Allowed. "When submitting your game, you'll be asked about your use of AI." | Announcement; FAQ, relayed |

Our internal submission target remains **2026-11-29 21:37 UTC**.

## 2. Remaining open points

| Topic | Status |
|---|---|
| Final wording of the AI question on the submission form | Seen only when the form is filled in. Answer it accurately from §5. Do not anticipate the options. |
| Any other change on the FAQ page | The owner should glance at the FAQ again at M7 before submitting, because this environment cannot read it. |

The earlier open questions on pre-existing work, template reuse and whether
AI-assisted work is allowed are **resolved** by §1.

## 3. Repository and preparation record

- **Repository:** https://github.com/shamsuzzamansadi/dagon, created by the
  owner on 2026-10-28 at 06:35 UTC. Public, default branch `main`. It was empty
  until the first push on 2026-11-02.
- **Pre-jam work** was limited to planning documents and toolchain evidence
  (§6). No gameplay code was written before the jam started and the theme was
  checked. The first commit imports that material unchanged. Its commit date is
  2026-11-02, the day it was committed; the actual preparation date is recorded
  here and in the commit message. History is not backdated or rewritten.
- **Commit authorship:** commits use the owner's own Git identity. They carry
  no AI author, co-author or `Co-authored-by` trailers, and no automatic
  assistant footers in commits or PR descriptions. Claude Code's attribution
  is disabled in `.claude/settings.json`. This is separate from, and does not
  replace, the AI-use disclosure in the README, this document (§5) and the
  submission form.

## 4. Theme-fit assessment (G0, completed 2026-11-02)

**Verdict: DAGON fits SHIFT with no change to the core loop, architecture, act
structure or scope.** The concept and title stay. The theme is expressed by
making what the design already contains legible to the player. M1 may proceed.

| Shift | Meaning | What the player actually sees and does | Delivered by | Milestone |
|---|---|---|---|---|
| **Physical** | The seabed has been displaced from beneath the ocean. | Waking on exposed seabed beside a stranded boat, with the sea only a thin band far beyond it, drawn back unnaturally far ([D21](decisions.md)). Fish rotting on the mud. No surf where it should be, only a faint, far-off sea. Walking across terrain that is plainly ocean floor: rib arch, fossils, drained trench. | Act I–II layout, existing examine captions, ambience | M3 (layout, captions), M4 (ambience, silhouettes) |
| **Interpretive** | The glyph sequence restores the mural's meaning, turning apparent ruins into evidence of worship. | **Before solving:** examining the mural gives a caption describing eroded, meaningless carvings, and the mural is dim and fragmentary. **After solving:** the same mural, examined in the same place, is lit and readable, and its caption describes figures bowing to a vast swimmer. The player's own action caused that change. | The existing puzzle and mural Interactable. One caption swap on the Awakened beat, plus the existing `monolith_awaken` clip | M3 (caption swap, greybox lit state), M5 (final art) |
| **Perceptual** | The reveal changes the player's understanding of the landscape and their own scale; exploration becomes escape. | The camera pulls back far enough to make the sailor tiny. What read as a far ridge or background shape turns out to be part of the creature. The direction of travel reverses: the player walked right for the whole game and must now run left, back over ground that means something different. | Existing `dagon_reveal` camera framing, the Dagon parallax layer, the existing Fleeing beat | M3 (framing, flee), M5 (final reveal) |

**What exists now and what is planned (updated 2026-11-04).** M3 is implemented, awaiting independent review, and not accepted by the owner, who found it not yet engaging enough ([record](evidence/m3/owner-playtest-2026-11-04.md)).

| Shift | In the standard build today | Still planned |
|---|---|---|
| Physical | The exposed seabed on the Shore: wet flats, the sea far beyond the stranded boat, dead fish. **M3:** examine captions, fossils, rib arch, in greybox | Drained trench, and all ambience (M4) |
| Interpretive | **M3, in greybox:** tablets, mural, puzzle and caption swap | Final art and sound (M5) |
| Perceptual | **M3, in greybox:** the camera pull-back, a far ridge that becomes part of the creature, and the turn from exploration to escape | The final reveal (M5) |

**Explicitly not added:** dimension switching, alternate physics, a new player
verb, a new puzzle system, another ending. The optional perception shaders stay
stretch work after M6 and are not needed for this interpretation.

**Requirements this adds to existing work, and nothing else:**
1. M3: the mural has a before and an after caption, swapped as part of the
   Awakened beat's C++ essential outcome so a missing clip cannot leave it
   unchanged.
2. M3 and M5: at least one far-background silhouette is placed so it visibly
   becomes part of Dagon during the reveal.
3. M3: playtest check: can a player describe what the mural meant before and
   after solving it?
4. M3 to M5 (owner direction, 2026-11-02): at each relevant story beat, the player meets
   the change through a visible event and through sound, not only in documents (GDD §7).
   This does not justify a new mechanic or wider scope.

The submission page should state this interpretation in one or two sentences
(M7).

## 5. AI-assisted workflow record (for honest disclosure)

| Role | Who / what | Scope |
|---|---|---|
| Direction, decisions, playtesting, final approval, upload and submission | Human project owner | All |
| Architecture, documentation, C++ code, tests, CI configuration, greybox scenes | **Claude (Anthropic), via Claude Code**, working under the owner's direction | Authors most source code and documents |
| Independent design and code review | **ChatGPT (OpenAI)**, relayed by the owner | Review only |
| Placeholder art and audio | Silhouette polygons and shaders made in the editor or by scripts, and procedurally generated audio, produced with AI assistance | First playable |
| Shore art | Pixel art drawn by Python scripts written and tuned with AI assistance (Claude), under the owner's direction, who accepted the art direction. No image generators or third-party art | Shipped in the standard build (`docs/shore-preview.md`) |
| UI font and text | An original pixel font drawn by a Python script, and menu, controls, credits and caption text, written with AI assistance (Claude) under the owner's direction | M2 |
| Audio | **A first sound pass, synthesized by code the AI wrote** (`tools/audio/make_sounds.py`): ambience, footsteps, effects, breathing and music. No recordings or sample libraries ([record](evidence/m3/audio/README.md)). **Narration in an AI-generated voice, the owner's choice of two candidates:** Chatterbox performing in the timbre of a Kokoro stock voice, watermarked by its maker ([record](evidence/m3/voice-audition/README.md)). Disclose both on the submission form, and never describe either as recorded or performed by a person | M3, brought forward by the owner (D70) |
| Final assets | Decided before M4 | Each asset's provenance (human, AI-assisted, or third-party CC0/OFL) recorded in `CREDITS.md` |

On the submission form, choose the option that most accurately matches this
table. If the form only offers yes/no, the answer is **yes**.

## 6. Pre-jam work log

| Date | Work | Kind |
|---|---|---|
| 2026-10-28 | GDD, architecture, toolchain, roadmap, risks, decisions; review rounds | Planning documents |
| 2026-10-28 | Toolchain probe: C++20 GDExtension load test and import-crash investigation, plus the reproducible package and `reproduce.sh` (`docs/evidence/import-crash/`) | Toolchain evidence, not game code |
| 2026-10-28 06:35 UTC | Owner created the empty public GitHub repository | Repository setup |
| — | **No gameplay implementation before the jam start and theme-fit gate** | — |
| 2026-11-02 | First commit of the above; G0 completed; M1 started | Jam work begins |
