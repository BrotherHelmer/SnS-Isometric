#!/usr/bin/env python3
"""
Generate CC0 original settlement SFX for Shard & Sovereign.
Modern colony-sim clarity (Settlers-II-inspired) without commercial sample ripping.

All audio generated here is original work, licensed CC0 (public domain).
Uses layered synthesis: noise, harmonics, envelopes, and simple FM for character.
"""

import wave
import math
import random
import struct
import os

SAMPLE_RATE = 44100
OUTPUT_DIR = "assets/settlement/audio"

def write_wav(filename, samples):
    """Write 16-bit mono WAV file."""
    filepath = os.path.join(OUTPUT_DIR, filename)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    with wave.open(filepath, 'w') as wav:
        wav.setnchannels(1)  # Mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(SAMPLE_RATE)
        
        # Convert float samples to 16-bit integers
        int_samples = []
        for sample in samples:
            val = int(max(-32768, min(32767, sample * 32767)))
            int_samples.append(struct.pack('<h', val))
        
        wav.writeframes(b''.join(int_samples))
    
    print(f"✓ Generated {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")


def envelope_adsr(t, duration, attack=0.01, decay=0.05, sustain_level=0.7, release=0.1):
    """ADSR envelope for natural sound shaping."""
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain_level) * ((t - attack) / decay)
    elif t < duration - release:
        return sustain_level
    else:
        return sustain_level * (1.0 - (t - (duration - release)) / release)


def generate_tone(frequency, duration, amplitude=0.5, harmonics=None):
    """Generate tone with optional harmonics (list of (freq_mult, amp_mult) tuples)."""
    samples = []
    harmonics = harmonics or []
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Base frequency
        sample = math.sin(2.0 * math.pi * frequency * t) * amplitude
        
        # Add harmonics
        for h_mult, h_amp in harmonics:
            sample += math.sin(2.0 * math.pi * frequency * h_mult * t) * amplitude * h_amp
        
        # Apply envelope
        env = envelope_adsr(t, duration)
        samples.append(sample * env)
    
    return samples


def add_noise(samples, noise_level=0.05, cutoff_freq=5000):
    """Add filtered noise for texture."""
    result = []
    prev = 0.0
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_freq / SAMPLE_RATE)
    
    for sample in samples:
        noise = (random.random() * 2.0 - 1.0) * noise_level
        # Simple one-pole lowpass filter
        prev = prev + alpha * (noise - prev)
        result.append(sample + prev)
    
    return result


def generate_sweep(start_freq, end_freq, duration, amplitude=0.5):
    """Generate frequency sweep (good for whooshes, impacts)."""
    samples = []
    phase = 0.0
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # Exponential frequency sweep
        freq = start_freq * math.pow(end_freq / start_freq, progress)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        sample = math.sin(phase) * amplitude
        env = envelope_adsr(t, duration, attack=0.001, decay=0.02, sustain_level=0.6, release=duration*0.3)
        samples.append(sample * env)
    
    return samples


def generate_click():
    """UI click - short, crisp, satisfying."""
    # Two-tone click with quick decay
    base = generate_tone(1200, 0.06, amplitude=0.6, harmonics=[(2, 0.3), (3, 0.15)])
    base = add_noise(base, noise_level=0.08)
    write_wav("ui_click.wav", base)


def generate_build_start():
    """Hammer strike - percussive hit with body."""
    # Impact: quick sweep down with noise burst
    impact = generate_sweep(800, 150, 0.08, amplitude=0.7)
    impact = add_noise(impact, noise_level=0.25, cutoff_freq=3000)
    
    # Add metallic ring
    ring = generate_tone(440, 0.15, amplitude=0.3, harmonics=[(2, 0.2), (3, 0.1)])
    
    # Combine
    combined = [impact[i] + (ring[i] if i < len(ring) else 0) for i in range(len(impact))]
    write_wav("build_start.wav", combined)


