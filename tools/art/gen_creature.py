"""Draws the creature of the reveal, over the shapes the reveal's clip moves (scenes/level/shore.tscn, under Dagon).

It is drawn at half the world's size and doubled, because it is only seen whole when the camera has drawn back to
half: every block of it is then one pixel of the screen, and nothing folds or shimmers as it rises.

One light throughout: the moon, high and to the right, as the Monolith has it. Each part is a height field (its mass,
its muscle, its scales) lit from there, so its top and right catch the light and its left stands dark against the
haze and the pale stone, which is where it most needs to be told from what is behind it.

Each part is two images. The base is the dark body, as the fog first gives it up. The lit image holds only what the
moon and the wet pick out, and the clip fades it in over the base.

    dagon_<part>.png, dagon_<part>_lit.png    body, head, crest, arm
    dagon_ridge.png                           the shoulder as it shows before the reveal: the same pixels as the body's
    dagon_shoulder.png, dagon_shoulder_lit.png
                                              the body's own pixels wherever the arm, turning, crosses it: laid over
                                              the arm, so that it comes out from under the shoulder's outline (D120)
    dagon_<part>_reach.png                    body, head, crest: how far each pixel lies from the ridge, 0 on it and
                                              255 at the farthest that shows (D119); arm: how far from the shoulder,
                                              0 at it and 255 at the fingertips (D120). Not artwork: data for the
                                              shader the parts come out through, project/assets/reveal/emerge.gdshader
"""

import math
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from scipy import ndimage

from art_common import BAYER, Noise
from palette import rgba

SKIN = ["C0", "C1", "T0", "T1", "T2", "T3"]
LIGHT = np.array([0.50, -0.76, 0.42])
LIGHT = LIGHT / np.linalg.norm(LIGHT)

# The point on the body's outline that the reveal's clip turns the arm about, and how far it turns it either way
# (D107). A test holds the clip to them.
SHOULDER = (-305, -166)
ARM_TURN = (-0.5, 0.22)
# The arm's root is rounded about that point, so that its outline there is the same at every turn.
SHOULDER_RADIUS = 27
# What shows of the creature once the fog has left it: down to the water, at y = -9 in the world, with the creature
# then 41 px up from its rest (the reveal's clip at 4.3 s).
SHOWN_TO = -9 + 41


def frame(points):
    """A part's place: its top left corner in the creature's space, on even numbers, and its size at half scale."""
    left = math.floor(min(x for x, _ in points) / 2) * 2
    top = math.floor(min(y for _, y in points) / 2) * 2
    width = math.ceil((max(x for x, _ in points) - left) / 2) + 1
    height = math.ceil((max(y for _, y in points) - top) / 2) + 1
    return left, top, width, height


def raster(polygons, left, top, width, height):
    image = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(image)
    for points in polygons:
        draw.polygon([((x - left) / 2, (y - top) / 2) for x, y in points], fill=255)
    return np.array(image) > 0


def soften(mask, radius):
    """Rounds a polygon's corners, so the outline is a body's and not a drawing's."""
    return ndimage.gaussian_filter(mask.astype(float), radius) > 0.5


def bump(shape, cx, cy, sx, sy, amount):
    yy, xx = np.mgrid[0 : shape[0], 0 : shape[1]]
    return amount * np.exp(-(((xx - cx) / sx) ** 2) - ((yy - cy) / sy) ** 2)


def groove(shape, path, width, depth):
    """A cut along a path of points: a height to take away."""
    image = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(image).line(path, fill=255, width=width)
    return -depth * ndimage.gaussian_filter(np.array(image) / 255.0, 0.7)


