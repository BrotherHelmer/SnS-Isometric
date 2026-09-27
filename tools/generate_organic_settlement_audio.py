#!/usr/bin/env python3
"""
Generate organic settlement SFX with warmth and character.
Settlers-2-inspired FEEL (not copies) - warm, rhythmic colony-work clarity.

All audio is CC0 original synthesis designed to feel like real foley/game audio.
Uses: layered noise, resonant filters, transients, decay tails, body/weight.

License: CC0 (public domain)
Author: Original work for Shard & Sovereign
"""

import wave
import math
import random
import struct
import os

SAMPLE_RATE = 44100
OUTPUT_DIR = "assets/settlement/audio"

def write_wav(filename, samples):
    """Write 16-bit mono WAV with proper normalization."""
    filepath = os.path.join(OUTPUT_DIR, filename)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Normalize to prevent clipping while keeping headroom
    max_val = max(abs(s) for s in samples)
    if max_val > 0:
        # Target -1dB peak
        scale = 0.89 / max_val
        samples = [s * scale for s in samples]
    
    with wave.open(filepath, 'w') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        
        int_samples = []
        for sample in samples:
            val = int(max(-32768, min(32767, sample * 32767)))
            int_samples.append(struct.pack('<h', val))
        
        wav.writeframes(b''.join(int_samples))
    
    print(f"✓ {filename:25s} ({len(samples)/SAMPLE_RATE:.2f}s)")


def lowpass_filter(samples, cutoff_hz, resonance=0.7):
    """Simple resonant lowpass filter for warmth."""
    if not samples:
        return samples
    
    alpha = 2.0 * math.pi * cutoff_hz / SAMPLE_RATE
    feedback = resonance + resonance / (1.0 - alpha)
    
    buf0 = buf1 = 0.0
    result = []
    
    for sample in samples:
        buf0 += alpha * (sample - buf0 + feedback * (buf0 - buf1))
        buf1 += alpha * (buf0 - buf1)
        result.append(buf1)
    
    return result


def add_resonance(samples, freq, decay, amplitude=0.3):
    """Add resonant ring/body to impact sounds."""
    result = list(samples)
    for i in range(len(result)):
        t = i / SAMPLE_RATE
        ring = math.sin(2.0 * math.pi * freq * t) * amplitude * math.exp(-decay * t)
        result[i] += ring
    return result


def noise_burst(duration, color='brown', decay=5.0):
    """Generate colored noise with natural decay."""
    samples = []
    prev = 0.0
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Generate base noise
        white = random.random() * 2.0 - 1.0
        
        # Color the noise
        if color == 'brown':
            # Low frequency rumble
            alpha = 0.02
        elif color == 'pink':
            # Natural mid-range
            alpha = 0.1
        else:  # white
            alpha = 1.0
        
        prev = prev * (1 - alpha) + white * alpha
        
        # Apply decay envelope
        env = math.exp(-decay * t)
        samples.append(prev * env)
    
    return samples


def wood_impact(frequency=180, duration=0.15):
    """Generate organic wood impact with body and resonance."""
    # Sharp attack transient
    transient = []
    for i in range(int(SAMPLE_RATE * 0.005)):
        t = i / SAMPLE_RATE
        # Click + noise burst
        click = math.sin(2.0 * math.pi * 2000 * t) * math.exp(-t * 1000)
        noise = (random.random() * 2 - 1) * 0.5 * math.exp(-t * 800)
        transient.append(click + noise)
    
    # Body resonance
    body = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        # Multiple wood resonances (fundamental + harmonics)
        fundamental = math.sin(2.0 * math.pi * frequency * t)
        harmonic2 = math.sin(2.0 * math.pi * frequency * 2.3 * t) * 0.4
        harmonic3 = math.sin(2.0 * math.pi * frequency * 3.7 * t) * 0.15
        
        tone = (fundamental + harmonic2 + harmonic3) * 0.6
        
        # Add subtle noise for wood texture
        texture = (random.random() * 2 - 1) * 0.1
        
        # Natural wood decay
        env = math.exp(-t * 8) * (1 + 0.3 * math.sin(2 * math.pi * 5 * t))  # slight vibrato
        body.append((tone + texture) * env)
    
    # Combine transient and body
    combined = transient + body
    
    # Warm lowpass filter
    combined = lowpass_filter(combined, 3500, 0.5)
    
    return combined


