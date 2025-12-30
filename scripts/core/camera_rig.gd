extends Node3D
class_name CameraRig

## Enhanced camera rig with auto-zoom, look-ahead, and quick-snap features

@export var target_path: NodePath
@export var orbit_speed: float = 0.015
@export var zoom_speed: float = 2.0
@export var min_distance: float = 6.0
@export var max_distance: float = 22.0
@export var occlusion_radius: float = 0.35
@export var follow_lerp: float = 8.0

# Auto-zoom based on velocity
@export var auto_zoom_enabled: bool = true
@export var velocity_zoom_threshold: float = 8.0  # Speed at which zoom starts
@export var auto_zoom_lerp: float = 2.0

# Look-ahead toward movement direction
@export var look_ahead_enabled: bool = true
@export var look_ahead_strength: float = 3.0
@export var look_ahead_lerp: float = 4.0

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D

var _target: Node3D
var _yaw: float = -0.6
var _pitch: float = -0.4
var _distance: float = 14.0
var _target_distance: float = 14.0  # For auto-zoom smoothing
var _dragging: bool = false
var _settings: CameraSettingsState
var _look_ahead_offset: Vector3 = Vector3.ZERO
var _manual_zoom_override: bool = false
var _manual_zoom_timer: float = 0.0

# Shake properties
var _trauma: float = 0.0
@export var trauma_reduction: float = 0.8
@export var max_shake_offset: float = 0.5
@export var max_shake_rotation: float = 0.1

func _ready() -> void:
	camera.current = true
	_target = _resolve_target()
	_settings = get_tree().get_root().find_child("CameraSettingsState", true, false) as CameraSettingsState
	if _settings:
		_apply_settings(_settings)
		_settings.settings_changed.connect(_on_settings_changed)
	_update_transform(0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-1.0)
			_manual_zoom_override = true
			_manual_zoom_timer = 2.0  # Override auto-zoom for 2 seconds
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0)
			_manual_zoom_override = true
			_manual_zoom_timer = 2.0
	elif event is InputEventMouseMotion and _dragging:
		_orbit(event.relative)
	
	# Quick-snap to behind player on C key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			_snap_behind_player()

func _process(delta: float) -> void:
	if not _target:
		_target = _resolve_target()
		return
	
	# Handle manual zoom override timer
	if _manual_zoom_override:
		_manual_zoom_timer -= delta
		if _manual_zoom_timer <= 0:
			_manual_zoom_override = false
	
	if _trauma > 0:
		_trauma = max(_trauma - trauma_reduction * delta, 0.0)
		_apply_shake()
	else:
		# Reset camera offsets when no trauma
		camera.h_offset = 0
		camera.v_offset = 0
		camera.rotation.z = 0
	
	_update_auto_zoom(delta)
	_update_look_ahead(delta)
	_update_transform(delta)

func apply_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _apply_shake() -> void:
	var shake = _trauma * _trauma
	var offset = Vector2(
		randf_range(-1.0, 1.0) * max_shake_offset * shake,
		randf_range(-1.0, 1.0) * max_shake_offset * shake
	)
	var rot = randf_range(-1.0, 1.0) * max_shake_rotation * shake
	
	camera.h_offset = offset.x
	camera.v_offset = offset.y
	camera.rotation.z = rot

func _resolve_target() -> Node3D:
	if target_path != NodePath():
		return get_node_or_null(target_path) as Node3D
	return get_tree().get_root().find_child("PlayerObject", true, false) as Node3D

func _orbit(relative: Vector2) -> void:
	var sensitivity = orbit_speed
	if _settings:
		sensitivity = _settings.orbit_sensitivity
	_yaw -= relative.x * sensitivity
	_pitch -= relative.y * sensitivity
	_pitch = clampf(_pitch, -1.50, 1.50)

func _zoom(direction: float) -> void:
	var speed = zoom_speed
	if _settings:
		speed = _settings.zoom_speed
	_target_distance = clampf(_target_distance + direction * speed, min_distance, max_distance)

