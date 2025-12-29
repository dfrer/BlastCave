extends Node
class_name FXHelper

static func spawn_burst(parent: Node, position: Vector3, color: Color, amount: int = 16, lifetime: float = 0.6) -> void:
	if parent == null:
		return
	var particles = CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.speed_scale = 2.0
	particles.color = color
	particles.initial_velocity = 6.0
	particles.spread = 180.0
	particles.global_position = position
	parent.add_child(particles)
	parent.get_tree().create_timer(lifetime).timeout.connect(particles.queue_free)

static func spawn_sfx(parent: Node, position: Vector3, pitch: float = 1.0) -> void:
	if parent == null:
		return
	var player = AudioStreamPlayer3D.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.2
	player.stream = generator
	player.pitch_scale = pitch
	player.volume_db = -8.0
	player.global_position = position
	parent.add_child(player)
	player.play()
	var playback = player.get_stream_playback()
	if playback:
		var sample_count = int(generator.mix_rate * 0.15)
		for i in range(sample_count):
			var t = float(i) / generator.mix_rate
			var sample = sin(t * TAU * 440.0 * pitch) * 0.15
			playback.push_frame(AudioFrame(sample, sample))
	parent.get_tree().create_timer(0.3).timeout.connect(player.queue_free)
