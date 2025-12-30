extends Node3D
class_name ExplosiveBase

## Base class for all explosives with tunable physics properties

@export var blast_force: float = 25.0  # Increased for blast-propulsion (was 10.0)
@export var blast_radius: float = 7.0  # Larger radius for easier self-launching (was 5.0)
@export var explosive_type: String = "ImpulseCharge"

# Blast tuning - optimized for rolling/launching gameplay
## Falloff curve power - 1.5 = smoother falloff for more consistent launches (was 2.0)
@export var falloff_power: float = 1.5
## Minimum distance for full-power blast (prevents point-blank issues)
@export var inner_radius: float = 0.3  # Smaller inner radius for more power zone
## Minimum impulse strength (blasts below this are ignored)
const MIN_IMPULSE_THRESHOLD: float = 0.3
## Optional upward bias - helps with launches (was 0.15)
@export var upward_bias: float = 0.25

var is_preview: bool = false

func trigger() -> void:
	if is_preview:
		return
	explode()
	queue_free()

func explode():
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
				
				# Apply damage to destructibles
				if collider.has_method("take_damage"):
					# Damage based on impulse magnitude
					var damage = final_impulse.length() * 0.5
					collider.take_damage(damage, final_impulse, collider.global_position)

	FXHelper.spawn_explosion(get_parent(), global_position, explosive_type)
	
	# Trigger screen shake based on blast force
	FXHelper.screen_shake(self, blast_force * 0.05)

## Calculate impulse applied to a target at given position
## Uses quadratic falloff for more realistic and controllable explosions
func calculate_impulse(target_pos: Vector3) -> Vector3:
	var dir = target_pos - global_position
	var dist = dir.length()
	
	# Outside blast radius - no effect
	if dist >= blast_radius:
		return Vector3.ZERO
	
	# Handle point-blank / degenerate cases
	if dist < 0.001:
		dir = Vector3.UP
		dist = 0.001
	
	# Normalize direction
	var direction = dir.normalized()
	
	# Apply upward bias for more predictable, game-y feel
	if upward_bias > 0.0:
		direction = direction.lerp(Vector3.UP, upward_bias).normalized()
	
	# Calculate falloff with inner radius (full power zone)
	var effective_dist = maxf(dist - inner_radius, 0.0)
	var effective_radius = blast_radius - inner_radius
	
	# Quadratic falloff: strength drops off faster at edges
	# normalized_dist goes from 0 (close) to 1 (at edge)
	var normalized_dist = effective_dist / effective_radius
	
	# Apply falloff curve: pow(1 - normalized_dist, falloff_power)
	# Higher falloff_power = more concentrated blast
	var falloff = pow(1.0 - normalized_dist, falloff_power)
	
	var strength = falloff * blast_force
	
	return direction * strength
