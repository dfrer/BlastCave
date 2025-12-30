extends Node
class_name PlayerMovement

@export var move_impulse: float = 8.0
@export var air_control_multiplier: float = 0.35
@export var jump_impulse: float = 6.0
@export var grounded_linear_damp: float = 1.5
@export var airborne_linear_damp: float = 0.1
@export var max_ground_speed: float = 12.0
@export var ground_check_distance: float = 0.6
@export var use_camera_relative: bool = true

var _was_grounded: bool = true
var _vertical_velocity_at_impact: float = 0.0

func apply_movement(body: RigidBody3D, delta: float) -> void:
	if not body:
		return
	var grounded = _is_grounded(body)
	body.linear_damp = grounded_linear_damp if grounded else airborne_linear_damp

	# Handle landing FX
	if grounded and not _was_grounded:
		var impact_speed = abs(_vertical_velocity_at_impact)
		if impact_speed > 5.0:
			FXHelper.spawn_dust(body, body.global_position)
			FXHelper.screen_shake(body, impact_speed * 0.04)
	
	_was_grounded = grounded
	if not grounded:
		_vertical_velocity_at_impact = body.linear_velocity.y

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
	var forward: Vector3
	var right: Vector3
	
	if use_camera_relative:
		# Get camera and use its horizontal direction (ignore pitch)
		var camera = body.get_viewport().get_camera_3d()
		if camera:
			var cam_basis = camera.global_transform.basis
			forward = -Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
			right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		else:
			# Fallback if no camera
			forward = -body.global_transform.basis.z
			right = body.global_transform.basis.x
	else:
		# Body-relative (legacy behavior)
		forward = -body.global_transform.basis.z
		right = body.global_transform.basis.x
	
	if Input.is_action_pressed("move_forward"):
		dir += forward
	if Input.is_action_pressed("move_back"):
		dir -= forward
	if Input.is_action_pressed("move_left"):
		dir -= right
	if Input.is_action_pressed("move_right"):
		dir += right
	return dir

func _is_grounded(body: RigidBody3D) -> bool:
	var space_state = body.get_world_3d().direct_space_state
	var from = body.global_transform.origin
	var to = from + Vector3.DOWN * ground_check_distance
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [body]
	var result = space_state.intersect_ray(query)
	return not result.is_empty()
