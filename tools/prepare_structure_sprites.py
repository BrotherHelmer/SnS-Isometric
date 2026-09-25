from pathlib import Path

from PIL import Image


def prepare(source: Path, destination: Path, canvas_size: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGBA")
    bounds = image.getchannel("A").point(lambda value: 255 if value >= 96 else 0).getbbox()
    if bounds is None:
        raise RuntimeError(f"No visible sprite found in {source}")
    image = image.crop(bounds)

    available = (canvas_size[0] - 4, canvas_size[1] - 2)
    scale = min(available[0] / image.width, available[1] / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    image = image.resize(size, Image.Resampling.NEAREST)

    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 0 if alpha < 96 else 255)

    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    canvas.alpha_composite(image, ((canvas_size[0] - image.width) // 2, canvas_size[1] - image.height))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    sources = root / "tools/art_sources"
    prepare(sources / "barracks_raw.png", root / "assets/settlement/buildings/barracks.png", (150, 126))
    prepare(sources / "storehouse_raw.png", root / "assets/settlement/buildings/storehouse.png", (136, 112))
    prepare(sources / "enemy_camp_raw.png", root / "assets/settlement/threats/enemy_camp.png", (142, 112))