def generate_build_complete():
    """Satisfying completion chime - major chord rising."""
    # C major chord: C-E-G (523.25, 659.25, 783.99 Hz)
    c_note = generate_tone(523.25, 0.8, amplitude=0.4, harmonics=[(2, 0.2)])
    e_note = generate_tone(659.25, 0.8, amplitude=0.35, harmonics=[(2, 0.15)])
    g_note = generate_tone(783.99, 0.8, amplitude=0.3, harmonics=[(2, 0.1)])
    
    max_len = max(len(c_note), len(e_note), len(g_note))
    chord = []
    for i in range(max_len):
        sample = 0
        if i < len(c_note): sample += c_note[i]
        if i < len(e_note): sample += e_note[i]
        if i < len(g_note): sample += g_note[i]
        chord.append(sample * 0.5)  # Scale down to prevent clipping
    
    write_wav("build_complete.wav", chord)


def generate_delivery():
    """Resource dropoff - thunk/crate landing."""
    # Low impact with quick decay
    thunk = generate_sweep(220, 80, 0.15, amplitude=0.65)
    thunk = add_noise(thunk, noise_level=0.2, cutoff_freq=2000)
    write_wav("delivery.wav", thunk)


def generate_road():
    """Road construction - scraping/grinding gravel."""
    # Noise burst with lowpass sweep
    samples = []
    duration = 0.4
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        # Filtered noise
        noise = (random.random() * 2.0 - 1.0) * 0.5
        
        # Add some tonal component for character
        tone = math.sin(2.0 * math.pi * 150 * t) * 0.2
        
        env = envelope_adsr(t, duration, attack=0.02, decay=0.1, sustain_level=0.4, release=0.15)
        samples.append((noise + tone) * env)
    
    write_wav("road.wav", samples)


def generate_attack():
    """Combat hit - sword/weapon impact."""
    # Metallic clang with quick attack
    clang = generate_sweep(600, 200, 0.12, amplitude=0.7)
    clang = add_noise(clang, noise_level=0.3, cutoff_freq=4000)
    
    # Add metallic ring
    ring = generate_tone(330, 0.18, amplitude=0.25, harmonics=[(3, 0.15), (5, 0.08)])
    
    max_len = max(len(clang), len(ring))
    combined = []
    for i in range(max_len):
        sample = (clang[i] if i < len(clang) else 0) + (ring[i] if i < len(ring) else 0)
        combined.append(sample)
    
    write_wav("attack.wav", combined)


def generate_tower():
    """Watchtower arrow shot - whoosh/launch."""
    # Quick high-to-low sweep with air noise
    arrow = generate_sweep(1200, 300, 0.25, amplitude=0.5)
    arrow = add_noise(arrow, noise_level=0.15, cutoff_freq=6000)
    write_wav("tower.wav", arrow)


def generate_enemy():
    """Enemy spawn - ominous low growl."""
    # Low rumbling tone with slight vibrato
    samples = []
    duration = 0.6
    base_freq = 110
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Add vibrato (slight frequency modulation)
        vibrato = math.sin(2.0 * math.pi * 5 * t) * 8
        freq = base_freq + vibrato
        
        # Two octaves for depth
        sample = math.sin(2.0 * math.pi * freq * t) * 0.5
        sample += math.sin(2.0 * math.pi * freq * 0.5 * t) * 0.3
        
        env = envelope_adsr(t, duration, attack=0.05, decay=0.1, sustain_level=0.6, release=0.2)
        samples.append(sample * env)
    
    samples = add_noise(samples, noise_level=0.08, cutoff_freq=800)
    write_wav("enemy.wav", samples)


