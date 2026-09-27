@tool
extends ScriptedEditorPlugin

## Issue #6: Generate better placeholder audio than simple sine waves
## This script creates colony-sim style SFX using Godot's AudioStreamGenerator
## for temporary use until proper CC0/libre audio is sourced.

const SAMPLE_RATE := 44100
const OUTPUT_DIR := "res://assets/settlement/audio/"

static func _ready() -> void:
	print("Placeholder audio generator ready. Run generate_all() to create audio files.")


static func generate_all() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	
	# Build sounds
	_generate_build_start()
	_generate_build_complete()
	_generate_delivery()
	_generate_road()
	
	# Combat sounds
	_generate_attack()
	_generate_tower()
	_generate_enemy()
	
	# Event sounds
	_generate_night()
	_generate_soldier()
	_generate_destroyed()
	
	print("Generated placeholder audio files in %s" % OUTPUT_DIR)


static func _generate_build_start() -> void:
	# Hammer strike: short percussive hit
	var stream := _create_simple_wave(0.3, 440.0, 0.8, "decay")
	_add_harmonic(stream, 880.0, 0.4)
	_add_noise(stream, 0.15)
	ResourceSaver.save(stream, OUTPUT_DIR + "build_start.wav")


static func _generate_build_complete() -> void:
	# Completion chime: rising tone with decay
	var stream := _create_simple_wave(0.6, 523.25, 0.6, "sustained")
	_add_harmonic(stream, 659.25, 0.5)
	_add_harmonic(stream, 783.99, 0.3)
	ResourceSaver.save(stream, OUTPUT_DIR + "build_complete.wav")


static func _generate_delivery() -> void:
	# Resource drop: short thunk
	var stream := _create_simple_wave(0.2, 220.0, 0.7, "decay")
	_add_noise(stream, 0.2)
	ResourceSaver.save(stream, OUTPUT_DIR + "delivery.wav")


static func _generate_road() -> void:
	# Road construction: brief scraping/grinding
	var stream := _create_noise_burst(0.35, 0.5, "decay")
	ResourceSaver.save(stream, OUTPUT_DIR + "road.wav")


static func _generate_attack() -> void:
	# Sword/weapon hit
	var stream := _create_simple_wave(0.25, 330.0, 0.7, "sharp_decay")
	_add_noise(stream, 0.3)
	_add_harmonic(stream, 165.0, 0.4)
	ResourceSaver.save(stream, OUTPUT_DIR + "attack.wav")


static func _generate_tower() -> void:
	# Arrow/projectile launch
	var stream := _create_sweep(0.3, 800.0, 400.0, 0.5)
	_add_noise(stream, 0.15)
	ResourceSaver.save(stream, OUTPUT_DIR + "tower.wav")


static func _generate_enemy() -> void:
	# Enemy spawn: low ominous tone
	var stream := _create_simple_wave(0.5, 110.0, 0.6, "sustained")
	_add_harmonic(stream, 165.0, 0.4)
	ResourceSaver.save(stream, OUTPUT_DIR + "enemy.wav")


static func _generate_night() -> void:
	# Nightfall sting: descending tense chord
	var stream := _create_sweep(0.8, 523.25, 220.0, 0.7)
	_add_harmonic(stream, 329.63, 0.5)
	ResourceSaver.save(stream, OUTPUT_DIR + "night.wav")


static func _generate_soldier() -> void:
	# Military unit acknowledgement: firm, brief tone
	var stream := _create_simple_wave(0.35, 392.0, 0.6, "decay")
	_add_harmonic(stream, 587.33, 0.4)
	ResourceSaver.save(stream, OUTPUT_DIR + "soldier.wav")


static func _generate_destroyed() -> void:
	# Building destruction: crash/collapse
	var stream := _create_noise_burst(1.0, 0.8, "long_decay")
	_add_rumble(stream, 80.0, 0.5)
	ResourceSaver.save(stream, OUTPUT_DIR + "destroyed.wav")


static func _create_simple_wave(duration: float, frequency: float, amplitude: float, envelope: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var phase := t * frequency * TAU
		var sample := sin(phase) * amplitude
		
		# Apply envelope
		var env_mult := 1.0
		match envelope:
			"decay":
				env_mult = exp(-t * 8.0)
			"sharp_decay":
				env_mult = exp(-t * 15.0)
			"sustained":
				env_mult = exp(-t * 2.0)
		
		sample *= env_mult
		var sample_int := int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_int)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	return stream


static func _create_noise_burst(duration: float, amplitude: float, envelope: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var sample := (randf() * 2.0 - 1.0) * amplitude
		
		# Apply envelope
		var env_mult := 1.0
		match envelope:
			"decay":
				env_mult = exp(-t * 8.0)
			"long_decay":
				env_mult = exp(-t * 3.0)
		
		sample *= env_mult
		var sample_int := int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_int)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	return stream


static func _create_sweep(duration: float, start_freq: float, end_freq: float, amplitude: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	
	var phase := 0.0
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var frequency := lerp(start_freq, end_freq, progress)
		phase += frequency * TAU / SAMPLE_RATE
		
		var sample := sin(phase) * amplitude * exp(-t * 3.0)
		var sample_int := int(clamp(sample * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample_int)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	return stream


static func _add_harmonic(stream: AudioStreamWAV, frequency: float, amplitude: float) -> void:
	# Add a harmonic overtone to existing stream
	var frame_count := stream.data.size() / 2
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var phase := t * frequency * TAU
		var existing := stream.data.decode_s16(i * 2)
		var harmonic := sin(phase) * amplitude * 32767.0 * exp(-t * 5.0)
		var combined := int(clamp(float(existing) + harmonic, -32768.0, 32767.0))
		stream.data.encode_s16(i * 2, combined)


static func _add_noise(stream: AudioStreamWAV, amplitude: float) -> void:
	# Add noise texture
	var frame_count := stream.data.size() / 2
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var existing := stream.data.decode_s16(i * 2)
		var noise := (randf() * 2.0 - 1.0) * amplitude * 32767.0 * exp(-t * 10.0)
		var combined := int(clamp(float(existing) + noise, -32768.0, 32767.0))
		stream.data.encode_s16(i * 2, combined)


static func _add_rumble(stream: AudioStreamWAV, frequency: float, amplitude: float) -> void:
	# Add low-frequency rumble
	var frame_count := stream.data.size() / 2
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var phase := t * frequency * TAU
		var existing := stream.data.decode_s16(i * 2)
		var rumble := sin(phase) * amplitude * 32767.0 * exp(-t * 2.0)
		var combined := int(clamp(float(existing) + rumble, -32768.0, 32767.0))
		stream.data.encode_s16(i * 2, combined)
