"""The one palette every preview asset is drawn with (docs/shore-preview.md)."""

PALETTE = {
    # Cold ramp: sky, sea haze, moonlight, the sailor's coat.
    "C0": "0a0e18", "C1": "121a2a", "C2": "1b2638", "C3": "263448", "C4": "34455a",
    "C5": "475a6f", "C6": "637789", "C7": "8497a6", "C8": "aebcc4", "C9": "dfe6e6",
    # Sickly teal: sea, wet ground, weed.
    "T0": "12262e", "T1": "1c3a40", "T2": "2c5553", "T3": "4a7a72", "T4": "7fa89a",
    # Earth: mud, sand and rock, kept cold.
    "E0": "13141c", "E1": "1d1e27", "E2": "2a2a33", "E3": "3a3840", "E4": "4f4b50", "E5": "6e6864",
    # Wood: the boat, muted.
    "W0": "261c1d", "W1": "3d2e2c", "W2": "564339", "W3": "735b49", "W4": "958069",
    # Skin.
    "S0": "6e4a3f", "S1": "b58a6d",
    # Amber: the lantern only.
    "A0": "8a4f1d", "A1": "d48a2e", "A2": "f6c35c", "A3": "ffe9a8",
}


def rgba(name):
    h = PALETTE[name]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


ALLOWED = {rgba(name) for name in PALETTE}
