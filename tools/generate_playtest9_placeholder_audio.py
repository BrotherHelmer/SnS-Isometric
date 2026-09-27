#!/usr/bin/env python3
"""
Generate minimal CC0 placeholder audio for playtest.9.
These are procedural placeholders until proper curated CC0 audio is sourced.
"""

import struct
import wave
import math

def generate_wav(filename: str, duration_seconds: float, sample_rate: int, samples: list[int]):
    """Write a mono 16-bit WAV file."""
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        # Ensure we have the right number of samples
        target_samples = int(duration_seconds * sample_rate)
        if len(samples) < target_samples:
            samples.extend([0] * (target_samples - len(samples)))
        elif len(samples) > target_samples:
            samples = samples[:target_samples]
        # Convert to bytes
        wav_file.writeframes(b''.join(struct.pack('<h', s) for s in samples))

def envelope_adsr(sample_count: int, attack: float, decay: float, sustain_level: float, release: float) -> list[float]:
    """Generate ADSR envelope coefficients."""
    attack_samples = int(attack * sample_count)
    decay_samples = int(decay * sample_count)
    release_samples = int(release * sample_count)
    sustain_samples = sample_count - attack_samples - decay_samples - release_samples
    
    envelope = []
    # Attack
    for i in range(attack_samples):
        envelope.append(i / attack_samples if attack_samples > 0 else 1.0)
    # Decay
    for i in range(decay_samples):
        envelope.append(1.0 - (1.0 - sustain_level) * (i / decay_samples) if decay_samples > 0 else sustain_level)
    # Sustain
    for i in range(sustain_samples):
        envelope.append(sustain_level)
    # Release
    for i in range(release_samples):
        envelope.append(sustain_level * (1.0 - i / release_samples) if release_samples > 0 else 0.0)
    
    return envelope

def generate_farm_animal_placeholder():
    """Generate a simple sheep-like bleat (placeholder until real CC0 sheep sound)."""
    sample_rate = 44100
    duration = 0.9
    num_samples = int(duration * sample_rate)
    
    samples = []
    # Two-tone bleat: 350Hz -> 280Hz with vibrato
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency sweep from 350 to 280 Hz
        freq = 350 - (70 * t / duration)
        # Add vibrato (15Hz modulation at 6Hz rate)
        vibrato = 15 * math.sin(2 * math.pi * 6 * t)
        actual_freq = freq + vibrato
        # Generate tone
        amplitude = 0.35
        sample = amplitude * math.sin(2 * math.pi * actual_freq * t)
        # Add noise texture for "breath" character
        noise = (hash(i) % 2000 - 1000) / 10000.0 * 0.12
        sample += noise
        samples.append(sample)
    
    # Apply envelope: quick attack, sustained bleat, quick release
    envelope = envelope_adsr(num_samples, 0.02, 0.05, 0.7, 0.15)
    samples = [int(s * e * 16000) for s, e in zip(samples, envelope)]
    
    generate_wav('assets/settlement/audio/farm_animal.wav', duration, sample_rate, samples)
    print("Generated: assets/settlement/audio/farm_animal.wav (procedural sheep-like placeholder)")

def generate_settler_arrive_placeholder():
    """Generate a friendly arrival chime (placeholder until real CC0 greeting)."""
    sample_rate = 44100
    duration = 0.75
    num_samples = int(duration * sample_rate)
    
    samples = []
    # Two-note ascending chime: C4 (262 Hz) -> E4 (330 Hz)
    note1_duration = 0.35
    note2_start = 0.25
    note2_duration = 0.5
    
    for i in range(num_samples):
        t = i / sample_rate
        sample = 0.0
        
        # First note (C4)
        if t < note1_duration:
            amplitude = 0.25 * (1.0 - t / note1_duration)  # Decay
            sample += amplitude * math.sin(2 * math.pi * 262 * t)
            # Add harmonic for warmth
            sample += 0.1 * amplitude * math.sin(2 * math.pi * 524 * t)
        
        # Second note (E4)
        if t >= note2_start and t < note2_start + note2_duration:
            t2 = t - note2_start
            amplitude = 0.28 * (1.0 - t2 / note2_duration)  # Decay
            sample += amplitude * math.sin(2 * math.pi * 330 * t2)
            # Add harmonic
            sample += 0.12 * amplitude * math.sin(2 * math.pi * 660 * t2)
        
        samples.append(int(sample * 18000))
    
    generate_wav('assets/settlement/audio/settler_arrive.wav', duration, sample_rate, samples)
    print("Generated: assets/settlement/audio/settler_arrive.wav (procedural chime placeholder)")

def main():
    print("Generating playtest.9 placeholder audio (procedural CC0)...")
    print("These are minimal placeholders until proper curated CC0 audio is sourced.")
    print()
    
    generate_farm_animal_placeholder()
    generate_settler_arrive_placeholder()
    
    print()
    print("Done! Audio files created in assets/settlement/audio/")
    print()
    print("NOTE: These are PROCEDURAL PLACEHOLDERS.")
    print("Replace with curated CC0 recordings from Freesound/OpenGameArt.")
    print("See docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md for sourcing instructions.")

if __name__ == '__main__':
    main()
