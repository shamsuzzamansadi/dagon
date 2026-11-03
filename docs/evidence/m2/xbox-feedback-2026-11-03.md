# Owner feedback: physical Xbox controller, 2026-11-03

**Reported by the owner, relayed in their message on 2026-11-03:**

> I have now physically tested an Xbox controller. The controls I tried worked correctly, but the menus do not explain the
> controller mappings, and the interaction button is unclear.

**What this establishes:** positive owner feedback for the controls they exercised, on the Windows build they had.

**What it does not establish:**

- Which buttons those were. The message does not list them, so no individual button is recorded as passed here.
- Which commit or artifact was used. The message does not say, and this record does not infer it.
- Anything about every button, or every controller interaction.
- Anything about PlayStation hardware, which nobody has tried.
- Anything about Xbox or PlayStation console platforms. Testing a controller on Windows does not establish console support,
  and consoles are not targets.

**What the feedback changed:**

- Controls now explains the controller from both menus, and the introduction shows the controls for the device in use.
- Prompts name the button for the device in use, because a bare "X" was unclear, and wrong on PlayStation ([D39](../../decisions.md)).

**A related limit:** in every export up to `d78f5a6`, the Hud received nothing from the Interactor, whichever device pressed the
button (see [examine/](examine/README.md)). So if the owner pressed X near something in such a build, it would have done nothing visible. That
follows from the code. It was not observed with a controller, and it may be part of why the interaction button seemed unclear.

**Still deferred to M6, and not passed:** the individual Xbox buttons in the review package's manual check, and all physical PlayStation coverage. The owner's later [acceptance of M2](owner-acceptance-2026-11-03.md) does not list them either.
