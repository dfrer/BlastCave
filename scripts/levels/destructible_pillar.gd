extends StaticBody3D
class_name DestructiblePillar

## A pillar that can be destroyed by explosive damage
## Shows visual damage progression and spawns debris when destroyed

signal destroyed(position: Vector3)

@export var max_health: float = 50.0
@export var debris_count: int = 8

var current_health: float
var _mesh: MeshInstance3D
var _crack_overlay: MeshInstance3D
var _original_material: StandardMaterial3D

func _ready() -> void:
	current_health = max_health
	_mesh = get_node_or_null("Mesh")
	_crack_overlay = get_node_or_null("CrackOverlay")
	
	if _mesh and _mesh.material_override:
		_original_material = _mesh.material_override.duplicate()

## Called by explosives when they deal damage
func take_damage(damage: float, _impulse: Vector3, _hit_position: Vector3) -> void:
	current_health -= damage
	
	# Update visual damage
	_update_damage_visuals()
	
	# Spawn impact effect
	FXHelper.spawn_impact(get_parent(), global_position + Vector3.UP * 2, Vector3.UP, "rock", damage)
	
	if current_health <= 0:
		_destroy()

## Also accept blast impulse for explosive interaction
func apply_blast_impulse(impulse: Vector3) -> void:
	take_damage(impulse.length() * 0.5, impulse, global_position)

func _update_damage_visuals() -> void:
	var damage_percent := 1.0 - (current_health / max_health)
	
	# Show crack overlay at 50% damage
	if _crack_overlay and damage_percent > 0.5:
		_crack_overlay.visible = true
	
	# Darken the material as damage increases
	if _mesh and _mesh.material_override is StandardMaterial3D:
		var mat := _mesh.material_override as StandardMaterial3D
		mat.albedo_color = _original_material.albedo_color.darkened(damage_percent * 0.4)
	
	# Slight shake effect
	if damage_percent > 0.3:
		var shake := Vector3(
			randf_range(-0.05, 0.05),
			0,
			randf_range(-0.05, 0.05)
		)
		position += shake

func _destroy() -> void:
	# Spawn debris particles
	FXHelper.spawn_dust(get_parent(), global_position + Vector3.UP * 2, 48)
	FXHelper.spawn_debris(get_parent(), global_position + Vector3.UP * 2)
	
	# Play destruction sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "rock", 15.0)
	
	# Screen shake
	FXHelper.screen_shake(self, 0.4)
	
	# Spawn debris chunks (static for now - could be RigidBodies)
	_spawn_debris_chunks()
	
	# Emit signal for level logic
	destroyed.emit(global_position)
	
	# Remove the pillar
	queue_free()

func _spawn_debris_chunks() -> void:
	for i in range(debris_count):
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(
			randf_range(0.3, 0.6),
			randf_range(0.2, 0.4),
			randf_range(0.3, 0.6)
		)
		chunk.mesh = box
		
		# Use same material as pillar
		if _original_material:
			chunk.material_override = _original_material.duplicate()
		
		# Random position around pillar
		var offset := Vector3(
			randf_range(-1.5, 1.5),
			randf_range(0, 3),
			randf_range(-1.5, 1.5)
		)
		chunk.global_position = global_position + offset
		chunk.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		get_parent().add_child(chunk)
		
		# Auto-cleanup after a few seconds
		get_tree().create_timer(3.0 + randf()).timeout.connect(chunk.queue_free)