def generate_night():
    """Nightfall warning - descending tense chord."""
    # Minor chord descending sweep
    duration = 0.9
    samples = []
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # Descending frequencies (A minor chord sweeping down)
        freq1 = 440 * math.pow(0.5, progress)  # A down to A lower
        freq2 = 523.25 * math.pow(0.5, progress)  # C down
        
        sample = math.sin(2.0 * math.pi * freq1 * t) * 0.4
        sample += math.sin(2.0 * math.pi * freq2 * t) * 0.3
        
        env = envelope_adsr(t, duration, attack=0.02, decay=0.1, sustain_level=0.7, release=0.3)
        samples.append(sample * env)
    
    write_wav("night.wav", samples)


def generate_soldier():
    """Military unit acknowledgement - firm, authoritative."""
    # Two-tone military "ready" sound
    tone1 = generate_tone(392, 0.15, amplitude=0.5, harmonics=[(2, 0.2)])
    tone2 = generate_tone(523.25, 0.2, amplitude=0.45, harmonics=[(2, 0.15)])
    
    # Slight gap then second tone
    gap = [0.0] * int(SAMPLE_RATE * 0.03)
    combined = tone1 + gap + tone2
    write_wav("soldier.wav", combined)


def generate_destroyed():
    """Building destruction - crash/collapse."""
    # Heavy rumble with noise burst
    samples = []
    duration = 1.2
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Deep rumble (multiple low frequencies)
        rumble = math.sin(2.0 * math.pi * 60 * t) * 0.4
        rumble += math.sin(2.0 * math.pi * 90 * t) * 0.3
        rumble += math.sin(2.0 * math.pi * 45 * t) * 0.2
        
        # Add heavy noise for impact
        noise = (random.random() * 2.0 - 1.0) * 0.5
        
        env = envelope_adsr(t, duration, attack=0.005, decay=0.2, sustain_level=0.3, release=0.5)
        samples.append((rumble + noise * 0.7) * env)
    
    # Apply lowpass to noise component
    write_wav("destroyed.wav", samples)


def generate_woodchop():
    """Woodchopping - axe hitting tree."""
    # Sharp impact then wood resonance
    chop = generate_sweep(500, 120, 0.12, amplitude=0.65)
    chop = add_noise(chop, noise_level=0.2, cutoff_freq=2500)
    
    # Wood resonance
    wood = generate_tone(180, 0.25, amplitude=0.3, harmonics=[(2, 0.15), (3, 0.08)])
    
    combined = [chop[i] + (wood[i] if i < len(wood) else 0) for i in range(len(chop))]
    write_wav("woodchop.wav", combined)


def generate_saw():
    """Sawing wood - mechanical sawmill."""
    # Buzzing/grinding with rhythm
    samples = []
    duration = 0.5
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Buzzing saw blade (high frequency with modulation)
        buzz_freq = 220 + math.sin(2.0 * math.pi * 8 * t) * 30
        buzz = math.sin(2.0 * math.pi * buzz_freq * t) * 0.4
        
        # Add some harmonics
        buzz += math.sin(2.0 * math.pi * buzz_freq * 2 * t) * 0.2
        
        env = envelope_adsr(t, duration, attack=0.02, decay=0.08, sustain_level=0.6, release=0.15)
        samples.append(buzz * env)
    
    samples = add_noise(samples, noise_level=0.15, cutoff_freq=4000)
    write_wav("saw.wav", samples)


def main():
    print("Generating CC0 original settlement SFX for Shard & Sovereign...")
    print(f"Output directory: {OUTPUT_DIR}\n")
    
    # UI
    generate_click()
    
    # Construction
    generate_build_start()
    generate_build_complete()
    generate_road()
    generate_delivery()
    
    # Work sounds
    generate_woodchop()
    generate_saw()
    
    # Combat
    generate_attack()
    generate_tower()
    generate_enemy()
    
    # Events
    generate_night()
    generate_soldier()
    generate_destroyed()
    
    print(f"\n✓ Generated 13 audio files in {OUTPUT_DIR}/")
    print("All audio is original synthesis, licensed CC0 (public domain).")


if __name__ == "__main__":
    main()
