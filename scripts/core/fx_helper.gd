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
	var material = ParticleProcessMaterial.new()
	material.initial_velocity_min = 6.0
	material.initial_velocity_max = 6.0
	material.spread = 180.0
	particles.material = material
	if parent is Node3D:
		particles.position = parent.to_local(position)
	parent.add_child.call_deferred(particles)
	if parent.get_tree():
		parent.get_tree().create_timer(lifetime).timeout.connect(particles.queue_free)

static func spawn_sfx(parent: Node, position: Vector3, pitch: float = 1.0) -> void:
	# Placeholder for audio; hook up real SFX streams in content pipeline.
	# Avoid generating audio frames at runtime to keep script compatible.
	if parent == null:
		return
	var player = AudioStreamPlayer3D.new()
	player.pitch_scale = pitch
	player.volume_db = -8.0
	if parent is Node3D:
		player.position = parent.to_local(position)
	parent.add_child.call_deferred(player)
	if parent.get_tree():
		parent.get_tree().create_timer(0.3).timeout.connect(player.queue_free)
