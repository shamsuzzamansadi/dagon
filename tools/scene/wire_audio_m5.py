"""One local change to the reveal's sound: the water's cascade and surge are lowered under the reveal's first line,
which they were measured to mask in the voice's own band (docs/evidence/m5/audio). Nothing else, and no bus, is
touched. Run once from the repository root."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from scene_edit import Scene

s = Scene("project/scenes/level/shore.tscn")
c = s.clip("clip_dagon_reveal")
assert not c.find("Sound/WaterCascade:volume_db")
# It starts at its own level with the body at 3 s, falls under the line that begins at 4.3 s, and is put back after
# it has died away, for the next time the clip plays.
c.set_value("Sound/WaterCascade:volume_db", [3.0, 4.15, 4.45, 13.0, 13.9], ["-6.0", "-6.0", "-13.0", "-13.0", "-6.0"])
# The surge, which swells to its loudest at 4.5 s, just as that line begins.
assert not c.find("Sound/WaterSurge:volume_db")
c.set_value("Sound/WaterSurge:volume_db", [1.5, 4.15, 4.45, 13.0, 13.9], ["-4.0", "-4.0", "-9.0", "-9.0", "-4.0"])
c.save()
s.save()
print("wired")
