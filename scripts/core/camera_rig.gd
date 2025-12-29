extends Node3D
class_name CameraRig

@export var target_path: NodePath
@export var orbit_speed: float = 0.015
@export var zoom_speed: float = 2.0
@export var min_distance: float = 6.0
@export var max_distance: float = 22.0
@export var occlusion_radius: float = 0.35
@export var follow_lerp: float = 8.0

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D

var _target: Node3D
var _yaw: float = -0.6
var _pitch: float = -0.4
var _distance: float = 14.0
var _dragging: bool = false
var _settings: CameraSettingsState

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
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0)
	elif event is InputEventMouseMotion and _dragging:
		_orbit(event.relative)

func _process(delta: float) -> void:
	if not _target:
		_target = _resolve_target()
		return
	_update_transform(delta)

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
	_pitch = clampf(_pitch, -1.1, -0.1)

func _zoom(direction: float) -> void:
	var speed = zoom_speed
	if _settings:
		speed = _settings.zoom_speed
	_distance = clampf(_distance + direction * speed, min_distance, max_distance)

func _update_transform(delta: float) -> void:
	if not _target:
		return
	var desired_pivot_pos = _target.global_position
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
	query.exclude = [self]
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	if result:
		var hit_pos: Vector3 = result.position
		var normal: Vector3 = result.normal
		return hit_pos + normal * occlusion_radius
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
