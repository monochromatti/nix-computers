import json
import re
import sys

import numpy as np
from PIL import Image

WIDTH, HEIGHT = 5120, 2880


def parse_oklch(text):
    lightness, chroma, hue = map(float, re.fullmatch(r"oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)", text).groups())
    return np.array([lightness, chroma * np.cos(np.radians(hue)), chroma * np.sin(np.radians(hue))], np.float32)


def oklab_to_srgb(lab):
    l_, m_, s_ = np.moveaxis(lab, -1, 0)
    l = (l_ + 0.3963377774 * m_ + 0.2158037573 * s_) ** 3
    m = (l_ - 0.1055613458 * m_ - 0.0638541728 * s_) ** 3
    s = (l_ - 0.0894841775 * m_ - 1.2914855480 * s_) ** 3
    linear = np.stack(
        [
            4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
        ],
        -1,
    ).clip(0, 1)
    return np.where(linear <= 0.0031308, 12.92 * linear, 1.055 * linear ** (1 / 2.4) - 0.055)


def render(colors, rng):
    y, x = np.mgrid[0:HEIGHT, 0:WIDTH].astype(np.float32)
    x /= HEIGHT
    y /= HEIGHT
    lab = np.broadcast_to(parse_oklch(colors["ground"]), (HEIGHT, WIDTH, 3)).copy()
    xw = x + 0.18 * np.sin(2.1 * y + rng.uniform(0, 6.3)) + 0.07 * np.sin(5.3 * y + rng.uniform(0, 6.3))
    yw = y + 0.18 * np.sin(1.7 * x + rng.uniform(0, 6.3)) + 0.07 * np.sin(4.1 * x + rng.uniform(0, 6.3))
    washes = ["rule", "paper", "warm", "ochre", "selection", "paper", "warm", "rule", "ochre", "paper", "warm"]
    for name in washes:
        cx, cy = rng.uniform(-0.1, WIDTH / HEIGHT + 0.1), rng.uniform(-0.1, 1.1)
        rx, ry = rng.uniform(0.3, 0.8), rng.uniform(0.18, 0.5)
        angle = rng.uniform(0, np.pi)
        dx, dy = xw - cx, yw - cy
        u = (dx * np.cos(angle) + dy * np.sin(angle)) / rx
        v = (-dx * np.sin(angle) + dy * np.cos(angle)) / ry
        weight = (rng.uniform(0.6, 0.95) * np.exp(-(u * u + v * v))).astype(np.float32)[..., None]
        lab += weight * (parse_oklch(colors[name]) - lab)
    grain = rng.normal(0, 0.014, (HEIGHT, WIDTH)).astype(np.float32)
    coarse = rng.normal(0, 0.008, (HEIGHT // 2, WIDTH // 2)).astype(np.float32).repeat(2, 0).repeat(2, 1)
    lab[..., 0] += grain + coarse
    return Image.fromarray((oklab_to_srgb(lab) * 255 + 0.5).astype(np.uint8))


assert np.allclose(oklab_to_srgb(np.array([1.0, 0.0, 0.0])), 1.0, atol=1e-3)

palette = json.load(open(sys.argv[1]))
for mode, colors in palette.items():
    render(colors, np.random.default_rng(11)).save(f"{sys.argv[2]}/paper-{mode}.jpg", quality=92)
