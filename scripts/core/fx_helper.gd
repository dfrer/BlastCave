extends Node
class_name FXHelper

static func spawn_burst(parent: Node, position: Vector3, color: Color, amount: int = 24, lifetime: float = 0.6) -> void:
	if parent == null:
		return
	var particles = GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	particles.speed_scale = 1.5
	
	var material = ParticleProcessMaterial.new()
	material.initial_velocity_min = 8.0
	material.initial_velocity_max = 12.0
	material.damping_min = 2.0
	material.damping_max = 4.0
	material.spread = 180.0
	material.direction = Vector3.UP
	material.gravity = Vector3(0, -9.8, 0)
	material.color = color
	material.scale_min = 0.5
	material.scale_max = 1.5
	particles.process_material = material
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.1, 0.1)
	particles.draw_pass_1 = mesh
	
	parent.add_child.call_deferred(particles)
	# Set position after adding to tree
	if parent is Node3D and parent.is_inside_tree():
		particles.set_deferred("global_position", position)
	else:
		particles.position = position
	if parent.get_tree():
		parent.get_tree().create_timer(lifetime + 0.1).timeout.connect(particles.queue_free)

static func spawn_dust(parent: Node, position: Vector3, amount: int = 32) -> void:
	if parent == null:
		return
	var particles = GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true
	
	var material = ParticleProcessMaterial.new()
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, 0.5, 0) # Dust floats up
	material.damping_min = 1.0
	material.damping_max = 2.0
	material.color = Color(0.8, 0.7, 0.6, 0.6)
	material.scale_min = 1.0
	material.scale_max = 3.0
	particles.process_material = material
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	
	# Transparent mat for dust
	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.8, 0.7, 0.6, 0.3)
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = StandardMaterial3D.BILLBOARD_ENABLED
	mesh.material = mat
	
	particles.draw_pass_1 = mesh
	
	parent.add_child.call_deferred(particles)
	# Set position after adding to tree
	if parent is Node3D and parent.is_inside_tree():
		particles.set_deferred("global_position", position)
	else:
		particles.position = position
	if parent.get_tree():
		parent.get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

static func screen_shake(parent: Node, intensity: float) -> void:
	if parent == null: return
	var rig = parent.get_tree().get_root().find_child("CameraRig", true, false)
	if rig and rig.has_method("apply_trauma"):
		rig.apply_trauma(intensity)

static func spawn_sfx(parent: Node, position: Vector3, pitch: float = 1.0) -> void:
	if parent == null:
		return
	var player = AudioStreamPlayer3D.new()
	player.pitch_scale = pitch
	player.volume_db = -8.0
	parent.add_child.call_deferred(player)
	# Set position after adding to tree
	if parent is Node3D and parent.is_inside_tree():
		player.set_deferred("global_position", position)
	else:
		player.position = position
	if parent.get_tree():
		parent.get_tree().create_timer(0.3).timeout.connect(player.queue_free)
