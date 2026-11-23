import re
import sys

from coloraide import Color


def oklch_to_hex(lightness, chroma, hue):
    if not 0 <= lightness <= 1:
        raise ValueError(f"oklch({lightness} {chroma} {hue}) has invalid lightness")
    color = Color("oklch", [lightness, chroma, hue]).convert("srgb").fit(method="oklch-chroma")
    return color.to_string(hex=True, upper=True)


assert oklch_to_hex(0.62796, 0.25768, 29.2339) == "#FF0000"
assert oklch_to_hex(1.0, 0.0, 0.0) == "#FFFFFF"
assert oklch_to_hex(0.62, 0.5, 86) == oklch_to_hex(0.62, 0.3, 86)

pattern = re.compile(r"oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)")
sys.stdout.write(
    pattern.sub(lambda m: oklch_to_hex(*map(float, m.groups())), sys.stdin.read())
)
