from __future__ import annotations

import math
import random
import wave
from pathlib import Path


RATE = 22050
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "settlement" / "audio"


def envelope(t: float, duration: float, attack: float = 0.02, release: float = 0.18) -> float:
    return min(1.0, t / max(attack, 0.001)) * min(1.0, (duration - t) / max(release, 0.001))


def tone(duration: float, frequency: float, volume: float = 0.5, end_frequency: float | None = None, noise: float = 0.0, seed: int = 1) -> list[float]:
    rng = random.Random(seed)
    count = int(duration * RATE)
    samples: list[float] = []
    phase = 0.0
    for index in range(count):
        t = index / RATE
        progress = t / duration
        frequency_now = frequency if end_frequency is None else frequency + (end_frequency - frequency) * progress
        phase += math.tau * frequency_now / RATE
        body = math.sin(phase) + 0.28 * math.sin(phase * 2.01)
        body += (rng.random() * 2.0 - 1.0) * noise
        samples.append(body * volume * envelope(t, duration))
    return samples


def silence(duration: float) -> list[float]:
    return [0.0] * int(duration * RATE)


def mix(duration: float, parts: list[tuple[float, list[float]]]) -> list[float]:
    result = silence(duration)
    for offset, samples in parts:
        start = int(offset * RATE)
        for index, value in enumerate(samples):
            if start + index >= len(result):
                break
            result[start + index] += value
    peak = max(1.0, max(abs(value) for value in result) * 1.05)
    return [value / peak for value in result]


def write(name: str, samples: list[float]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        frames = bytearray()
        for value in samples:
            integer = max(-32767, min(32767, int(value * 32767)))
            frames.extend(integer.to_bytes(2, "little", signed=True))
        target.writeframes(frames)


def make_ambience() -> list[float]:
    rng = random.Random(92)
    duration = 12.0
    samples = silence(duration)
    for index in range(len(samples)):
        t = index / RATE
        breeze = (rng.random() * 2.0 - 1.0) * (0.025 + 0.012 * math.sin(t * 0.4))
        samples[index] = breeze
    birds = [
        (1.2, 1320.0), (1.35, 1640.0), (4.8, 1100.0), (5.0, 1450.0),
        (8.4, 1250.0), (8.56, 1580.0), (10.6, 980.0),
    ]
    return mix(duration, [(0.0, samples)] + [(at, tone(0.18, hz, 0.11, hz * 1.32, seed=int(at * 100))) for at, hz in birds])


def make_music() -> list[float]:
    """Original pastoral tracker-style loop; no melody is derived from an existing work."""
    duration = 24.0
    beat = 0.5
    # A simple original D-dorian village theme, voiced as soft plucks and drone.
    melody = [293.66, 349.23, 392.00, 440.00, 392.00, 349.23, 329.63, 293.66,
              261.63, 293.66, 349.23, 329.63, 293.66, 261.63, 220.00, 261.63]
    bass = [146.83, 130.81, 110.00, 130.81]
    parts: list[tuple[float, list[float]]] = []
    for bar in range(3):
        bar_start = bar * 8.0
        for note_index, frequency in enumerate(melody):
            parts.append((bar_start + note_index * beat, tone(0.42, frequency, 0.105, frequency * 0.997, seed=100 + bar * 20 + note_index)))
        for bass_index, frequency in enumerate(bass):
            parts.append((bar_start + bass_index * 2.0, tone(1.72, frequency, 0.075, frequency * 0.995, seed=200 + bar * 8 + bass_index)))
        for pulse in range(16):
            at = bar_start + pulse * beat
            parts.append((at, tone(0.055, 88 if pulse % 4 == 0 else 132, 0.025, 55, 0.18, 300 + pulse)))
    return mix(duration, parts)


def main() -> None:
    write("road.wav", mix(0.30, [(0.00, tone(0.18, 135, 0.38, 82, 0.22, 2)), (0.10, tone(0.16, 190, 0.22, 110, 0.15, 3))]))
    write("build_start.wav", mix(0.45, [(0.00, tone(0.14, 220, 0.34, 125, 0.12, 4)), (0.18, tone(0.16, 245, 0.30, 135, 0.10, 5))]))
    write("build_complete.wav", mix(0.90, [(0.00, tone(0.50, 523.25, 0.26, seed=6)), (0.17, tone(0.56, 659.25, 0.25, seed=7)), (0.34, tone(0.56, 783.99, 0.23, seed=8))]))
    write("delivery.wav", mix(0.38, [(0.00, tone(0.12, 165, 0.28, 105, 0.1, 9)), (0.16, tone(0.16, 230, 0.20, 150, 0.08, 10))]))
    write("tower.wav", mix(0.34, [(0.00, tone(0.24, 720, 0.25, 220, 0.12, 11)), (0.20, tone(0.10, 105, 0.22, 70, 0.25, 12))]))
    write("night.wav", mix(1.70, [(0.00, tone(1.20, 196, 0.26, 147, seed=13)), (0.34, tone(1.18, 246.94, 0.22, 185, seed=14))]))
    write("enemy.wav", mix(0.90, [(0.00, tone(0.70, 92, 0.33, 58, 0.42, 15)), (0.18, tone(0.60, 73, 0.26, 48, 0.35, 16))]))
    write("soldier.wav", mix(0.90, [(0.00, tone(0.50, 392, 0.24, seed=17)), (0.20, tone(0.56, 523.25, 0.24, seed=18)), (0.38, tone(0.48, 659.25, 0.20, seed=19))]))
    write("attack.wav", mix(0.34, [(0.00, tone(0.13, 310, 0.30, 115, 0.18, 20)), (0.11, tone(0.20, 105, 0.32, 62, 0.32, 21))]))
    write("destroyed.wav", mix(1.85, [
        (0.00, tone(0.65, 145, 0.34, 58, 0.55, 22)),
        (0.20, tone(1.20, 330, 0.15, 205, 0.22, 23)),
        (0.36, tone(1.05, 277, 0.14, 175, 0.25, 24)),
        (0.52, tone(0.95, 220, 0.13, 145, 0.28, 25)),
    ]))
    write("ambience.wav", make_ambience())
    write("music.wav", make_music())


if __name__ == "__main__":
    main()
