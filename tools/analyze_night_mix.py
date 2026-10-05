#!/usr/bin/env python3
"""Render a 60 s night-mix RMS envelope: old periodic scream vs the fix.

Does not play audio through Godot. Mixes the same stems the director uses at
the published night dB targets, then overlays night_scream.wav on the old
10 s cycle. Writes a PNG next to the docs so the PR can cite the evidence.
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "settlement" / "audio" / "presentation"
OUT = Path(__file__).resolve().parents[1] / "docs" / "art" / "night_mix_before_after.png"
SECONDS = 60.0
HOP = 512


def read_wav(path: Path) -> tuple[int, list[float]]:
    with wave.open(str(path), "rb") as handle:
        rate = handle.getframerate()
        width = handle.getsampwidth()
        channels = handle.getnchannels()
        raw = handle.readframes(handle.getnframes())
    if width == 2:
        count = len(raw) // 2
        samples = list(struct.unpack("<" + "h" * count, raw))
        data = [s / 32768.0 for s in samples]
    else:
        raise SystemExit(f"unsupported width {width} in {path}")
    if channels == 2:
        data = [(data[i] + data[i + 1]) * 0.5 for i in range(0, len(data), 2)]
    return rate, data


def loop_to(data: list[float], frames: int) -> list[float]:
    if not data:
        return [0.0] * frames
    out = [0.0] * frames
    n = len(data)
    for i in range(frames):
        out[i] = data[i % n]
    return out


def db_gain(db: float) -> float:
    return 10.0 ** (db / 20.0)


def rms_envelope(data: list[float], hop: int) -> list[float]:
    out: list[float] = []
    for i in range(0, len(data), hop):
        chunk = data[i : i + hop]
        if not chunk:
            continue
        acc = sum(s * s for s in chunk) / float(len(chunk))
        out.append(math.sqrt(acc))
    return out


def mix_night(rate: int, frames: int, with_periodic_scream: bool) -> list[float]:
    night = loop_to(read_wav(AUDIO / "score_night_percussion.wav")[1], frames)
    dusk = loop_to(read_wav(AUDIO / "score_dusk_tension.wav")[1], frames)
    ambience = loop_to(read_wav(AUDIO / "ambient_world.wav")[1], frames)
    wyrd = loop_to(read_wav(AUDIO / "wyrd_drone.wav")[1], frames)
    lumen = loop_to(read_wav(AUDIO / "lumen_hum.wav")[1], frames)
    scream_rate, scream = read_wav(AUDIO / "night_scream.wav")
    if scream_rate != rate:
        # All presentation stems are 22050; scream is too. Keep a cheap resample
        # so a future import change does not crash the evidence plot.
        scream = [scream[min(len(scream) - 1, int(i * scream_rate / rate))] for i in range(int(len(scream) * rate / scream_rate))]

    out = [0.0] * frames
    night_g = db_gain(-9.0)
    dusk_g = db_gain(-22.0) if with_periodic_scream else 0.0
    amb_g = db_gain(-28.0)
    wyrd_g = db_gain(-16.0)
    lumen_g = db_gain(-18.0)
    scream_g = db_gain(-6.0)
    for i in range(frames):
        out[i] = (
            night[i] * night_g
            + dusk[i] * dusk_g
            + ambience[i] * amb_g
            + wyrd[i] * wyrd_g
            + lumen[i] * lumen_g
        )
    if with_periodic_scream:
        period = int(10.0 * rate)
        for start in range(int(3.2 * rate), frames, period):
            for j, sample in enumerate(scream):
                if start + j >= frames:
                    break
                out[start + j] += sample * scream_g
    elif scream:
        # One scare ~4 s in, matching the remaining one-shot.
        start = int(4.0 * rate)
        for j, sample in enumerate(scream):
            if start + j >= frames:
                break
            out[start + j] += sample * scream_g * 0.85
    return out


def draw_plot(before: list[float], after: list[float], rate: int, hop: int, dest: Path) -> None:
    width, height = 1100, 520
    img = Image.new("RGB", (width, height), (18, 16, 14))
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    margin = 56
    pane_h = (height - margin * 2 - 24) // 2
    peak = max(0.0001, max(before + after))

    def pane(values: list[float], top: int, title: str, accent: tuple[int, int, int]) -> None:
        draw.rectangle([margin, top, width - 24, top + pane_h], outline=(60, 52, 44), fill=(28, 24, 20))
        draw.text((margin + 8, top + 6), title, fill=accent, font=font)
        if len(values) < 2:
            return
        pts = []
        for index, value in enumerate(values):
            x = margin + 8 + int((width - margin - 40) * index / (len(values) - 1))
            y = top + pane_h - 12 - int((pane_h - 28) * (value / peak))
            pts.append((x, y))
        draw.line(pts, fill=accent, width=2)
        for second in range(0, int(SECONDS) + 1, 10):
            x = margin + 8 + int((width - margin - 40) * second / SECONDS)
            draw.line([(x, top + pane_h - 8), (x, top + pane_h - 4)], fill=(90, 80, 70), width=1)
            draw.text((x - 6, top + pane_h - 2), f"{second}s", fill=(120, 110, 96), font=font)

    pane(before, margin, "BEFORE — night bed + dusk underlay + scream every 10 s (820→460 Hz sweep)", (220, 96, 72))
    pane(after, margin + pane_h + 24, "AFTER — night bed + one scare, dusk muted, no periodic sweep", (120, 196, 140))
    draw.text(
        (margin, 12),
        "60 s night mix RMS  |  stems at director dB  |  one_shard_audio.json untouched",
        fill=(220, 210, 190),
        font=font,
    )
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest)
    print(f"NIGHT_MIX_PLOT {dest} peak_before={max(before):.4f} peak_after={max(after):.4f}")


def main() -> None:
    rate, _ = read_wav(AUDIO / "score_night_percussion.wav")
    frames = int(SECONDS * rate)
    before = rms_envelope(mix_night(rate, frames, True), HOP)
    after = rms_envelope(mix_night(rate, frames, False), HOP)
    draw_plot(before, after, rate, HOP, OUT)
    # Also copy into the cloud-agent artifact folder when present.
    artifact = Path("/opt/cursor/artifacts/night_mix_before_after.png")
    if artifact.parent.exists():
        artifact.write_bytes(OUT.read_bytes())
        print(f"NIGHT_MIX_PLOT {artifact}")


if __name__ == "__main__":
    main()
