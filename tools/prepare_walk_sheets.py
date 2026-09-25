from pathlib import Path

from PIL import Image


def build_sheet(source: Path, destination: Path, cell_size: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGBA")
    sheet = Image.new("RGBA", (cell_size[0] * 4, cell_size[1]), (0, 0, 0, 0))

    alpha = image.getchannel("A").point(lambda value: 255 if value >= 96 else 0)
    occupied_columns, _ = alpha.getprojection()
    groups: list[tuple[int, int]] = []
    group_start: int | None = None
    for x, occupied in enumerate(occupied_columns + [0]):
        if occupied and group_start is None:
            group_start = x
        elif not occupied and group_start is not None:
            groups.append((group_start, x))
            group_start = None
    groups = sorted(sorted(groups, key=lambda item: item[1] - item[0], reverse=True)[:4])
    if len(groups) != 4:
        raise RuntimeError(f"Expected four silhouettes in {source}, found {len(groups)}")

    for frame_index, (left, right) in enumerate(groups):
        frame = image.crop((left, 0, right, image.height))
        alpha_bounds = frame.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError(f"Frame {frame_index} in {source} is empty")
        frame = frame.crop(alpha_bounds)

        available_width = cell_size[0] - 4
        available_height = cell_size[1] - 2
        scale = min(available_width / frame.width, available_height / frame.height)
        resized_size = (
            max(1, round(frame.width * scale)),
            max(1, round(frame.height * scale)),
        )
        frame = frame.resize(resized_size, Image.Resampling.NEAREST)

        # Keep generated pixel clusters crisp after chroma-key edge cleanup.
        pixels = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                red, green, blue, alpha = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0 if alpha < 96 else 255)

        x = frame_index * cell_size[0] + (cell_size[0] - frame.width) // 2
        y = cell_size[1] - frame.height
        sheet.alpha_composite(frame, (x, y))

    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination)


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    build_sheet(
        root / "assets/settlement/settler_walk_raw_v2.png",
        root / "assets/settlement/settler_walk_v2.png",
        (28, 42),
    )
    build_sheet(
        root / "assets/settlement/threats/night_raider_walk_raw_v2.png",
        root / "assets/settlement/threats/night_raider_walk_v2.png",
        (38, 46),
    )
