#!/usr/bin/env python3
"""Generate clean procedural SFX for Shard & Sovereign settlement activities.
Style: Clear, punchy, reminiscent of Amiga Settlers II clarity without copyright issues.
All sounds are procedurally generated - no sampling or ripping.
"""

import numpy as np
import wave
import struct
import os

SAMPLE_RATE = 44100

def write_wav(filename, samples, sample_rate=SAMPLE_RATE):
    """Write samples to WAV file."""
    # Normalize to 16-bit range
    samples = np.clip(samples, -1.0, 1.0)
    samples_int = (samples * 32767).astype(np.int16)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(samples_int.tobytes())
    
    print(f"Generated: {filename} ({len(samples)/sample_rate:.2f}s)")

def envelope(duration, attack=0.01, decay=0.05, sustain=0.7, release=0.1):
    """Create ADSR envelope."""
    samples = int(duration * SAMPLE_RATE)
    env = np.zeros(samples)
    
    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    release_samples = int(release * SAMPLE_RATE)
    
    # Attack
    if attack_samples > 0:
        env[:attack_samples] = np.linspace(0, 1, attack_samples)
    
    # Decay
    if decay_samples > 0:
        env[attack_samples:attack_samples+decay_samples] = np.linspace(1, sustain, decay_samples)
    
    # Sustain
    sustain_start = attack_samples + decay_samples
    sustain_end = samples - release_samples
    if sustain_end > sustain_start:
        env[sustain_start:sustain_end] = sustain
    
    # Release
    if release_samples > 0:
        env[-release_samples:] = np.linspace(sustain, 0, release_samples)
    
    return env

def ui_click():
    """Short click for UI interactions."""
    duration = 0.08
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Two-tone click: high frequency pop
    freq1 = 1200
    freq2 = 800
    
    click1 = np.sin(2 * np.pi * freq1 * t) * np.exp(-t * 40)
    click2 = np.sin(2 * np.pi * freq2 * t) * np.exp(-t * 30) * 0.5
    
    sound = (click1 + click2) * 0.6
    return sound

def build_place():
    """Building placement confirmation - satisfying thunk."""
    duration = 0.15
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Low thunk with slight pitch sweep
    freq = 150 * np.exp(-t * 8)
    sound = np.sin(2 * np.pi * freq * t)
    
    # Add a bit of noise for materiality
    noise = np.random.randn(len(t)) * 0.15
    sound = sound * 0.7 + noise * np.exp(-t * 20)
    
    env = envelope(duration, attack=0.01, decay=0.08, sustain=0.3, release=0.06)
    return sound * env

def hammer_construction():
    """Hammering/construction sound."""
    duration = 0.12
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Sharp impact with metallic overtones
    freq = 800
    harmonics = [1.0, 0.5, 0.3, 0.2]
    sound = np.zeros(len(t))
    
    for i, amp in enumerate(harmonics):
        sound += np.sin(2 * np.pi * freq * (i + 1) * t) * amp
    
    # Noise burst for impact
    noise = np.random.randn(len(t)) * 0.3
    sound = sound * 0.5 + noise * np.exp(-t * 50)
    
    env = np.exp(-t * 35)
    return sound * env * 0.7

def wood_chop():
    """Axe chopping wood."""
    duration = 0.18
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Wood impact - mid frequency with snap
    freq = 300 * np.exp(-t * 5)
    sound = np.sin(2 * np.pi * freq * t)
    
    # Noise for woody texture
    noise = np.random.randn(len(t)) * 0.4
    filtered_noise = noise * np.exp(-t * 15)
    
    sound = sound * 0.6 + filtered_noise
    env = np.exp(-t * 20)
    return sound * env * 0.8

def stone_quarry():
    """Stone mining/quarrying."""
    duration = 0.2
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Stone impact - lower, harder
    freq = 200 * np.exp(-t * 3)
    sound = np.sin(2 * np.pi * freq * t)
    
    # More high-frequency noise for stone hardness
    noise = np.random.randn(len(t)) * 0.5
    highpass = noise * (1 + np.sin(2 * np.pi * 2000 * t) * 0.3)
    
    sound = sound * 0.5 + highpass * np.exp(-t * 18)
    env = np.exp(-t * 15)
    return sound * env * 0.75

def combat_hit():
    """Weapon impact - sword/arrow hit."""
    duration = 0.14
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Metallic clang with pitch
    freq = 1200 * (1 + np.sin(2 * np.pi * 50 * t) * 0.3)
    sound = np.sin(2 * np.pi * freq * t)
    
    # Impact noise
    noise = np.random.randn(len(t)) * 0.4
    sound = sound * 0.6 + noise * np.exp(-t * 40)
    
    env = np.exp(-t * 30)
    return sound * env * 0.7