def metal_impact(frequency=440, duration=0.25, brightness=0.7):
    """Generate metallic impact with realistic ring."""
    samples = []
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Metallic overtone series (inharmonic)
        partials = [
            (frequency, 1.0),
            (frequency * 2.3, 0.6),
            (frequency * 3.8, 0.4),
            (frequency * 5.2, 0.25),
            (frequency * 7.1, 0.15 * brightness),
        ]
        
        tone = sum(math.sin(2.0 * math.pi * f * t) * amp for f, amp in partials)
        
        # Sharp attack, long decay
        if t < 0.01:
            env = t / 0.01  # Attack
        else:
            env = math.exp(-(t - 0.01) * 6)  # Decay
        
        # Add metallic noise
        noise = (random.random() * 2 - 1) * 0.08 * math.exp(-t * 15)
        
        samples.append((tone + noise) * env * 0.7)
    
    return lowpass_filter(samples, 6000, 0.3)


def generate_ui_click():
    """Soft wooden UI tap - pleasant to spam."""
    # Gentle wood knock
    click = wood_impact(frequency=800, duration=0.08)
    
    # Very short, no harsh transient
    click = [s * 0.6 for s in click]
    
    write_wav("ui_click.wav", click)


def generate_build_start():
    """Hammer strike into wood/nail - satisfying impact."""
    # Metal hammer hitting nail
    hammer = metal_impact(frequency=600, duration=0.12, brightness=0.5)
    
    # Wood receiving impact
    wood = wood_impact(frequency=150, duration=0.15)
    
    # Layer them with slight offset
    max_len = max(len(hammer), len(wood))
    combined = []
    for i in range(max_len):
        h = hammer[i] if i < len(hammer) else 0
        w = wood[i] if i < len(wood) else 0
        combined.append(h * 0.7 + w * 0.5)
    
    write_wav("build_start.wav", combined)


def generate_build_complete():
    """Warm musical fanfare - rewarding, major key, cheerful."""
    # C major arpeggio with plucked/bell character
    duration = 0.9
    notes = [
        (523.25, 0.0, 0.3),   # C
        (659.25, 0.15, 0.35), # E
        (783.99, 0.30, 0.4),  # G
        (1046.5, 0.45, 0.55), # C upper
    ]
    
    samples = [0.0] * int(SAMPLE_RATE * duration)
    
    for freq, start_time, note_duration in notes:
        start_sample = int(start_time * SAMPLE_RATE)
        
        for i in range(int(note_duration * SAMPLE_RATE)):
            if start_sample + i >= len(samples):
                break
            
            t = i / SAMPLE_RATE
            
            # Plucked string/bell-like tone
            fundamental = math.sin(2.0 * math.pi * freq * t)
            harmonic2 = math.sin(2.0 * math.pi * freq * 2 * t) * 0.3
            harmonic3 = math.sin(2.0 * math.pi * freq * 3 * t) * 0.15
            
            tone = (fundamental + harmonic2 + harmonic3) * 0.4
            
            # Pluck envelope
            env = math.exp(-t * 5) + 0.3 * math.exp(-t * 2)
            
            samples[start_sample + i] += tone * env
    
    # Gentle fade out
    fade_samples = int(0.1 * SAMPLE_RATE)
    for i in range(fade_samples):
        idx = len(samples) - fade_samples + i
        samples[idx] *= (1.0 - i / fade_samples)
    
    samples = lowpass_filter(samples, 4000, 0.4)
    write_wav("build_complete.wav", samples)


def generate_delivery():
    """Crate/wood thunk with weight - resource dropoff."""
    # Heavy wooden crate impact
    impact = wood_impact(frequency=120, duration=0.18)
    
    # Add some contents rattle
    rattle = noise_burst(0.08, 'brown', decay=12)
    rattle = [r * 0.3 for r in rattle]
    
    # Combine
    combined = []
    for i in range(len(impact)):
        r = rattle[i] if i < len(rattle) else 0
        combined.append(impact[i] + r)
    
    write_wav("delivery.wav", combined)


def generate_road():
    """Gravel/scrape with physical texture - road construction."""
    # Multiple gravel/stone impacts with scraping
    duration = 0.45
    samples = [0.0] * int(SAMPLE_RATE * duration)
    
    # Random stone impacts throughout
    for _ in range(8):
        impact_time = random.uniform(0, duration - 0.1)
        impact_start = int(impact_time * SAMPLE_RATE)
        
        # Small stone impact
        stone = wood_impact(frequency=random.uniform(200, 400), duration=0.08)
        stone = [s * random.uniform(0.3, 0.6) for s in stone]
        
        for i, s in enumerate(stone):
            if impact_start + i < len(samples):
                samples[impact_start + i] += s
    
    # Add scraping texture
    scrape = noise_burst(duration, 'brown', decay=3)
    scrape = lowpass_filter(scrape, 2000, 0.3)
    scrape = [s * 0.4 for s in scrape]
    
    # Combine
    combined = [samples[i] + scrape[i] for i in range(len(samples))]
    write_wav("road.wav", combined)


