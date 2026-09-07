"""Trim and validate MASTER-03R chroma-key outputs without changing aspect ratio.

The creative image operation happens through the approved image workflow.  This
script only removes empty alpha margins, adds a small safe pad, and emits metrics
used by the Godot scale/pivot validator.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPRITE_DIR = ROOT / "assets" / "art" / "green_coast_2d5d_v01" / "sprites"


def prepare(path: Path) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    source_size = image.size
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError(f"Sprite is fully transparent: {path}")
    cropped = image.crop(bounds)
    pad = max(8, round(max(cropped.size) * 0.015))
    final = Image.new("RGBA", (cropped.width + pad * 2, cropped.height + pad * 2))
    final.alpha_composite(cropped, (pad, pad))
    final.save(path)

    alpha_final = final.getchannel("A")
    corners = [alpha_final.getpixel((0, 0)), alpha_final.getpixel((final.width - 1, 0)),
               alpha_final.getpixel((0, final.height - 1)), alpha_final.getpixel((final.width - 1, final.height - 1))]
    pixels = list(final.getdata())
    opaque = sum(1 for pixel in pixels if pixel[3] >= 240)
    magenta_fringe = sum(1 for red, green, blue, value in pixels if value > 16 and red > 220 and blue > 220 and green < 80)
    source_ratio = source_size[0] / source_size[1]
    content_ratio = cropped.width / cropped.height
    return {
        "file": path.name,
        "source_size": source_size,
        "trimmed_size": final.size,
        "content_ratio": round(content_ratio, 4),
        "source_canvas_ratio": round(source_ratio, 4),
        "transparent_corners": corners == [0, 0, 0, 0],
        "opaque_coverage": round(opaque / len(pixels), 4),
        "magenta_fringe_pixels": magenta_fringe,
    }


def main() -> None:
    paths = sorted(SPRITE_DIR.glob("*.png"))
    if not paths:
        raise RuntimeError(f"No sprites found in {SPRITE_DIR}")
    print(json.dumps([prepare(path) for path in paths], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
