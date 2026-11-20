"""Stages the creature's head turn so it can be read: from the owner's playtest of 2026-11-19, where by the time "Its head
turned. I ran." was on screen the camera was already leaving the head. Run once from the repository root, on the scene
as wire_reveal_m5.py, wire_figures_m5.py and wire_audio_m5.py left it.

Within the clip's same 14 s, and with every line, sound and the clip's end where they were:
  - the head lowers toward the sailor by 0.16 rad (about 9 degrees) from 11.4 s to 12.5 s, where it lowered 0.055 rad
    by 12.2 s; it turns about the same neck, and its keys before 11.4 s are unchanged;
  - the camera holds its wide view on the head until 12.8 s, where it began to leave at 12.0 s, and is back on the
    sailor at 13.8 s as before, eased in and out, so the turn and the line's start are seen with the head in frame.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from scene_edit import Scene, v2

# The same functions as wire_reveal_m5.py's section 4, which cannot be imported: it rebuilds the scene when run.
def smooth(u):
    u = max(0.0, min(1.0, u)); return u * u * (3 - 2 * u)
def span(t, t0, t1):
    return (t - t0) / (t1 - t0)
def rot(a, p):
    return (p[0] * math.cos(a) - p[1] * math.sin(a), p[0] * math.sin(a) + p[1] * math.cos(a))
def times(t0, t1, step=0.1):
    n = round((t1 - t0) / step)
    return [round(t0 + i * step, 3) for i in range(n + 1)]
BREATH = 3.335
def breath(t, start):
    return 0.0 if t < start else 0.5 - 0.5 * math.cos(2 * math.pi * (t - start) / BREATH)
NECK = (30, -256)


def head_angle(t, amount, t1):
    back = 0.05 * (smooth(span(t, 3.2, 3.8)) - smooth(span(t, 4.4, 5.4)))
    return back - amount * smooth(span(t, 11.4, t1))


def head_at(t, amount, t1, shift):
    a = head_angle(t, amount, t1); r = rot(a, NECK); turn = smooth(span(t, 11.4, t1))
    return (NECK[0] - r[0] - shift[0] * turn, NECK[1] - r[1] + shift[1] * turn - 2 * breath(t, 7.83))


AS_WIRED = (0.055, 12.2, (4, 2))
STAGED = (0.16, 12.5, (6, 4))

s = Scene("project/scenes/level/shore.tscn")
c = s.clip("clip_dagon_reveal")
ts = times(3.0, 14.0)

# The scene must be as wire_reveal_m5.py baked it, key for key, or this is not the edit it says it is.
track = c.tracks[c.find("Dagon/Head:rotation")[0]]
assert '"values": [' + ", ".join("%.4f" % head_angle(t, *AS_WIRED[:2]) for t in ts) + "]" in track, "the head's rotation keys are not as wired"
track = c.tracks[c.find("Dagon/Head:position")[0]]
assert '"values": [' + ", ".join(v2(round(head_at(t, *AS_WIRED)[0], 2), round(head_at(t, *AS_WIRED)[1], 2)) for t in ts) + "]" in track, "the head's position keys are not as wired"
for t in ts:
    if t < 11.4:
        assert head_angle(t, *STAGED[:2]) == head_angle(t, *AS_WIRED[:2]) and head_at(t, *STAGED) == head_at(t, *AS_WIRED), t

c.set_value("Dagon/Head:position", ts, [v2(round(head_at(t, *STAGED)[0], 2), round(head_at(t, *STAGED)[1], 2)) for t in ts])
c.set_value("Dagon/Head:rotation", ts, ["%.4f" % head_angle(t, *STAGED[:2]) for t in ts])

# The camera: the same marks, the wide view held 0.8 s longer, and the return to the sailor eased.
assert c.find("CameraRig:zoom") and c.find("CameraMarks/Reveal:position")
assert '"times": PackedFloat32Array(2.5, 7, 12, 13.8)' in c.tracks[c.find("CameraRig:zoom")[0]]
assert '"times": PackedFloat32Array(0.05, 2.5, 7, 12, 13.8)' in c.tracks[c.find("CameraMarks/Reveal:position")[0]]
c.set_value("CameraRig:zoom", [2.5, 7, 12.8, 13.8], [v2(1, 1), v2(0.5, 0.5), v2(0.5, 0.5), v2(1, 1)], [1, 1, -2, 1])
c.set_value("CameraMarks/Reveal:position", [0.05, 2.5, 7, 12.8, 13.8], [v2(4304, -30), v2(4304, -30), v2(4560, -120), v2(4560, -120), v2(4304, -30)], [1, 1, 1, -2, 1])
c.save()
s.save()
print("staged")
