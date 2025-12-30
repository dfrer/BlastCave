extends Node
class_name AudioManager

## Centralized audio management with procedural sound generation
## Provides high-quality game audio without requiring external audio files

# Singleton access
static var instance: AudioManager

# Audio bus indices
var master_bus_idx: int = 0
var sfx_bus_idx: int = -1
var music_bus_idx: int = -1
var ambient_bus_idx: int = -1

# Pool of audio players for performance
var _sfx_pool: Array[AudioStreamPlayer3D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _ambient_players: Dictionary = {}  # room_id -> AudioStreamPlayer3D

const SFX_POOL_SIZE: int = 16
const UI_POOL_SIZE: int = 8

# Cached procedural streams
var _explosion_streams: Dictionary = {}  # explosive_type -> AudioStream
var _impact_streams: Dictionary = {}  # surface_type -> AudioStream
var _ui_streams: Dictionary = {}  # action_type -> AudioStream

func _ready() -> void:
	instance = self
	_setup_audio_buses()
	_create_audio_pools()
	_generate_procedural_sounds()

func _setup_audio_buses() -> void:
	# Create audio buses if they don't exist
	var bus_count = AudioServer.bus_count
	
	# Check for existing buses
	for i in range(bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		if bus_name == "SFX":
			sfx_bus_idx = i
		elif bus_name == "Music":
			music_bus_idx = i
		elif bus_name == "Ambient":
			ambient_bus_idx = i
	
	# Create SFX bus if missing
	if sfx_bus_idx == -1:
		sfx_bus_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")
	
	# Create Ambient bus if missing
	if ambient_bus_idx == -1:
		ambient_bus_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(ambient_bus_idx, "Ambient")
		AudioServer.set_bus_send(ambient_bus_idx, "Master")
		AudioServer.set_bus_volume_db(ambient_bus_idx, -6.0)

func _create_audio_pools() -> void:
	# Create 3D SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer3D.new()
		player.bus = "SFX"
		player.max_distance = 50.0
		player.unit_size = 5.0
		player.max_polyphony = 4
		add_child(player)
		_sfx_pool.append(player)
	
	# Create 2D UI pool
	for i in range(UI_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -3.0
		add_child(player)
		_ui_pool.append(player)

func _generate_procedural_sounds() -> void:
	# Generate explosion sounds for each type
	_explosion_streams["ImpulseCharge"] = _create_explosion_sound(440.0, 0.4, 1.0)
	_explosion_streams["ShapedCharge"] = _create_explosion_sound(330.0, 0.5, 1.3)
	_explosion_streams["DelayedCharge"] = _create_explosion_sound(280.0, 0.6, 0.9)
	_explosion_streams["ClusterCharge"] = _create_explosion_sound(520.0, 0.3, 0.7)
	_explosion_streams["RepulsorCharge"] = _create_explosion_sound(600.0, 0.35, 1.1)
	
	# Generate impact sounds for different surfaces
	_impact_streams["rock"] = _create_impact_sound(200.0, 0.15, 0.8)
	_impact_streams["metal"] = _create_impact_sound(800.0, 0.2, 0.4)
	_impact_streams["crystal"] = _create_impact_sound(1200.0, 0.25, 0.3)
	_impact_streams["flesh"] = _create_impact_sound(150.0, 0.1, 0.9)
	_impact_streams["default"] = _create_impact_sound(300.0, 0.12, 0.6)
	
	# Generate UI sounds
	_ui_streams["click"] = _create_ui_click_sound()
	_ui_streams["hover"] = _create_ui_hover_sound()
	_ui_streams["confirm"] = _create_ui_confirm_sound()
	_ui_streams["cancel"] = _create_ui_cancel_sound()
	_ui_streams["pickup"] = _create_pickup_sound()
	_ui_streams["error"] = _create_error_sound()

# === EXPLOSION SOUND GENERATION ===

func _create_explosion_sound(base_freq: float, duration: float, intensity: float) -> AudioStreamWAV:
	var sample_rate := 44100.0
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)  # 16-bit audio = 2 bytes per sample
	
	for i in range(samples):
		var t := float(i) / sample_rate
		var envelope := _explosion_envelope(t, duration)
		
		# Layer 1: Low bass boom
		var bass := sin(TAU * base_freq * 0.25 * t) * 0.5
		bass *= exp(-t * 8.0)  # Fast decay
		
		# Layer 2: Mid-frequency crack
		var crack := sin(TAU * base_freq * t + sin(TAU * 50.0 * t) * 3.0) * 0.3
		crack *= exp(-t * 15.0)  # Very fast decay
		
		# Layer 3: High-frequency debris/shatter
		var debris := (randf() * 2.0 - 1.0) * 0.4  # White noise
		debris *= exp(-t * 6.0)  # Medium decay
		
		# Layer 4: Rumble tail
		var rumble := sin(TAU * base_freq * 0.1 * t) * 0.2
		rumble *= exp(-t * 3.0)  # Slow decay
		
		# Combine layers with intensity scaling
		var sample := (bass + crack + debris + rumble) * envelope * intensity
		sample = clampf(sample, -1.0, 1.0)
		
		# Convert to 16-bit signed integer
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _explosion_envelope(t: float, duration: float) -> float:
	# Attack-decay-sustain-release envelope
	var attack := 0.005
	var decay := 0.05
	var sustain_level := 0.6
	var release_start := duration * 0.7
	
	if t < attack:
		return t / attack
	elif t < attack + decay:
		return 1.0 - (1.0 - sustain_level) * ((t - attack) / decay)
	elif t < release_start:
		return sustain_level
	else:
		return sustain_level * (1.0 - (t - release_start) / (duration - release_start))

# === IMPACT SOUND GENERATION ===

func _create_impact_sound(freq: float, duration: float, dampness: float) -> AudioStreamWAV:
	var sample_rate := 44100.0
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		
		# Initial thump
		var thump := sin(TAU * freq * t) * exp(-t * 30.0 / dampness)
		
		# Surface resonance
		var resonance := sin(TAU * freq * 1.5 * t) * exp(-t * 20.0) * 0.3
		
		# Texture noise
		var texture := (randf() * 2.0 - 1.0) * exp(-t * 40.0) * 0.2
		
		var sample := (thump + resonance + texture) * 0.8
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

# === UI SOUND GENERATION ===

func _create_ui_click_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.05
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		var sample := sin(TAU * 1000.0 * t) * exp(-t * 100.0)
		sample += sin(TAU * 2500.0 * t) * exp(-t * 150.0) * 0.3
		sample = clampf(sample * 0.5, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _create_ui_hover_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.03
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		var sample := sin(TAU * 800.0 * t) * exp(-t * 80.0) * 0.3
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _create_ui_confirm_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.15
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		# Rising two-tone
		var freq1 := 600.0 + t * 400.0
		var freq2 := 900.0 + t * 600.0
		var sample := sin(TAU * freq1 * t) * 0.4 + sin(TAU * freq2 * t) * 0.3
		sample *= exp(-t * 10.0)
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _create_ui_cancel_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.12
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		# Falling tone
		var freq := 500.0 - t * 300.0
		var sample := sin(TAU * freq * t) * exp(-t * 15.0) * 0.5
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _create_pickup_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.2
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		# Bright ascending arpeggio-like
		var freq := 800.0 + sin(t * 30.0) * 200.0 + t * 500.0
		var sample := sin(TAU * freq * t) * exp(-t * 8.0) * 0.5
		sample += sin(TAU * freq * 2.0 * t) * exp(-t * 12.0) * 0.2
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

func _create_error_sound() -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 0.15
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		# Harsh buzz
		var sample := sin(TAU * 150.0 * t) * 0.4
		sample += sin(TAU * 300.0 * t) * 0.3
		sample *= (1.0 + sin(TAU * 30.0 * t) * 0.5)  # Modulation
		sample *= exp(-t * 12.0)
		sample = clampf(sample, -1.0, 1.0)
		
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	return stream

# === PUBLIC API ===

## Play an explosion sound at a 3D position
func play_explosion(position: Vector3, explosive_type: String, volume_db: float = 0.0) -> void:
	var stream = _explosion_streams.get(explosive_type, _explosion_streams.get("ImpulseCharge"))
	if stream:
		_play_3d_sound(stream, position, volume_db)

## Play an impact sound at a 3D position
func play_impact(position: Vector3, surface_type: String = "default", velocity: float = 1.0) -> void:
	var stream = _impact_streams.get(surface_type, _impact_streams.get("default"))
	if stream:
		var volume := clampf(velocity * 0.1, -20.0, 6.0)
		_play_3d_sound(stream, position, volume)

## Play a UI sound (2D, non-positional)
func play_ui(action: String, volume_db: float = 0.0) -> void:
	var stream = _ui_streams.get(action)
	if stream:
		_play_2d_sound(stream, volume_db)

## Start ambient sound for a room
func start_ambient(room_id: String, ambient_type: String, position: Vector3) -> void:
	if _ambient_players.has(room_id):
		return  # Already playing
	
	var player = AudioStreamPlayer3D.new()
	player.bus = "Ambient"
	player.max_distance = 100.0
	player.unit_size = 10.0
	player.stream = _create_ambient_loop(ambient_type)
	# Add to tree first, then set position
	add_child(player)
	player.global_position = position
	player.play()
	_ambient_players[room_id] = player

## Stop ambient sound for a room
func stop_ambient(room_id: String) -> void:
	if _ambient_players.has(room_id):
		var player = _ambient_players[room_id] as AudioStreamPlayer3D
		if player:
			player.stop()
			player.queue_free()
		_ambient_players.erase(room_id)

func _create_ambient_loop(ambient_type: String) -> AudioStreamWAV:
	var sample_rate := 44100.0
	var duration := 2.0  # Loop every 2 seconds
	var samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / sample_rate
		var sample := 0.0
		
		match ambient_type:
			"cave":
				# Dripping water + low rumble
				sample = sin(TAU * 40.0 * t) * 0.05  # Rumble
				if fmod(t, 0.7) < 0.01:  # Occasional drip
					sample += sin(TAU * 2000.0 * t) * exp(-fmod(t, 0.7) * 500.0) * 0.1
			"toxic":
				# Bubbling + hiss
				sample = sin(TAU * 60.0 * t + sin(TAU * 3.0 * t) * 2.0) * 0.04
				sample += (randf() * 2.0 - 1.0) * 0.02
			"crystal":
				# High resonant hum
				sample = sin(TAU * 440.0 * t) * 0.02
				sample += sin(TAU * 660.0 * t) * 0.015
				sample += sin(TAU * 880.0 * t) * 0.01
			"magma":
				# Deep rumble + crackle
				sample = sin(TAU * 25.0 * t) * 0.08
				if randf() < 0.01:
					sample += (randf() * 2.0 - 1.0) * 0.15
			_:
				# Generic ambient
				sample = sin(TAU * 50.0 * t) * 0.03
		
		sample = clampf(sample, -1.0, 1.0)
		var sample_int := int(sample * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.data = data
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

func _play_3d_sound(stream: AudioStream, position: Vector3, volume_db: float) -> void:
	var player := _get_available_3d_player()
	if player:
		player.stream = stream
		player.global_position = position
		player.volume_db = volume_db
		player.pitch_scale = randf_range(0.95, 1.05)  # Slight variation
		player.play()

func _play_2d_sound(stream: AudioStream, volume_db: float) -> void:
	var player := _get_available_2d_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = randf_range(0.98, 1.02)
		player.play()

func _get_available_3d_player() -> AudioStreamPlayer3D:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# All busy, reuse oldest
	return _sfx_pool[0]

func _get_available_2d_player() -> AudioStreamPlayer:
	for player in _ui_pool:
		if not player.playing:
			return player
	return _ui_pool[0]