def generate_woodchop():
    """Axe into tree - satisfying chop with wood split."""
    # Sharp axe blade cutting
    blade = []
    for i in range(int(SAMPLE_RATE * 0.02)):
        t = i / SAMPLE_RATE
        # High freq slice
        slice_sound = math.sin(2.0 * math.pi * 1200 * t) * math.exp(-t * 200)
        noise = (random.random() * 2 - 1) * 0.3 * math.exp(-t * 150)
        blade.append(slice_sound + noise)
    
    # Wood splitting/cracking
    wood = wood_impact(frequency=160, duration=0.15)
    
    # Combine with blade first
    combined = blade + [w * 0.8 for w in wood]
    
    write_wav("woodchop.wav", combined)


def generate_saw():
    """Sawmill blade with grain and rhythm - busy workshop sound."""
    duration = 0.55
    samples = []
    
    # Sawblade motor drone + teeth rhythm
    base_freq = 120  # motor
    tooth_freq = 18  # teeth hitting wood
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Motor drone with slight fluctuation
        motor = math.sin(2.0 * math.pi * base_freq * t) * 0.3
        motor += math.sin(2.0 * math.pi * base_freq * 2 * t) * 0.15
        
        # Teeth impacts (amplitude modulation)
        teeth_rhythm = abs(math.sin(2.0 * math.pi * tooth_freq * t))
        
        # High freq buzz from blade
        buzz = math.sin(2.0 * math.pi * (base_freq * 8 + 50 * teeth_rhythm) * t) * 0.25
        
        # Wood grain texture
        grain = (random.random() * 2 - 1) * 0.15 * teeth_rhythm
        
        # Combine with envelope
        env = 1.0 if t < 0.45 else (1.0 - (t - 0.45) / 0.1)  # sustain then quick release
        
        samples.append((motor + buzz * teeth_rhythm + grain) * env * 0.7)
    
    samples = lowpass_filter(samples, 3000, 0.4)
    write_wav("saw.wav", samples)


def generate_attack():
    """Combat hit - sword/weapon impact with weight."""
    # Metal weapon strike
    weapon = metal_impact(frequency=450, duration=0.12, brightness=0.8)
    
    # Impact on armor/body
    impact_thud = wood_impact(frequency=100, duration=0.1)
    
    # Combine
    max_len = max(len(weapon), len(impact_thud))
    combined = []
    for i in range(max_len):
        w = weapon[i] if i < len(weapon) else 0
        t = impact_thud[i] if i < len(impact_thud) else 0
        combined.append(w * 0.6 + t * 0.4)
    
    write_wav("attack.wav", combined)


def generate_tower():
    """Arrow launch - whoosh with bow twang."""
    duration = 0.3
    samples = []
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Bow string twang (pluck)
        twang_freq = 220 + (1.0 - t / duration) * 100  # slight pitch bend
        twang = math.sin(2.0 * math.pi * twang_freq * t) * math.exp(-t * 12)
        
        # Arrow whoosh (swept filtered noise)
        whoosh = (random.random() * 2 - 1) * 0.4
        whoosh_env = math.exp(-t * 4) * (1 - t / duration)
        
        samples.append((twang * 0.4 + whoosh * whoosh_env) * 0.7)
    
    samples = lowpass_filter(samples, 5000 - int(3000 * min(1, i / len(samples))), 0.3)
    write_wav("tower.wav", samples)


def generate_enemy():
    """Enemy spawn - ominous low growl with gothic character."""
    duration = 0.7
    samples = []
    
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Deep growl (low freq with inharmonic partials)
        freq1 = 85 + math.sin(2 * math.pi * 4 * t) * 8  # slow vibrato
        freq2 = 127  # minor third for tension
        
        growl = math.sin(2.0 * math.pi * freq1 * t) * 0.5
        growl += math.sin(2.0 * math.pi * freq2 * t) * 0.3
        growl += math.sin(2.0 * math.pi * freq1 * 2.5 * t) * 0.15  # inharmonic
        
        # Dark texture
        texture = (random.random() * 2 - 1) * 0.12
        
        # Envelope: swell then sustain
        if t < 0.1:
            env = t / 0.1
        elif t < 0.5:
            env = 1.0
        else:
            env = 1.0 - (t - 0.5) / 0.2
        
        samples.append((growl + texture) * env * 0.7)
    
    samples = lowpass_filter(samples, 800, 0.6)
    write_wav("enemy.wav", samples)


