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
	# Placeholder for audio; hook up real SFX streams in content pipeline.
	# Avoid generating audio frames at runtime to keep script compatible.
	if parent == null:
		return
	var player = AudioStreamPlayer3D.new()
	player.pitch_scale = pitch
	player.volume_db = -8.0
	player.global_position = position
	parent.add_child(player)
	parent.get_tree().create_timer(0.3).timeout.connect(player.queue_free)
