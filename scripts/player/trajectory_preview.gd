extends Node3D
class_name TrajectoryPreview

var max_steps: int = 30
var step_interval: float = 0.1
var spheres: Array[MeshInstance3D] = []

func _ready():
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.YELLOW
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	for i in range(max_steps):
		var sphere = MeshInstance3D.new()
		sphere.mesh = mesh
		sphere.material_override = mat
		sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sphere)
		sphere.hide()
		spheres.append(sphere)

func update_preview(start_pos: Vector3, initial_velocity: Vector3, gravity: Vector3):
	for i in range(max_steps):
		var t = i * step_interval
		var pos = start_pos + initial_velocity * t + 0.5 * gravity * t * t
		spheres[i].global_position = pos
		spheres[i].show()

func hide_preview():
	for s in spheres:
		s.hide()