func _update_auto_zoom(delta: float) -> void:
	if not auto_zoom_enabled or _manual_zoom_override:
		_distance = lerpf(_distance, _target_distance, delta * auto_zoom_lerp)
		return
	
	if not _target:
		return
	
	# Get velocity if target is a RigidBody3D
	var velocity = Vector3.ZERO
	if _target is RigidBody3D:
		velocity = _target.linear_velocity
	elif _target.has_method("get_velocity"):
		velocity = _target.get_velocity()
	
	var speed = velocity.length()
	
	# Calculate target distance based on speed
	var speed_factor = clampf((speed - velocity_zoom_threshold) / 15.0, 0.0, 1.0)
	var auto_distance = lerpf(min_distance + 2.0, max_distance, speed_factor)
	
	# Blend between manual target and auto distance
	var desired_distance = maxf(_target_distance, auto_distance)
	_distance = lerpf(_distance, desired_distance, delta * auto_zoom_lerp)

func _update_look_ahead(delta: float) -> void:
	if not look_ahead_enabled or not _target:
		_look_ahead_offset = _look_ahead_offset.lerp(Vector3.ZERO, delta * look_ahead_lerp)
		return
	
	# Get velocity
	var velocity = Vector3.ZERO
	if _target is RigidBody3D:
		velocity = _target.linear_velocity
	elif _target.has_method("get_velocity"):
		velocity = _target.get_velocity()
	
	# Only use horizontal velocity for look-ahead
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal_vel.length()
	
	if speed > 0.5:
		var look_ahead_dir = horizontal_vel.normalized()
		var look_ahead_amount = clampf(speed * 0.15, 0.0, look_ahead_strength)
		var target_offset = look_ahead_dir * look_ahead_amount
		_look_ahead_offset = _look_ahead_offset.lerp(target_offset, delta * look_ahead_lerp)
	else:
		_look_ahead_offset = _look_ahead_offset.lerp(Vector3.ZERO, delta * look_ahead_lerp)

func _snap_behind_player() -> void:
	if not _target:
		return
	
	# Get player's forward direction (use velocity if moving, otherwise current yaw)
	var forward = Vector3.ZERO
	if _target is RigidBody3D:
		var vel = _target.linear_velocity
		if vel.length() > 1.0:
			forward = -Vector3(vel.x, 0, vel.z).normalized()
	
	if forward.length_squared() > 0.1:
		_yaw = atan2(forward.x, forward.z)
	
	# Reset to comfortable viewing distance
	_target_distance = (min_distance + max_distance) * 0.5
	_pitch = -0.5

func _update_transform(delta: float) -> void:
	if not _target:
		return
	
	var desired_pivot_pos = _target.global_position + _look_ahead_offset
	if delta > 0.0:
		global_position = global_position.lerp(desired_pivot_pos, clampf(delta * follow_lerp, 0.0, 1.0))
	else:
		global_position = desired_pivot_pos

	pivot.rotation = Vector3(_pitch, _yaw, 0.0)
	var desired_offset = -pivot.global_transform.basis.z * _distance
	var desired_camera_pos = global_position + desired_offset
	camera.global_position = _resolve_occlusion(global_position, desired_camera_pos)
	if not camera.global_position.is_equal_approx(global_position):
		camera.look_at(global_position, Vector3.UP)

func _resolve_occlusion(origin: Vector3, desired: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, desired)
	query.exclude = [self, _target]
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	if result:
		var hit_pos: Vector3 = result.position
		# Pull back towards the origin (pivot/target) slightly
		return hit_pos.move_toward(origin, occlusion_radius)
	return desired

func _on_settings_changed() -> void:
	_apply_settings(_settings)

func _apply_settings(settings: CameraSettingsState) -> void:
	if not settings:
		return
	orbit_speed = settings.orbit_sensitivity
	zoom_speed = settings.zoom_speed
	min_distance = settings.min_distance
	max_distance = settings.max_distance
