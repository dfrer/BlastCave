extends Node
class_name BouncySurface

## Bouncy surface that makes walls and floors bouncy
## Attach to a StaticBody3D with collision

@export var bounce_coefficient: float = 0.7  # How much velocity is preserved on bounce
@export var surface_type: String = "crystal"  # "rubber", "crystal", "metal"
@export var min_bounce_speed: float = 3.0  # Minimum speed to trigger bounce effect
@export var visual_glow: bool = true

var _parent_body: StaticBody3D
var _physics_material: PhysicsMaterial

# Surface type presets
const SURFACE_PRESETS = {
	"rubber": {"bounce": 0.8, "friction": 0.6, "color": Color(0.2, 0.7, 0.3)},
	"crystal": {"bounce": 0.7, "friction": 0.2, "color": Color(0.3, 0.8, 1.0)},
	"metal": {"bounce": 0.5, "friction": 0.3, "color": Color(0.7, 0.7, 0.8)},
	"slime": {"bounce": 0.9, "friction": 0.1, "color": Color(0.5, 0.9, 0.3)}
}

func _ready() -> void:
	_parent_body = get_parent() as StaticBody3D
	if not _parent_body:
		push_warning("BouncySurface must be a child of StaticBody3D")
		return
	
	_apply_surface_properties()

func _apply_surface_properties() -> void:
	if not _parent_body:
		return
	
	# Get preset or use defaults
	var preset = SURFACE_PRESETS.get(surface_type, SURFACE_PRESETS["crystal"])
	
	# Create physics material with bounce
	_physics_material = PhysicsMaterial.new()
	_physics_material.bounce = preset.bounce if bounce_coefficient <= 0 else bounce_coefficient
	_physics_material.friction = preset.friction
	_parent_body.physics_material_override = _physics_material
	
	# Apply visual glow if enabled
	if visual_glow:
		_apply_visual_glow(preset.color)

func _apply_visual_glow(color: Color) -> void:
	# Find all MeshInstance3D children and add emissive tint
	for child in _parent_body.get_children():
		if child is MeshInstance3D:
			_tint_mesh(child, color)

func _tint_mesh(mesh_instance: MeshInstance3D, color: Color) -> void:
	var current_mat = mesh_instance.get_active_material(0)
	if current_mat is StandardMaterial3D:
		var new_mat = current_mat.duplicate() as StandardMaterial3D
		new_mat.emission_enabled = true
		new_mat.emission = color
		new_mat.emission_energy_multiplier = 1.2
		# Blend the albedo with the glow color
		new_mat.albedo_color = new_mat.albedo_color.lerp(color, 0.3)
		mesh_instance.material_override = new_mat
