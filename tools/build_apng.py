"""Assemble same-sized PNG frames into an animated PNG without dependencies."""

from __future__ import annotations

import argparse
import binascii
import struct
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def chunks(payload: bytes):
    position = len(PNG_SIGNATURE)
    while position + 12 <= len(payload):
        length = struct.unpack(">I", payload[position : position + 4])[0]
        kind = payload[position + 4 : position + 8]
        data = payload[position + 8 : position + 8 + length]
        yield kind, data
        position += 12 + length


def make_chunk(kind: bytes, data: bytes) -> bytes:
    crc = binascii.crc32(kind)
    crc = binascii.crc32(data, crc) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)


def assemble(frame_paths: list[Path], output: Path, fps: int) -> None:
    frames = [path.read_bytes() for path in frame_paths]
    if not frames or any(not frame.startswith(PNG_SIGNATURE) for frame in frames):
        raise ValueError("Every input must be a PNG frame.")
    parsed = [list(chunks(frame)) for frame in frames]
    ihdr = next(data for kind, data in parsed[0] if kind == b"IHDR")
    width, height = struct.unpack(">II", ihdr[:8])
    for frame_chunks in parsed[1:]:
        frame_ihdr = next(data for kind, data in frame_chunks if kind == b"IHDR")
        if frame_ihdr[:8] != ihdr[:8]:
            raise ValueError("All frames must have the same dimensions.")
    global_chunks = [
        (kind, data)
        for kind, data in parsed[0]
        if kind not in {b"IHDR", b"IDAT", b"IEND", b"acTL", b"fcTL", b"fdAT"}
    ]
    result = bytearray(PNG_SIGNATURE)
    result.extend(make_chunk(b"IHDR", ihdr))
    result.extend(make_chunk(b"acTL", struct.pack(">II", len(frames), 0)))
    for kind, data in global_chunks:
        result.extend(make_chunk(kind, data))
    sequence = 0
    for frame_index, frame_chunks in enumerate(parsed):
        frame_control = struct.pack(
            ">IIIIIHHBB",
            sequence,
            width,
            height,
            0,
            0,
            1,
            fps,
            0,
            0,
        )
        result.extend(make_chunk(b"fcTL", frame_control))
        sequence += 1
        for kind, data in frame_chunks:
            if kind != b"IDAT":
                continue
            if frame_index == 0:
                result.extend(make_chunk(b"IDAT", data))
            else:
                result.extend(make_chunk(b"fdAT", struct.pack(">I", sequence) + data))
                sequence += 1
    result.extend(make_chunk(b"IEND", b""))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(result)
    print(f"Built {output} from {len(frames)} frames at {width}x{height}, {fps} fps")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("frame_dir", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fps", type=int, default=8)
    args = parser.parse_args()
    frame_paths = sorted(args.frame_dir.glob("frame_*.png"))
    assemble(frame_paths, args.output, args.fps)


if __name__ == "__main__":
    main()
