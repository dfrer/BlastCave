extends ExplosiveBase
class_name RepulsorCharge

## Repulsor charge that pushes everything AWAY from the center
## Useful for clearing enemies or creating space

@export var push_multiplier: float = 1.5
@export var lift_bias: float = 0.3  # Extra upward push

func _ready() -> void:
	explosive_type = "RepulsorCharge"
	blast_force = 12.0
	blast_radius = 6.0
	falloff_power = 1.0  # Linear falloff for more even push
	upward_bias = 0.0  # We handle this ourselves

func calculate_impulse(target_pos: Vector3) -> Vector3:
	var dir = target_pos - global_position
	var dist = dir.length()
	
	if dist >= blast_radius:
		return Vector3.ZERO
	
	if dist < 0.001:
		dir = Vector3.UP
		dist = 0.001
	
	var direction = dir.normalized()
	
	# Add extra lift to make it feel more "repulsive"
	direction = direction.lerp(Vector3.UP, lift_bias).normalized()
	
	# Linear falloff for more consistent push
	var normalized_dist = dist / blast_radius
	var strength = (1.0 - normalized_dist) * blast_force * push_multiplier
	
	return direction * strength

func explode() -> void:
	# Custom explosion with unique visuals
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = blast_radius
	query.shape = sphere
	query.transform = global_transform
	query.collide_with_areas = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider:
			var impulse = calculate_impulse(collider.global_position)
			if impulse.length() > MIN_IMPULSE_THRESHOLD:
				var response = 1.0
				if "blast_response" in collider:
					response = collider.blast_response
				elif collider.has_meta("blast_response"):
					response = collider.get_meta("blast_response")
				
				var final_impulse = impulse * response
				if collider is RigidBody3D:
					collider.apply_central_impulse(final_impulse)
				elif collider.has_method("apply_blast_impulse_with_type"):
					collider.apply_blast_impulse_with_type(final_impulse, explosive_type)
				elif collider.has_method("apply_blast_impulse"):
					collider.apply_blast_impulse(final_impulse)
	
	# Unique repulsor visual - expanding ring effect
	FXHelper.spawn_explosion(get_parent(), global_position, explosive_type)
	
	# Extra ring particles for the repulsor effect
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_dust(get_parent(), global_position, 32)
	
	FXHelper.screen_shake(self, blast_force * 0.04)
