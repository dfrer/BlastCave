extends Node3D
class_name PlacementGhost

## Visual ghost preview for explosive placement positions

@export var valid_color: Color = Color(0.2, 0.9, 0.3, 0.5)
@export var invalid_color: Color = Color(0.9, 0.2, 0.2, 0.5)
@export var shaped_color: Color = Color(0.95, 0.7, 0.1, 0.5)
@export var min_placement_distance: float = 1.5
@export var max_placement_distance: float = 25.0

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _cone_mesh: MeshInstance3D  # For ShapedCharge direction indicator
var _cone_material: StandardMaterial3D
var _current_type: String = "ImpulseCharge"
var _is_valid: bool = true
var _player: Node3D

signal validity_changed(is_valid: bool)

func _ready() -> void:
	_setup_ghost_mesh()
	_setup_cone_indicator()
	hide()

func _setup_ghost_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	_mesh_instance.mesh = sphere
	
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = valid_color
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = _material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)

func _setup_cone_indicator() -> void:
	_cone_mesh = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.6
	cone.height = 1.2
	_cone_mesh.mesh = cone
	
	_cone_material = StandardMaterial3D.new()
	_cone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_material.albedo_color = Color(1.0, 0.8, 0.2, 0.4)
	_cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_mesh.material_override = _cone_material
	_cone_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cone_mesh.rotation_degrees.x = -90  # Point forward
	_cone_mesh.position.z = -0.8
	_cone_mesh.hide()
	add_child(_cone_mesh)

func set_player(player: Node3D) -> void:
	_player = player

func set_explosive_type(type_name: String) -> void:
	_current_type = type_name
	_cone_mesh.visible = type_name == "ShapedCharge"
	_update_appearance()

func update_position(world_pos: Vector3) -> void:
	global_position = world_pos
	_validate_placement()
	_update_appearance()
	show()

func set_aim_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return
	# Rotate ghost to face the aim direction
	var target_pos = global_position + direction
	look_at(target_pos, Vector3.UP)

func hide_ghost() -> void:
	hide()

func is_placement_valid() -> bool:
	return _is_valid

func _validate_placement() -> void:
	if not _player:
		_is_valid = true
		return
	
	var distance = global_position.distance_to(_player.global_position)
	var was_valid = _is_valid
	
	# Check distance bounds
	if distance < min_placement_distance:
		_is_valid = false
	elif distance > max_placement_distance:
		_is_valid = false
	else:
		# Check if position is inside geometry (simple sphere overlap test)
		var space = get_world_3d().direct_space_state
		var query = PhysicsPointQueryParameters3D.new()
		query.position = global_position
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var results = space.intersect_point(query)
		_is_valid = results.is_empty()
	
	if was_valid != _is_valid:
		validity_changed.emit(_is_valid)

func _update_appearance() -> void:
	var color: Color
	if _current_type == "ShapedCharge":
		color = shaped_color if _is_valid else invalid_color
	else:
		color = valid_color if _is_valid else invalid_color
	
	_material.albedo_color = color
	
	# Pulse effect
	var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	_mesh_instance.scale = Vector3.ONE * pulse