def scales(shape, cell, seed, lift=1.0):
    """Scales as a field of low domes on a staggered lattice, a little uneven. Lit from above, each catches the light
    on its upper side and shadows the one below it."""
    noise = Noise(seed)
    h, w = shape
    out = np.zeros(shape)
    for y in range(h):
        for x in range(w):
            u = x + 2.2 * (noise(x / 23.0, y / 23.0) - 0.5) * cell
            v = y + 2.2 * (noise(x / 23.0 + 40.0, y / 23.0) - 0.5) * cell
            row = math.floor(v / (cell * 0.8))
            best = 0.0
            for r in (row - 1, row, row + 1):
                cx = (math.floor((u - (r % 2) * cell / 2) / cell) + 0.5) * cell + (r % 2) * cell / 2
                for c in (cx - cell, cx, cx + cell):
                    cy = (r + 0.5) * cell * 0.8
                    d = math.hypot((u - c) / (cell * 0.62), (v - cy) / (cell * 0.62))
                    best = max(best, 1.0 - d * d)
            out[y, x] = max(0.0, best)
    return lift * out


def light_on(mask, height):
    """How much of the moon each pixel of a height field takes, and which way its edge faces."""
    height = ndimage.gaussian_filter(height, 0.6)
    gy, gx = np.gradient(height)
    normal = np.stack([-gx, -gy, np.ones_like(gx)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    lambert = normal @ LIGHT
    half = LIGHT + np.array([0.0, 0.0, 1.0])
    half /= np.linalg.norm(half)
    gloss = np.clip(normal @ half, 0, 1) ** 26
    depth = ndimage.distance_transform_edt(mask)
    ey, ex = np.gradient(ndimage.gaussian_filter(depth, 1.2))
    norm = np.hypot(ex, ey) + 1e-6
    facing = (-ex / norm) * LIGHT[0] + (-ey / norm) * LIGHT[1]
    return lambert, gloss, depth, facing


def mass(mask, bulge):
    depth = ndimage.distance_transform_edt(mask)
    return bulge * (1.0 - np.exp(-depth / (bulge * 0.8)))


def paint(mask, lambert, gloss, depth, facing, seed, dim=None, wet=1.0, rim=1.0, streaks=0):
    """Turns light into the palette, as two images: the dark base, and what the moon and the wet pick out."""
    h, w = mask.shape
    noise = Noise(seed)
    rng = random.Random(seed + 1)
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lit = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tone = np.zeros((h, w), dtype=int)
    for y in range(h):
        for x in range(w):
            if not mask[y, x]:
                continue
            fall = 1.0 if dim is None else dim[y, x]
            value = 0.5 + 6.0 * max(0.0, lambert[y, x] - 0.40) * fall + 0.35 * (noise.fractal(x / 17.0, y / 17.0, 2) - 0.5)
            # The edge that faces the moon: a wet rim, brightest where it faces it squarely.
            if depth[y, x] <= 2.0 and facing[y, x] > 0.15:
                value = max(value, (3.2 + 1.9 * facing[y, x] - 0.8 * (depth[y, x] - 1.0)) * rim * (0.35 + 0.65 * fall))
            # The edge that faces away is lit a little by the pale stone it faces: enough to part it from the rock.
            elif depth[y, x] <= 1.0 and facing[y, x] < -0.35:
                value = max(value, 1.9 * (0.4 + 0.6 * fall))
            value = max(0.0, min(value, len(SKIN) - 1.0))
            index = int(value)
            if index < len(SKIN) - 1 and 0.5 + (value - index - 0.5) / 0.3 > (BAYER[y % 4][x % 4] + 0.5) / 16.0:
                index += 1
            tone[y, x] = index
            # The base keeps only a hint of its form: nearly all of it is the dark of the body.
            dark = 0 if value < 2.2 else (1 if value < 4.3 else 2)
            base.putpixel((x, y), rgba(SKIN[dark]))
            if index != dark:
                lit.putpixel((x, y), rgba(SKIN[index]))
            if gloss[y, x] * wet * fall > 0.55 and noise(x / 2.0, y / 2.0) > 0.52:
                lit.putpixel((x, y), rgba("T4" if gloss[y, x] * fall > 0.8 else "T3"))
    # Water running off it: thin broken runs downward from the lit edges.
    for _ in range(streaks):
        x = rng.randrange(w)
        column = [y for y in range(h) if mask[y, x]]
        if not column:
            continue
        y = column[0] + rng.randrange(2, 9)
        for k in range(rng.randrange(6, 26)):
            if y + k < h and mask[y + k, x] and (k + x) % 4 and tone[y + k, x] < 4:
                lit.putpixel((x, y + k), rgba("T2" if k < 5 else "T1"))
    return base, lit


def double(image):
    return image.resize((image.width * 2, image.height * 2), Image.NEAREST)


# ---------------------------------------------------------------- the parts


def body(points):
    left, top, w, h = frame(points)
    mask = soften(raster([points], left, top, w, h), 2.5)
    # Spines down the back, the crest's own carried on: they break the long slope of the far shoulder.
    spines = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(spines)
    for cx, cy, tall in ((228, 14, 7), (243, 21, 8), (259, 27, 9), (276, 33, 8), (292, 40, 7), (305, 52, 6), (315, 66, 5)):
        draw.polygon([(cx - 5, cy + 5), (cx + 3, cy - tall), (cx + 6, cy + 7)], fill=255)
    mask = mask | ((np.array(spines) > 0) & (np.mgrid[0:h, 0:w][1] < w - 1))
    shape = mask.shape
    yy, xx = np.mgrid[0:h, 0:w]
    height = mass(mask, 16.0)
    height += bump(shape, 96, 78, 62, 50, 11.0)  # the near shoulder
    height += bump(shape, 252, 92, 58, 60, 6.0)  # the far one, and the back
    height += bump(shape, 176, 18, 48, 24, 5.0)  # the root of the neck
    # The front, toward the stone: broad plates lapping downward, each lit along its top.
    front = np.clip((118 + 14 * np.sin(yy / 40.0) - xx) / 26.0, 0, 1)
    plate = ((yy + 7 * np.cos((xx - 40) / 46.0)) / 21.0) % 1.0
    height += 1.7 * front * (1.0 - plate) ** 0.6
    # Scales over the shoulder and the back, larger over the mass of the shoulder.
    hide = 1.0 - front
    height += hide * scales(shape, 9, 631, 1.9) * np.clip((150 - yy) / 60.0, 0.25, 1)
    # Three gill slits in the side of the neck.
    for k in range(3):
        x0 = 196 + k * 9
        height += groove(shape, [(x0, 8), (x0 + 3, 20), (x0 + 2, 34), (x0 - 2, 44)], 2, 3.2)
    lambert, gloss, depth, facing = light_on(mask, height)
    # It goes down into spray and black water: the light leaves it toward the foot.
    dim = np.clip(1.15 - yy / 190.0, 0.12, 1.0)
    base, lit = paint(mask, lambert, gloss, depth, facing, 641, dim=dim, streaks=22)
    return (double(base), double(lit), (left, top)), mask


def head(points):
    left, top, w, h = frame(points)
    mask = soften(raster([points], left, top, w, h), 1.6)
    shape = mask.shape
    height = mass(mask, 9.0)
    height += bump(shape, 52, 12, 22, 6, 4.5)  # the brow, heavy over the eye
    height += bump(shape, 98, 44, 26, 18, 4.0)  # the hinge of the jaw
    height += bump(shape, 30, 34, 26, 8, 2.5)  # the snout's upper ridge
    # The mouth: a long cut from the snout back to the hinge, the upper jaw standing over the lower.
    mouth = [(2, 47), (20, 50), (44, 52), (68, 53), (88, 49)]
    height += groove(shape, mouth, 2, 5.5)
    lower = Image.new("L", (w, h), 0)
    ImageDraw.Draw(lower).polygon(mouth + [(96, 70), (0, 70)], fill=255)
    height -= 2.2 * ndimage.gaussian_filter(np.array(lower) / 255.0, 1.0)
    # The socket, dark until the eye opens in it; a nostril; the gill covers behind the jaw.
    height += bump(shape, 51, 20, 11, 5, -5.0)
    height += groove(shape, [(41, 21), (51, 22), (61, 20)], 1, 2.5)
    height += bump(shape, 9, 40, 2, 1.5, -3.0)
    for k, x0 in enumerate((108, 117, 125)):
        height += groove(shape, [(x0, 24), (x0 + 4, 36), (x0 + 3, 48), (x0 - 1, 58)], 2, 3.4 - k * 0.5)
    height += scales(shape, 6, 633, 1.1) * np.clip((np.mgrid[0:h, 0:w][1] - 58) / 30.0, 0, 1)
    lambert, gloss, depth, facing = light_on(mask, height)
    base, lit = paint(mask, lambert, gloss, depth, facing, 643, streaks=4)
    # Teeth: a row of pale points under the upper jaw, toward the front.
    for i, x in enumerate(range(7, 62, 5)):
        y = round(48 + (x - 2) * 0.075) + 1
        for k in range(2 if i % 3 else 3):
            if mask[min(h - 1, y + k), x]:
                lit.putpixel((x, y + k), rgba("C6" if k == 0 else "C4"))
                base.putpixel((x, y + k), rgba("C2"))
    return double(base), double(lit), (left, top)


def crest(points):
    """A fin along the skull: six spines and the web between them, its edge scalloped from tip to tip."""
    left, top, w, h = frame(points)
    mask = raster([points], left, top, w, h)
    shape = mask.shape
    yy, xx = np.mgrid[0:h, 0:w]
    tips = sorted(((x - left) / 2, (y - top) / 2) for x, y in points if (y - top) / 2 < h * 0.48)
    height = np.where(mask, 1.6, 0.0)
    rays = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(rays)
    for tx, ty in tips:
        draw.line([(tx, ty), (tx - 7 + 0.02 * tx, h + 6)], fill=255, width=2)
    spine = ndimage.gaussian_filter(np.array(rays) / 255.0, 0.8)
    height += 4.5 * spine
    lambert, gloss, depth, facing = light_on(mask, height)
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lit = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    noise = Noise(645)
    for y in range(h):
        for x in range(w):
            if not mask[y, x]:
                continue
            on_spine = spine[y, x] > 0.35
            # The web is thin: the moon behind it shows through, most near its edge, in ribs that follow the spines.
            through = max(0.0, 1.0 - depth[y, x] / 9.0) * (0.6 + 0.4 * noise(x / 1.5, y / 9.0))
            base.putpixel((x, y), rgba("C0" if on_spine else ("C1" if through < 0.55 else "T0")))
            if on_spine:
                if lambert[y, x] > 0.5 or (depth[y, x] <= 1.5 and facing[y, x] > 0.1):
                    lit.putpixel((x, y), rgba("T3" if depth[y, x] <= 1.5 else "T2"))
            elif depth[y, x] <= 1.2 and facing[y, x] > 0.0:
                lit.putpixel((x, y), rgba("T3"))
            elif through > 0.42:
                lit.putpixel((x, y), rgba("T2" if through > 0.72 else "T1"))
    return double(base), double(lit), (left, top)


def shoulder_disc():
    cx, cy = SHOULDER
    return [(cx + SHOULDER_RADIUS * math.cos(a), cy + SHOULDER_RADIUS * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 48, endpoint=False)]


def arm(points):
    """The arm and its hand. Its root is rounded about the shoulder it turns on: it ended in a straight cut, which the
    moon lit like an outer edge, and whose corner stood clear of the body."""
    disc = shoulder_disc()
    left, top, w, h = frame(points + disc)
    mask = raster([points, disc], left, top, w, h)
    # The web between the fingers, from the knuckles to half their length.
    web = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(web)
    for quad in (((28, 7), (15, 5), (14, 12), (28, 13)), ((27, 14), (14, 13), (14, 19), (27, 20)), ((28, 21), (15, 22), (18, 29), (29, 27))):
        draw.polygon(list(quad), fill=255)
    webbed = (np.array(web) > 0) & ~mask
    whole = mask | webbed
    shape = whole.shape
    height = mass(whole, 6.0)
    height += bump(shape, 62, 30, 26, 12, 3.0)  # the forearm
    height += bump(shape, 30, 17, 4, 12, 2.2)  # the knuckles
    height -= 2.5 * webbed
    lambert, gloss, depth, facing = light_on(whole, height)
    base, lit = paint(whole, lambert, gloss, depth, facing, 647, streaks=5, rim=1.05)
    # The web is thinner and darker than the fingers; claws, pale at the tips.
    for y in range(h):
        for x in range(w):
            if webbed[y, x]:
                base.putpixel((x, y), rgba("C1" if (x + y) % 2 else "T0"))
                if lit.getpixel((x, y))[3] and depth[y, x] > 1.5:
                    lit.putpixel((x, y), (0, 0, 0, 0))
    for tip_x, tip_y in ((3, 0), (0, 11), (1, 23), (7, 35)):
        for dx in range(4):
            for dy in range(-1, 3):
                x, y = tip_x + dx, tip_y + dy
                if 0 <= x < w and 0 <= y < h and mask[y, x]:
                    lit.putpixel((x, y), rgba("C7" if dx < 2 else "C5"))
                    base.putpixel((x, y), rgba("C3" if dx < 2 else "C2"))
    return double(base), double(lit), (left, top)


def parts(polygon):
    """Every image of the creature, by file name without its extension, with its place in the creature's space.
    polygon(name) gives a part's outline from the scene."""
    out = {}
    (base, lit, at), body_mask = body(polygon("Body"))
    out["dagon_body"], out["dagon_body_lit"] = (base, at), (lit, at)
    # The ridge is the near shoulder, seen before anyone knows it for one: the body's own pixels inside its shape. The
    # shape runs a little outside the body's own outline on the left and over the top, so the ridge's edge there is
    # the body's: the line followed along it before the reveal is the shoulder's as it rises. It goes on below the
    # water at its foot (gen_reveal.ridge_water), which hides it until it lifts.
    ridge = Image.new("L", base.size, 0)
    ImageDraw.Draw(ridge).polygon([(x - at[0], y - at[1]) for x, y in polygon("Ridge")], fill=255)
    ridge = ridge.filter(ImageFilter.MaxFilter(5))
    shown = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shown.paste(base, (0, 0), ridge)
    box = shown.getbbox()
    box = (box[0] // 2 * 2, box[1] // 2 * 2, box[2], box[3])
    out["dagon_ridge"] = (shown.crop(box), (at[0] + box[0], at[1] + box[1]))
    for name, draw in (("head", head), ("crest", crest), ("arm", arm)):
        base, lit, at = draw(polygon(name.capitalize()))
        out[f"dagon_{name}"], out[f"dagon_{name}_lit"] = (base, at), (lit, at)
    out.update(shoulder(out))
    out.update(reach(polygon, body_mask))
    return out


def shoulder(out):
    """The body's own pixels wherever the arm crosses the body at any turn the clip gives it, with a little to spare
    for the screen's rounding. Laid over the arm, they put its root under the shoulder's outline, so that the arm
    always comes out from the body and never shows where it was cut."""
    body_base, (bx, by) = out["dagon_body"]
    body_lit, _ = out["dagon_body_lit"]
    arm_base, (ax, ay) = out["dagon_arm"]
    # The arm's shape, placed in the body's image, turned about the shoulder through the clip's whole turn.
    placed = Image.new("L", body_base.size, 0)
    placed.paste(arm_base.getchannel("A"), (ax - bx, ay - by))
    pivot = (SHOULDER[0] - bx, SHOULDER[1] - by)
    swept = Image.new("L", body_base.size, 0)
    for turn in np.arange(ARM_TURN[0] - 0.04, ARM_TURN[1] + 0.045, 0.005):
        swept = ImageChops.lighter(swept, placed.rotate(-math.degrees(turn), resample=Image.NEAREST, center=pivot))
    cover = ImageChops.multiply(swept.filter(ImageFilter.MaxFilter(7)), body_base.getchannel("A"))
    box = cover.getbbox()
    box = (box[0] // 2 * 2, box[1] // 2 * 2, box[2], box[3])
    images = {}
    for name, source in (("dagon_shoulder", body_base), ("dagon_shoulder_lit", body_lit)):
        image = Image.new("RGBA", body_base.size, (0, 0, 0, 0))
        image.paste(source, (0, 0), cover)
        images[name] = (image.crop(box), (bx + box[0], by + box[1]))
    return images


def reach(polygon, body_mask):
    """For the body, the head and the crest, how far each pixel lies from the ridge, in the creature's space at rest,
    as a grey image at the half scale the parts are drawn at: 0 on the ridge, 255 at the farthest pixel that shows
    when the fog has gone. The reveal's shader brings each part out where its fade has reached (D119)."""
    frames = {"body": frame(polygon("Body")), "head": frame(polygon("Head")), "crest": frame(polygon("Crest"))}
    left = min(f[0] for f in frames.values())
    top = min(f[1] for f in frames.values())
    right = max(f[0] + 2 * f[2] for f in frames.values())
    bottom = max(f[1] + 2 * f[3] for f in frames.values())
    w, h = (right - left) // 2, (bottom - top) // 2
    # As wide as the ridge's drawing, which takes in two pixels round its shape.
    ridge = ndimage.binary_dilation(raster([polygon("Ridge")], left, top, w, h))
    distance = 2.0 * ndimage.distance_transform_edt(~ridge)
    shows = np.zeros((h, w), dtype=bool)
    fl, ft, fw, fh = frames["body"]
    rows = np.arange(fh)[:, None] * 2 + ft < SHOWN_TO
    shows[(ft - top) // 2:(ft - top) // 2 + fh, (fl - left) // 2:(fl - left) // 2 + fw] |= body_mask & rows
    for name in ("head", "crest"):
        fl, ft, fw, fh = frames[name]
        shows[(ft - top) // 2:(ft - top) // 2 + fh, (fl - left) // 2:(fl - left) // 2 + fw] |= raster([polygon(name.capitalize())], fl, ft, fw, fh)
    farthest = distance[shows].max()
    value = np.clip(np.round(255.0 * distance / farthest), 0, 255).astype(np.uint8)
    out = {}
    for name, (fl, ft, fw, fh) in frames.items():
        part = value[(ft - top) // 2:(ft - top) // 2 + fh, (fl - left) // 2:(fl - left) // 2 + fw]
        out[f"dagon_{name}_reach"] = (Image.fromarray(part, "L"), (fl, ft))
    out["dagon_arm_reach"] = arm_reach(polygon("Arm"))
    return out


def arm_reach(points):
    """For the arm, at rest, how far each pixel lies from the shoulder it turns on, as a grey image at the half scale
    it is drawn at: 0 over its rounded root, 255 at the fingertips. Through the shader, its fade-in brings it out from
    the shoulder to the hand (D120), where it faded in whole, the hand dark against the pale stone and the rest lost
    against the night."""
    disc = shoulder_disc()
    left, top, w, h = frame(points + disc)
    yy, xx = np.mgrid[0:h, 0:w]
    distance = np.hypot(left + 2 * xx + 1 - SHOULDER[0], top + 2 * yy + 1 - SHOULDER[1]) - SHOULDER_RADIUS
    farthest = distance[raster([points, disc], left, top, w, h)].max()
    value = np.clip(np.round(255.0 * distance / farthest), 0, 255).astype(np.uint8)
    return Image.fromarray(value, "L"), (left, top)
