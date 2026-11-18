import math
import re
import sys


def oklch_to_hex(lightness, chroma, hue):
    a = chroma * math.cos(math.radians(hue))
    b = chroma * math.sin(math.radians(hue))
    l_ = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m_ = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s_ = (lightness - 0.0894841775 * a - 1.2914855480 * b) ** 3
    linear = (
        4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
        -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
        -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_,
    )
    if any(c < -1e-4 or c > 1 + 1e-4 for c in linear):
        raise ValueError(f"oklch({lightness} {chroma} {hue}) is outside sRGB")
    encoded = [
        12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
        for c in (min(max(c, 0.0), 1.0) for c in linear)
    ]
    return "#" + "".join(f"{round(c * 255):02X}" for c in encoded)


assert oklch_to_hex(0.62796, 0.25768, 29.2339) == "#FF0000"
assert oklch_to_hex(1.0, 0.0, 0.0) == "#FFFFFF"

pattern = re.compile(r"oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)")
sys.stdout.write(
    pattern.sub(lambda m: oklch_to_hex(*map(float, m.groups())), sys.stdin.read())
)
