extends Node3D
class_name ExplosiveBase

@export var blast_force: float = 10.0
@export var blast_radius: float = 5.0

var is_preview: bool = false

func explode():
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = blast_radius
	query.shape = sphere
	query.transform = global_transform
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider is RigidBody3D:
			var impulse = calculate_impulse(collider.global_position)
			if impulse != Vector3.ZERO:
				var response = 1.0
				if "blast_response" in collider:
					response = collider.blast_response
				elif collider.has_meta("blast_response"):
					response = collider.get_meta("blast_response")
				
				collider.apply_central_impulse(impulse * response)

# Virtual method to be overridden by subclasses
func calculate_impulse(target_pos: Vector3) -> Vector3:
	var dir = target_pos - global_position
	var dist = dir.length()
	
	if dist >= blast_radius:
		return Vector3.ZERO
		
	if dist < 0.001: dir = Vector3.UP
	
	var strength = (1.0 - (dist / blast_radius)) * blast_force
	return dir.normalized() * strength
