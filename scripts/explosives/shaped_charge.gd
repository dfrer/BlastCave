extends ExplosiveBase
class_name ShapedCharge

# Shaped charge applies more force but in a limited cone (forward)
@export var cone_angle: float = 45.0
@export var force_multiplier: float = 2.0

func trigger():
	explode()
	queue_free()

func calculate_impulse(target_pos: Vector3) -> Vector3:
	var to_target = target_pos - global_position
	var dist = to_target.length()
	
	if dist >= blast_radius:
		return Vector3.ZERO
		
	var forward = -global_transform.basis.z # Godot forward is -Z
	var dir_to_target = to_target.normalized()
	
	var angle = rad_to_deg(forward.angle_to(dir_to_target))
	
	if angle > cone_angle:
		return Vector3.ZERO
		
	var strength = (1.0 - (dist / blast_radius)) * blast_force * force_multiplier
	return dir_to_target * strength
