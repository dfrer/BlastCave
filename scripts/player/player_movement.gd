extends Node
class_name PlayerMovement

## Rolling-focused movement controller
## Walking is heavily nerfed - player should use explosives to move
## Jump is a tiny nudge for micro-adjustments only

# Movement tuning - HEAVILY NERFED for rolling-based gameplay
@export var nudge_impulse: float = 0.8  # Tiny nudge force (was move_impulse = 5.0)
@export var air_control_multiplier: float = 0.1  # Minimal air control (was 0.25)
@export var hop_impulse: float = 3.0  # Tiny hop for repositioning (was jump_impulse = 7.0)
@export var grounded_linear_damp: float = 0.8  # Lower damp for momentum (was 2.5)
@export var airborne_linear_damp: float = 0.02  # Very low air damp (was 0.05)
@export var ground_check_distance: float = 0.55  # Adjusted for sphere
@export var use_camera_relative: bool = true

# Rolling momentum - NEW for blast-propulsion gameplay
@export var momentum_preservation: float = 0.99  # How much speed is kept per frame when rolling
@export var slope_assist_strength: float = 2.0  # Extra push when going uphill
@export var roll_friction_base: float = 0.15  # Base rolling resistance
@export var speed_friction_reduction: float = 0.4  # Friction reduction at high speed

# Micro-hop for repositioning (replaces jump)
@export var hop_buffer_time: float = 0.08
var _hop_buffer_timer: float = 0.0
var _hop_cooldown: float = 0.0
const HOP_COOLDOWN_TIME: float = 0.5

var _was_grounded: bool = true
var _vertical_velocity_at_impact: float = 0.0

signal landed(impact_velocity: float)

func apply_movement(body: RigidBody3D, delta: float) -> void:
	if not body:
		return
	
	var grounded = _is_grounded(body)
	
	# Rolling momentum system - preserve speed
	_apply_momentum_physics(body, grounded, delta)
	
	# Handle landing FX
	if grounded and not _was_grounded:
		var impact_speed = abs(_vertical_velocity_at_impact)
		if impact_speed > 6.0:
			FXHelper.spawn_dust(body, body.global_position)
			FXHelper.screen_shake(body, impact_speed * 0.03)
		landed.emit(impact_speed)
		# Consume buffered hop on landing
		if _hop_buffer_timer > 0:
			_execute_hop(body)
	
	_was_grounded = grounded
	if not grounded:
		_vertical_velocity_at_impact = body.linear_velocity.y
	
	# Update hop cooldown
	if _hop_cooldown > 0:
		_hop_cooldown -= delta
	
	# Track hop buffer input
	if Input.is_action_just_pressed("move_jump"):
		_hop_buffer_timer = hop_buffer_time
	elif _hop_buffer_timer > 0:
		_hop_buffer_timer -= delta
	
	# MINIMAL nudge movement - player should use explosives for real movement
	var input_dir = _get_input_direction(body)
	if input_dir != Vector3.ZERO:
		var speed = body.linear_velocity.length()
		var impulse_scale: float
		
		if grounded:
			# Very weak ground nudge - just for micro-adjustments
			if speed > 3.0:
				impulse_scale = 0.1  # Almost no force when already moving
			else:
				impulse_scale = 1.0  # Full (but weak) nudge when stopped
		else:
			impulse_scale = air_control_multiplier  # Minimal air control
		
		var impulse = input_dir.normalized() * nudge_impulse * impulse_scale * delta
		body.apply_central_impulse(impulse)
	
	# Tiny hop for repositioning only (NOT a real jump)
	if Input.is_action_just_pressed("move_jump") and grounded and _hop_cooldown <= 0:
		_execute_hop(body)

func _execute_hop(body: RigidBody3D) -> void:
	# Tiny hop - not a real jump, just for small repositioning
	if body.linear_velocity.y < 0:
		body.linear_velocity.y = 0
	
	body.apply_central_impulse(Vector3.UP * hop_impulse)
	_hop_buffer_timer = 0.0
	_hop_cooldown = HOP_COOLDOWN_TIME

func _apply_momentum_physics(body: RigidBody3D, grounded: bool, delta: float) -> void:
	## Rolling momentum - key to the blast-propulsion gameplay
	
	var speed = body.linear_velocity.length()
	var horizontal_velocity = Vector3(body.linear_velocity.x, 0, body.linear_velocity.z)
	
	if grounded:
		# Apply rolling friction (but preserve momentum)
		var friction = roll_friction_base
		if speed > 8.0:
			# Reduce friction at high speeds - momentum is king
			var speed_factor = clampf((speed - 8.0) / 20.0, 0.0, speed_friction_reduction)
			friction *= (1.0 - speed_factor)
		
		# Very gentle friction application
		body.linear_damp = grounded_linear_damp * friction
		
		# Slope assist - help roll uphill with momentum
		if speed > 2.0:
			var ground_normal = _get_ground_normal(body)
			if ground_normal != Vector3.ZERO:
				var slope_factor = 1.0 - ground_normal.y  # 0 = flat, 1 = wall
				if slope_factor > 0.1 and horizontal_velocity.length() > 1.0:
					# Going uphill - add assist
					var assist_dir = horizontal_velocity.normalized()
					var assist = assist_dir * slope_assist_strength * slope_factor * delta
					body.apply_central_impulse(assist)
	else:
		# Airborne - very low damping to maintain launch momentum
		body.linear_damp = airborne_linear_damp

func _get_input_direction(body: RigidBody3D) -> Vector3:
	var dir = Vector3.ZERO
	var forward: Vector3
	var right: Vector3
	
	if use_camera_relative:
		var camera = body.get_viewport().get_camera_3d()
		if camera:
			var cam_basis = camera.global_transform.basis
			forward = -Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
			right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		else:
			forward = -body.global_transform.basis.z
			right = body.global_transform.basis.x
	else:
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

func _get_ground_normal(body: RigidBody3D) -> Vector3:
	var space_state = body.get_world_3d().direct_space_state
	var from = body.global_transform.origin
	var to = from + Vector3.DOWN * ground_check_distance * 1.2
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [body]
	var result = space_state.intersect_ray(query)
	if result:
		return result.normal
	return Vector3.ZERO

func is_grounded(body: RigidBody3D) -> bool:
	return _is_grounded(body)
