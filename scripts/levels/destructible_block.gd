extends RigidBody3D
class_name DestructibleBlock

@export var health: float = 20.0
@export var debris_scene: PackedScene

# Add to group "blast_sensitive" to be detected by explosives

func take_damage(amount: float, impulse: Vector3, location: Vector3) -> void:
	health -= amount
	apply_impulse(impulse, location - global_position)
	
	if health <= 0:
		explode()

func explode() -> void:
	if debris_scene:
		# Spawn visual debris
		var debris = debris_scene.instantiate()
		get_parent().add_child(debris)
		debris.global_position = global_position
		debris.global_rotation = global_rotation
	
	queue_free()
