extends Node
class_name PlayerMovement

@export var move_impulse: float = 8.0
@export var air_control_multiplier: float = 0.35
@export var jump_impulse: float = 6.0
@export var grounded_linear_damp: float = 1.5
@export var airborne_linear_damp: float = 0.1
@export var max_ground_speed: float = 12.0
@export var ground_check_distance: float = 0.6

func apply_movement(body: RigidBody3D, delta: float) -> void:
	if not body:
		return
	var grounded = _is_grounded(body)
	body.linear_damp = grounded_linear_damp if grounded else airborne_linear_damp

	var input_dir = _get_input_direction(body)
	if input_dir != Vector3.ZERO:
		var speed = body.linear_velocity.length()
		var impulse_scale = 1.0
		if grounded:
			if speed > max_ground_speed:
				impulse_scale = 0.2
		else:
			impulse_scale = air_control_multiplier
		var impulse = input_dir.normalized() * move_impulse * impulse_scale * delta
		body.apply_central_impulse(impulse)

	if grounded and Input.is_action_just_pressed("move_jump"):
		body.apply_central_impulse(Vector3.UP * jump_impulse)

func _get_input_direction(body: RigidBody3D) -> Vector3:
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir += -body.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		dir += body.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir += -body.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += body.global_transform.basis.x
	return dir

func _is_grounded(body: RigidBody3D) -> bool:
	var space_state = body.get_world_3d().direct_space_state
	var from = body.global_transform.origin
	var to = from + Vector3.DOWN * ground_check_distance
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [body]
	var result = space_state.intersect_ray(query)
	return not result.is_empty()