def tower_fire():
    """Watchtower arrow/projectile launch."""
    duration = 0.25
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Whoosh with pitch rise
    freq = 400 + t * 800
    sound = np.sin(2 * np.pi * freq * t)
    
    # Wind/whoosh noise
    noise = np.random.randn(len(t)) * 0.6
    bandpass = noise * np.sin(2 * np.pi * 600 * t) * 0.5
    
    sound = sound * 0.3 + bandpass
    env = envelope(duration, attack=0.02, decay=0.1, sustain=0.5, release=0.13)
    return sound * env * 0.65

def night_warning():
    """Night warning bell/gong."""
    duration = 0.8
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Bell tones with harmonics
    freq = 520
    harmonics = [1.0, 1.5, 2.0, 2.5, 3.0]
    amps = [1.0, 0.4, 0.3, 0.15, 0.1]
    
    sound = np.zeros(len(t))
    for harm, amp in zip(harmonics, amps):
        sound += np.sin(2 * np.pi * freq * harm * t) * amp
    
    env = np.exp(-t * 4)
    return sound * env * 0.5

def delivery_complete():
    """Resource delivery confirmation."""
    duration = 0.18
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Pleasant rising chime
    freq = 600 + t * 400
    sound = np.sin(2 * np.pi * freq * t)
    sound += np.sin(2 * np.pi * freq * 2 * t) * 0.4
    
    env = envelope(duration, attack=0.02, decay=0.08, sustain=0.4, release=0.08)
    return sound * env * 0.6

def building_complete():
    """Building construction finished - satisfying chime."""
    duration = 0.4
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Ascending chord
    freqs = [440, 550, 660]
    sound = np.zeros(len(t))
    
    for i, freq in enumerate(freqs):
        delay = i * 0.08
        delayed_t = np.maximum(0, t - delay)
        note = np.sin(2 * np.pi * freq * delayed_t)
        note_env = np.exp(-delayed_t * 6) * (delayed_t > 0)
        sound += note * note_env * 0.5
    
    return sound * 0.6

def enemy_spawn():
    """Enemy appearance - ominous."""
    duration = 0.3
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Low growl with modulation
    freq = 80 * (1 + np.sin(2 * np.pi * 8 * t) * 0.4)
    sound = np.sin(2 * np.pi * freq * t)
    
    # Add harmonics for menace
    sound += np.sin(2 * np.pi * freq * 2 * t) * 0.6
    sound += np.sin(2 * np.pi * freq * 3 * t) * 0.3
    
    # Noise for texture
    noise = np.random.randn(len(t)) * 0.3
    sound = sound * 0.6 + noise * np.exp(-t * 10)
    
    env = envelope(duration, attack=0.05, decay=0.1, sustain=0.7, release=0.15)
    return sound * env * 0.6

def road_build():
    """Road construction - lighter than building."""
    duration = 0.12
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE))
    
    # Scraping/gravel sound
    freq = 250
    sound = np.sin(2 * np.pi * freq * t) * 0.3
    
    # Gravel noise texture
    noise = np.random.randn(len(t)) * 0.7
    sound += noise * np.exp(-t * 25)
    
    env = np.exp(-t * 30)
    return sound * env * 0.65

def main():
    output_dir = "assets/settlement/audio"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating procedural settlement SFX...")
    print("Style: Clear, punchy colony-sim sounds (Settlers II-inspired)")
    print("License: CC0 (procedurally generated, no sampling)\n")
    
    # Generate all sounds
    write_wav(f"{output_dir}/ui_click.wav", ui_click())
    write_wav(f"{output_dir}/build_start.wav", hammer_construction())
    write_wav(f"{output_dir}/build_complete.wav", building_complete())
    write_wav(f"{output_dir}/road.wav", road_build())
    write_wav(f"{output_dir}/delivery.wav", delivery_complete())
    write_wav(f"{output_dir}/attack.wav", combat_hit())
    write_wav(f"{output_dir}/tower.wav", tower_fire())
    write_wav(f"{output_dir}/night.wav", night_warning())
    write_wav(f"{output_dir}/enemy.wav", enemy_spawn())
    write_wav(f"{output_dir}/soldier.wav", ui_click())  # Reuse click for soldier
    
    # Keep destroyed as-is or generate if needed
    # write_wav(f"{output_dir}/destroyed.wav", building_destroyed())
    
    print("\n✓ SFX generation complete!")
    print("All sounds are CC0 - procedurally generated, no copyrighted samples.")

if __name__ == "__main__":
    main()