def generate_night():
    """Nightfall warning - descending tense chord, cozy-horror."""
    duration = 1.0
    samples = []
    
    # Minor chord descending (tense but not cartoon)
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        progress = t / duration
        
        # A minor chord with descending sweep
        freq_a = 440 * math.pow(0.6, progress)  # A descending
        freq_c = 523.25 * math.pow(0.6, progress)  # C descending
        freq_e = 329.63 * math.pow(0.6, progress)  # E descending
        
        # String-like tones
        tone_a = math.sin(2.0 * math.pi * freq_a * t) * 0.35
        tone_c = math.sin(2.0 * math.pi * freq_c * t) * 0.3
        tone_e = math.sin(2.0 * math.pi * freq_e * t) * 0.25
        
        # Add slight dissonance for unease
        dissonance = math.sin(2.0 * math.pi * (freq_a * 1.05) * t) * 0.1
        
        # Envelope with slow fade
        env = math.exp(-t * 1.5) + 0.4 * math.exp(-t * 0.5)
        
        samples.append((tone_a + tone_c + tone_e + dissonance) * env)
    
    samples = lowpass_filter(samples, 2500, 0.5)
    write_wav("night.wav", samples)


def generate_soldier():
    """Military unit ready - firm horn-like acknowledgement."""
    duration = 0.4
    samples = []
    
    # Two-tone military signal (brass-like)
    notes = [(392, 0.0, 0.18), (523.25, 0.15, 0.25)]  # G -> C
    
    samples = [0.0] * int(SAMPLE_RATE * duration)
    
    for freq, start_time, note_duration in notes:
        start_sample = int(start_time * SAMPLE_RATE)
        
        for i in range(int(note_duration * SAMPLE_RATE)):
            if start_sample + i >= len(samples):
                break
            
            t = i / SAMPLE_RATE
            
            # Brass-like tone (odd harmonics prominent)
            fundamental = math.sin(2.0 * math.pi * freq * t)
            harmonic3 = math.sin(2.0 * math.pi * freq * 3 * t) * 0.25
            harmonic5 = math.sin(2.0 * math.pi * freq * 5 * t) * 0.12
            
            tone = (fundamental + harmonic3 + harmonic5) * 0.5
            
            # Horn envelope (slight attack, sustain, release)
            if t < 0.02:
                env = t / 0.02
            elif t < note_duration - 0.05:
                env = 1.0
            else:
                env = (note_duration - t) / 0.05
            
            samples[start_sample + i] += tone * env
    
    samples = lowpass_filter(samples, 3500, 0.4)
    write_wav("soldier.wav", samples)


def generate_destroyed():
    """Building destruction - crash/collapse with weight and rumble."""
    duration = 1.3
    samples = []
    
    # Initial impact crash
    crash = noise_burst(0.3, 'pink', decay=8)
    crash = [c * 0.8 for c in crash]
    
    # Add multiple wood breaking sounds
    for _ in range(5):
        break_time = random.uniform(0, 0.4)
        break_start = int(break_time * SAMPLE_RATE)
        wood_break = wood_impact(frequency=random.uniform(100, 200), duration=0.15)
        wood_break = [w * random.uniform(0.4, 0.7) for w in wood_break]
        
        for i, w in enumerate(wood_break):
            if break_start + i < len(crash):
                crash[break_start + i] += w
    
    # Deep rumble/aftermath
    rumble = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        
        # Low frequency rumble
        r = math.sin(2.0 * math.pi * 45 * t) * 0.4
        r += math.sin(2.0 * math.pi * 67 * t) * 0.3
        r += math.sin(2.0 * math.pi * 90 * t) * 0.2
        
        # Add settling debris noise
        debris = (random.random() * 2 - 1) * 0.15
        
        # Long decay
        env = math.exp(-t * 1.5)
        rumble.append((r + debris) * env)
    
    # Combine crash and rumble
    combined = []
    for i in range(len(rumble)):
        c = crash[i] if i < len(crash) else 0
        combined.append(c + rumble[i])
    
    combined = lowpass_filter(combined, 1800, 0.5)
    write_wav("destroyed.wav", combined)


def main():
    print("Generating organic settlement SFX with warmth and character...")
    print(f"Settlers-2-inspired FEEL - colony-work clarity with soul\n")
    
    generate_ui_click()
    generate_build_start()
    generate_build_complete()
    generate_delivery()
    generate_road()
    generate_woodchop()
    generate_saw()
    generate_attack()
    generate_tower()
    generate_enemy()
    generate_night()
    generate_soldier()
    generate_destroyed()
    
    print(f"\n✓ Generated 13 audio files with warmth and character")
    print("  Uses: layered synthesis, resonance, filtered noise, organic decay")
    print("  Character: Wood impacts, metallic rings, physical weight, rhythmic work")
    print("  License: CC0 original (not Settlers samples)")


if __name__ == "__main__":
    main()
