extends ExplosiveBase
class_name ShapedCharge

## Shaped charge applies more force but in a limited cone (forward)
## Features visual cone indicator and optional charge-up for more power

@export var cone_angle: float = 45.0
@export var force_multiplier: float = 2.0
@export var charge_up_enabled: bool = true
@export var max_charge_time: float = 1.5
@export var max_charge_multiplier: float = 2.0
@export var sticky: bool = true  # Sticks to surfaces

var _charge_time: float = 0.0
var _is_charging: bool = false
var _cone_visual: MeshInstance3D
var _stuck_to_surface: bool = false

func _ready() -> void:
	explosive_type = "ShapedCharge"
	_create_cone_visual()

func _process(delta: float) -> void:
	if _is_charging:
		_charge_time = minf(_charge_time + delta, max_charge_time)
		_update_cone_visual()

func _create_cone_visual() -> void:
	# Create a cone mesh to show the blast direction
	_cone_visual = MeshInstance3D.new()
	
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = tan(deg_to_rad(cone_angle)) * blast_radius * 0.5
	cone_mesh.height = blast_radius * 0.5
	_cone_visual.mesh = cone_mesh
	
	# Semi-transparent material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_visual.material_override = mat
	
	# Position cone in front of charge
	_cone_visual.position = Vector3(0, 0, -blast_radius * 0.25)
	_cone_visual.rotation_degrees = Vector3(90, 0, 0)
	
	add_child(_cone_visual)
	_cone_visual.visible = not is_preview

func _update_cone_visual() -> void:
	if not _cone_visual:
		return
	
	# Scale cone based on charge level
	var charge_percent = _charge_time / max_charge_time
	var scale_mult = 1.0 + (charge_percent * 0.5)
	_cone_visual.scale = Vector3(scale_mult, scale_mult, scale_mult)
	
	# Pulse the opacity
	var mat = _cone_visual.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 0.2 + charge_percent * 0.4

func start_charging() -> void:
	_is_charging = true
	_charge_time = 0.0

func stop_charging() -> void:
	_is_charging = false

func get_charge_multiplier() -> float:
	if not charge_up_enabled:
		return 1.0
	var charge_percent = _charge_time / max_charge_time
	return 1.0 + (charge_percent * (max_charge_multiplier - 1.0))

func trigger():
	explode()
	queue_free()

func calculate_impulse(target_pos: Vector3) -> Vector3:
	var to_target = target_pos - global_position
	var dist = to_target.length()
	
	if dist >= blast_radius:
		return Vector3.ZERO
		
	var forward = -global_transform.basis.z
	var dir_to_target = to_target.normalized()
	
	var angle = rad_to_deg(forward.angle_to(dir_to_target))
	
	if angle > cone_angle:
		return Vector3.ZERO
	
	# Apply charge multiplier
	var charge_mult = get_charge_multiplier()
	var strength = (1.0 - (dist / blast_radius)) * blast_force * force_multiplier * charge_mult
	return dir_to_target * strength

## For sticky placement - attach to surfaces
func attach_to_surface(surface_normal: Vector3, surface_point: Vector3) -> void:
	if not sticky:
		return
	
	global_position = surface_point + surface_normal * 0.1
	look_at(global_position - surface_normal, Vector3.UP)
	_stuck_to_surface = true

