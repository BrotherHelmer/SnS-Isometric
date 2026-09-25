"""Render the original Shard & Sovereign adaptive score and ambience.

The renderer intentionally uses only mathematical oscillators and deterministic
noise.  No third-party recordings, samples, melodies, or generative services
are used.  Run with the repository's Python interpreter.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "settlement" / "audio" / "presentation"
SAMPLE_RATE = 22_050
BPM = 90.0
BEAT = 60.0 / BPM
BARS = 8
DURATION = BARS * 4 * BEAT
SAMPLES = int(round(DURATION * SAMPLE_RATE))
RNG = random.Random(0x5A17D)


def midi(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def empty() -> list[float]:
    return [0.0] * SAMPLES


def add_tone(
    target: list[float],
    start: float,
    duration: float,
    frequency: float,
    amplitude: float,
    voice: str,
) -> None:
    first = max(0, int(start * SAMPLE_RATE))
    last = min(SAMPLES, int((start + duration) * SAMPLE_RATE))
    for index in range(first, last):
        local = (index - first) / SAMPLE_RATE
        phase = math.tau * frequency * local
        attack = min(1.0, local / 0.025)
        release = min(1.0, max(0.0, (duration - local) / 0.12))
        if voice == "pluck":
            envelope = attack * math.exp(-3.8 * local / max(duration, 0.05))
            sample = math.sin(phase) + 0.32 * math.sin(phase * 2.0) + 0.12 * math.sin(phase * 3.0)
        elif voice == "flute":
            envelope = attack * release * (0.86 + 0.14 * math.sin(math.tau * 4.7 * local))
            sample = math.sin(phase + 0.018 * math.sin(math.tau * 5.1 * local)) + 0.12 * math.sin(phase * 2.0)
        elif voice == "strings":
            envelope = min(1.0, local / 0.16) * min(1.0, max(0.0, (duration - local) / 0.28))
            sample = math.sin(phase) + 0.22 * math.sin(phase * 2.01) + 0.1 * math.sin(phase * 3.99)
        elif voice == "drone":
            envelope = min(1.0, local / 0.35) * min(1.0, max(0.0, (duration - local) / 0.45))
            sample = math.sin(phase) + 0.25 * math.sin(phase * 0.5)
        elif voice == "metal":
            envelope = attack * release
            raw = math.sin(phase) + 0.7 * math.sin(phase * 2.0) + 0.32 * math.sin(phase * 3.0)
            sample = math.tanh(raw * 2.6)
        else:
            envelope = attack * release
            sample = math.sin(phase)
        target[index] += sample * amplitude * envelope


def add_noise_hit(
    target: list[float], start: float, duration: float, amplitude: float, low: bool = False
) -> None:
    first = max(0, int(start * SAMPLE_RATE))
    last = min(SAMPLES, int((start + duration) * SAMPLE_RATE))
    filtered = 0.0
    for index in range(first, last):
        local = (index - first) / SAMPLE_RATE
        envelope = math.exp(-7.0 * local / max(duration, 0.02))
        noise = RNG.uniform(-1.0, 1.0)
        filtered = filtered * (0.94 if low else 0.58) + noise * (0.06 if low else 0.42)
        thump = math.sin(math.tau * (58.0 - 24.0 * local / max(duration, 0.02)) * local) if low else 0.0
        target[index] += (filtered + thump * 0.85) * amplitude * envelope


def motif_notes() -> list[int]:
    # Original D-Dorian contour: D-F-A-G | E-D-C-A.  It deliberately avoids
    # quoting or interpolating any existing game score.
    return [62, 65, 69, 67, 64, 62, 60, 57]


def render_foundation() -> list[float]:
    track = empty()
    chords = [(50, 57, 62), (48, 55, 60), (53, 60, 65), (50, 57, 62)]
    bass = [38, 38, 36, 38, 41, 36, 38, 38]
    for bar in range(BARS):
        chord = chords[bar % len(chords)]
        start = bar * 4 * BEAT
        add_tone(track, start, BEAT * 1.6, midi(bass[bar % len(bass)]), 0.16, "pluck")
        add_tone(track, start + 2 * BEAT, BEAT * 1.4, midi(bass[bar % len(bass)] + (7 if bar % 2 == 0 else 5)), 0.11, "pluck")
        for beat_index in range(4):
            note = chord[beat_index % len(chord)]
            add_tone(track, start + beat_index * BEAT, BEAT * 0.72, midi(note + 12), 0.19, "pluck")
            if beat_index % 2 == 1:
                add_tone(
                    track,
                    start + beat_index * BEAT + BEAT * 0.5,
                    BEAT * 0.22,
                    midi(note + 19),
                    0.07,
                    "pluck",
                )
        for note in chord:
            add_tone(track, start, 4 * BEAT, midi(note), 0.048, "strings")
        add_noise_hit(track, start, 0.09, 0.04, False)
        add_noise_hit(track, start + 2 * BEAT, 0.07, 0.03, False)
    for phrase in range(2):
        for index, note in enumerate(motif_notes()):
            add_tone(track, phrase * 16 * BEAT + index * 2 * BEAT, 1.15 * BEAT, midi(note + 12), 0.15, "flute")
    return track


def render_activity() -> list[float]:
    track = empty()
    bounce = [74, 76, 81, 76, 74, 69, 72, 67]
    for bar in range(BARS):
        start = bar * 4 * BEAT
        for eighth in range(8):
            pitch = bounce[(bar + eighth) % len(bounce)]
            add_tone(track, start + eighth * BEAT * 0.5, BEAT * 0.24, midi(pitch), 0.09, "pluck")
        add_noise_hit(track, start, 0.12, 0.06, True)
        add_noise_hit(track, start + BEAT, 0.05, 0.03, False)
        add_noise_hit(track, start + 2 * BEAT, 0.11, 0.05, True)
        add_noise_hit(track, start + 3 * BEAT, 0.04, 0.025, False)
    return track


def render_dusk() -> list[float]:
    track = empty()
    for bar in range(BARS):
        start = bar * 4 * BEAT
        root = 38 if bar % 4 in (0, 3) else 36
        add_tone(track, start, 4 * BEAT, midi(root), 0.13, "drone")
        add_tone(track, start, 4 * BEAT, midi(root + 7), 0.045, "strings")
        if bar % 2 == 1:
            add_noise_hit(track, start + 3.5 * BEAT, 0.28, 0.055, True)
    return track


def render_night_percussion() -> list[float]:
    track = empty()
    for bar in range(BARS):
        start = bar * 4 * BEAT
        add_tone(track, start, 4 * BEAT, midi(33), 0.09, "drone")
        add_tone(track, start, 4 * BEAT, midi(40), 0.035, "strings")
        add_noise_hit(track, start, 0.32, 0.18, True)
        add_noise_hit(track, start + 2.5 * BEAT, 0.22, 0.11, True)
        if bar % 2 == 1:
            add_noise_hit(track, start + 3.25 * BEAT, 0.16, 0.07, False)
            add_tone(track, start + 3.0 * BEAT, 0.8 * BEAT, midi(45), 0.04, "flute")
    return track


def render_metal() -> list[float]:
    track = empty()
    dark_motif = [38, 41, 45, 43, 40, 38, 36, 33]
    for bar in range(BARS):
        start = bar * 4 * BEAT
        for eighth in range(8):
            note = dark_motif[(bar * 2 + eighth // 2) % len(dark_motif)]
            add_tone(track, start + eighth * BEAT * 0.5, BEAT * 0.43, midi(note), 0.16, "metal")
            add_tone(track, start + eighth * BEAT * 0.5, BEAT * 0.43, midi(note + 7), 0.07, "metal")
    return track


def normalize(samples: list[float], ceiling: float = 0.82) -> list[float]:
    peak = max(0.0001, max(abs(value) for value in samples))
    scale = min(1.0, ceiling / peak)
    return [max(-1.0, min(1.0, value * scale)) for value in samples]


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        payload = bytearray()
        for value in normalize(samples):
            payload.extend(struct.pack("<h", int(round(value * 32767.0))))
        output.writeframes(payload)


def write_short_effect(path: Path, seconds: float, maker) -> None:
    count = int(seconds * SAMPLE_RATE)
    data = [0.0] * count
    maker(data)
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(0.0001, max(abs(value) for value in data))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(
            b"".join(struct.pack("<h", int(max(-1.0, min(1.0, value * 0.78 / peak)) * 32767)) for value in data)
        )


def render_ambience() -> None:
    def wind(data: list[float]) -> None:
        filtered = 0.0
        for i in range(len(data)):
            filtered = filtered * 0.992 + RNG.uniform(-1, 1) * 0.008
            data[i] = filtered * (0.45 + 0.15 * math.sin(math.tau * i / SAMPLE_RATE / 4.0))
            if i % int(SAMPLE_RATE * 2.7) < 1100:
                local = (i % int(SAMPLE_RATE * 2.7)) / SAMPLE_RATE
                data[i] += math.sin(math.tau * (1450 + 280 * math.sin(local * 7)) * local) * math.exp(-5 * local) * 0.12

    def chop(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            data[i] = (math.sin(math.tau * 118 * t) + RNG.uniform(-0.5, 0.5)) * math.exp(-17 * t)

    def hammer(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            data[i] = (math.sin(math.tau * 710 * t) + 0.5 * math.sin(math.tau * 1040 * t)) * math.exp(-22 * t)

    def footstep(data: list[float]) -> None:
        filtered = 0.0
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            filtered = filtered * 0.72 + RNG.uniform(-1, 1) * 0.28
            data[i] = (filtered + math.sin(math.tau * 82 * t)) * math.exp(-26 * t)

    def lumen(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            envelope = min(1.0, t / 0.2) * min(1.0, (len(data) / SAMPLE_RATE - t) / 0.3)
            data[i] = (math.sin(math.tau * 94 * t) + 0.24 * math.sin(math.tau * 188.7 * t)) * envelope

    def wyrd_drone(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            envelope = min(1.0, t / 0.4) * min(1.0, (len(data) / SAMPLE_RATE - t) / 0.5)
            pulse = 0.82 + 0.18 * math.sin(math.tau * 0.37 * t)
            crystal = math.sin(math.tau * 174 * t + 0.4 * math.sin(math.tau * 3.1 * t))
            low = math.sin(math.tau * 55 * t) + 0.35 * math.sin(math.tau * 82.5 * t)
            air = math.sin(math.tau * 410 * t) * 0.08 * math.sin(math.tau * 0.7 * t)
            data[i] = (low * 0.62 + crystal * 0.22 + air) * envelope * pulse

    def ui_click(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            data[i] = (math.sin(math.tau * 920 * t) + 0.35 * math.sin(math.tau * 1840 * t)) * math.exp(-28 * t)

    def nightfall_sting(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            horn = math.sin(math.tau * 196 * t) + 0.4 * math.sin(math.tau * 147 * t)
            data[i] = horn * min(1.0, t / 0.05) * math.exp(-1.6 * t)

    def dawn_release(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            env = min(1.0, t / 0.12) * min(1.0, (len(data) / SAMPLE_RATE - t) / 0.4)
            data[i] = (
                math.sin(math.tau * 262 * t) * 0.55
                + math.sin(math.tau * 330 * t) * 0.28
                + math.sin(math.tau * 392 * t) * 0.18
            ) * env

    def victory_motif(data: list[float]) -> None:
        notes = [262.0, 330.0, 392.0, 523.0]
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            index = min(3, int(t / 0.32))
            local = t - index * 0.32
            env = min(1.0, local / 0.04) * math.exp(-2.4 * local)
            data[i] = math.sin(math.tau * notes[index] * t) * env

    def defeat_motif(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            env = min(1.0, t / 0.08) * min(1.0, (len(data) / SAMPLE_RATE - t) / 0.35)
            data[i] = (math.sin(math.tau * 196 * t) + 0.4 * math.sin(math.tau * 147 * t)) * env

    def reckoning_pulse(data: list[float]) -> None:
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            env = min(1.0, t / 0.2) * min(1.0, (len(data) / SAMPLE_RATE - t) / 0.35)
            pulse = 0.5 + 0.5 * math.sin(math.tau * 1.6 * t)
            data[i] = (
                math.sin(math.tau * 73 * t)
                + 0.28 * math.sin(math.tau * 219 * t + 0.6 * math.sin(math.tau * 5 * t))
            ) * env * pulse

    def night_scream(data: list[float]) -> None:
        filtered = 0.0
        for i in range(len(data)):
            t = i / SAMPLE_RATE
            rise = min(1.0, t / 0.045)
            fall = math.exp(-1.15 * t)
            glide = 820.0 - 360.0 * min(1.0, t / 0.95)
            vibrato = 1.0 + 0.04 * math.sin(math.tau * 6.4 * t)
            formant = math.sin(math.tau * glide * vibrato * t) + 0.42 * math.sin(
                math.tau * (glide * 1.82) * t
            )
            noise = RNG.uniform(-1.0, 1.0)
            filtered = filtered * 0.84 + noise * 0.16
            data[i] = (formant * 0.7 + filtered * 0.4) * rise * fall

    write_short_effect(OUTPUT / "settlement_wind_birds.wav", 8.0, wind)
    write_short_effect(OUTPUT / "work_chop.wav", 0.42, chop)
    write_short_effect(OUTPUT / "work_hammer.wav", 0.32, hammer)
    write_short_effect(OUTPUT / "footstep.wav", 0.18, footstep)
    write_short_effect(OUTPUT / "lumen_hum.wav", 3.0, lumen)
    write_short_effect(OUTPUT / "wyrd_drone.wav", 6.0, wyrd_drone)
    write_short_effect(OUTPUT / "ui_click.wav", 0.16, ui_click)
    write_short_effect(OUTPUT / "nightfall_sting.wav", 1.6, nightfall_sting)
    write_short_effect(OUTPUT / "dawn_release.wav", 2.4, dawn_release)
    write_short_effect(OUTPUT / "victory_motif.wav", 1.6, victory_motif)
    write_short_effect(OUTPUT / "defeat_motif.wav", 1.8, defeat_motif)
    write_short_effect(OUTPUT / "reckoning_pulse.wav", 3.2, reckoning_pulse)
    write_short_effect(OUTPUT / "night_scream.wav", 1.45, night_scream)


def main() -> None:
    stems = {
        "score_pastoral_foundation.wav": render_foundation(),
        "score_settlement_activity.wav": render_activity(),
        "score_dusk_tension.wav": render_dusk(),
        "score_night_percussion.wav": render_night_percussion(),
        "score_metal_combat.wav": render_metal(),
    }
    for filename, samples in stems.items():
        write_wav(OUTPUT / filename, samples)
    transition = empty()
    pastoral = stems["score_pastoral_foundation.wav"]
    activity = stems["score_settlement_activity.wav"]
    dusk = stems["score_dusk_tension.wav"]
    night = stems["score_night_percussion.wav"]
    metal = stems["score_metal_combat.wav"]
    for index in range(SAMPLES):
        seconds = index / SAMPLE_RATE
        dusk_weight = max(0.0, min(1.0, (seconds - 6.0) / 6.0))
        night_weight = max(0.0, min(1.0, (seconds - 11.0) / 5.0))
        threat_weight = max(0.0, min(1.0, (seconds - 14.0) / 5.0))
        transition[index] = (
            pastoral[index] * (0.72 - 0.34 * night_weight)
            + activity[index] * (0.34 * (1.0 - dusk_weight))
            + dusk[index] * (0.46 * dusk_weight)
            + night[index] * (0.48 * night_weight)
            + metal[index] * (0.50 * threat_weight)
        )
    transition_path = ROOT / "artifacts" / "presentation_pass" / "motion" / "music_day_to_night_transition.wav"
    write_wav(transition_path, transition)
    render_ambience()
    print(f"Rendered {len(stems)} synchronized {DURATION:.3f}s stems, transition proof, and ambience")


if __name__ == "__main__":
    main()
