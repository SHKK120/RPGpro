"""Extract the five texture swatches embedded in the Green Coast terrain sheet.

The source sheet is project-owned reference material. Each crop is square and is
mirrored into a 2x2 tile, so no subject is stretched and opposite tile edges match.
"""

from pathlib import Path

from PIL import Image, ImageOps


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "art" / "reference" / "Terrain Kit 2.jpeg"
OUTPUT = PROJECT / "assets" / "art" / "green_coast_2d5d_v01" / "surface_samples"

# Inner 56 px squares avoid the white frame and labels around the visible swatches.
CROPS = {
    "grass.png": (918, 17, 974, 73),
    "soil_path.png": (1018, 17, 1074, 73),
    "rock_cliff.png": (1120, 17, 1176, 73),
    "sand.png": (1225, 17, 1281, 73),
    "shallow_water.png": (1341, 17, 1397, 73),
}


def mirrored_tile(sample: Image.Image) -> Image.Image:
    width, height = sample.size
    tile = Image.new("RGB", (width * 2, height * 2))
    tile.paste(sample, (0, 0))
    tile.paste(ImageOps.mirror(sample), (width, 0))
    tile.paste(ImageOps.flip(sample), (0, height))
    tile.paste(ImageOps.flip(ImageOps.mirror(sample)), (width, height))
    return tile.resize((256, 256), Image.Resampling.LANCZOS)


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    base_size = (1456, 1092)
    scale_x = source.width / base_size[0]
    scale_y = source.height / base_size[1]
    if not (0.95 <= scale_x <= 1.05 and 0.95 <= scale_y <= 1.05):
        raise RuntimeError(f"Unexpected source dimensions: {source.size}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for filename, crop_box in CROPS.items():
        scaled_box = tuple(
            round(value * (scale_x if index % 2 == 0 else scale_y))
            for index, value in enumerate(crop_box)
        )
        sample = source.crop(scaled_box)
        mirrored_tile(sample).save(OUTPUT / filename, optimize=True)
        print(f"{filename}: crop={scaled_box} source={sample.size} output=256x256")


if __name__ == "__main__":
    main()
