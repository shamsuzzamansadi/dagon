"""Where the reveal's clip turns the creature's arm (D107, D120), for gen_creature.py, which draws to it, and for
check_art.py, which checks against it and must run where NumPy is not installed. A test holds the clip to it."""

# The point on the body's outline that the arm turns about, in the creature's space.
SHOULDER = (-305, -166)
# How far the clip turns it either way, in radians.
ARM_TURN = (-0.5, 0.22)
# The arm's root is rounded about that point, so that its outline there is the same at every turn.
SHOULDER_RADIUS = 27
