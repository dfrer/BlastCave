extends Node
class_name MaterialLibrary

## Centralized PBR material library for consistent visual quality
## Provides properly configured materials with roughness, metallic, and emission

# Singleton access
static var instance: MaterialLibrary

# Material caches
var _base_materials: Dictionary = {}
var _emissive_materials: Dictionary = {}
var _special_materials: Dictionary = {}

# Color palettes for each biome/material type
const PALETTE := {
	"rock": {
		"base": Color(0.35, 0.32, 0.28),
		"dark": Color(0.22, 0.20, 0.18),
		"light": Color(0.5, 0.46, 0.40),
		"accent": Color(0.45, 0.35, 0.25),
	},
	"metal": {
		"base": Color(0.55, 0.55, 0.58),
		"dark": Color(0.35, 0.35, 0.38),
		"light": Color(0.75, 0.75, 0.78),
		"rust": Color(0.6, 0.35, 0.2),
	},
	"crystal": {
		"base": Color(0.4, 0.6, 0.8),
		"dark": Color(0.2, 0.35, 0.55),
		"light": Color(0.7, 0.85, 0.95),
		"glow": Color(0.5, 0.8, 1.0),
	},
	"organic": {
		"base": Color(0.4, 0.55, 0.35),
		"dark": Color(0.25, 0.35, 0.22),
		"light": Color(0.55, 0.7, 0.45),
		"accent": Color(0.6, 0.5, 0.3),
	},
	"toxic": {
		"base": Color(0.3, 0.5, 0.25),
		"glow": Color(0.4, 0.9, 0.3),
		"dark": Color(0.2, 0.3, 0.15),
		"accent": Color(0.8, 0.9, 0.2),
	},
	"magma": {
		"base": Color(0.4, 0.25, 0.2),
		"glow": Color(1.0, 0.5, 0.1),
		"dark": Color(0.25, 0.15, 0.1),
		"hot": Color(1.0, 0.8, 0.3),
	},
	"ice": {
		"base": Color(0.7, 0.85, 0.95),
		"dark": Color(0.4, 0.55, 0.7),
		"light": Color(0.9, 0.95, 1.0),
		"glow": Color(0.6, 0.9, 1.0),
	},
}

# Explosive type colors
const EXPLOSIVE_COLORS := {
	"ImpulseCharge": Color(1.0, 0.7, 0.2),
	"ShapedCharge": Color(0.2, 0.8, 1.0),
	"DelayedCharge": Color(0.9, 0.3, 0.6),
	"ClusterCharge": Color(0.6, 1.0, 0.4),
	"RepulsorCharge": Color(0.8, 0.4, 1.0),
}

func _ready() -> void:
	instance = self
	_generate_base_materials()
	_generate_emissive_materials()
	_generate_special_materials()

# === MATERIAL GENERATION ===

func _generate_base_materials() -> void:
	# Rock materials - rough, non-metallic surfaces
	_base_materials["rock_base"] = _create_pbr_material(
		PALETTE.rock.base, 0.85, 0.0, 0.0
	)
	_base_materials["rock_dark"] = _create_pbr_material(
		PALETTE.rock.dark, 0.9, 0.0, 0.0
	)
	_base_materials["rock_light"] = _create_pbr_material(
		PALETTE.rock.light, 0.75, 0.0, 0.0
	)
	_base_materials["rock_mossy"] = _create_pbr_material(
		PALETTE.rock.base.lerp(PALETTE.organic.base, 0.3), 0.8, 0.0, 0.0
	)
	
	# Metal materials - smooth to rough, metallic
	_base_materials["metal_clean"] = _create_pbr_material(
		PALETTE.metal.light, 0.3, 0.9, 0.0
	)
	_base_materials["metal_worn"] = _create_pbr_material(
		PALETTE.metal.dark, 0.6, 0.7, 0.0
	)
	_base_materials["metal_rusted"] = _create_pbr_material(
		PALETTE.metal.rust, 0.85, 0.3, 0.0
	)
	_base_materials["metal_grate"] = _create_pbr_material(
		PALETTE.metal.base, 0.5, 0.8, 0.0
	)
	
	# Crystal materials - smooth, slightly translucent feel
	_base_materials["crystal_base"] = _create_pbr_material(
		PALETTE.crystal.base, 0.15, 0.2, 0.0
	)
	_base_materials["crystal_dark"] = _create_pbr_material(
		PALETTE.crystal.dark, 0.2, 0.3, 0.0
	)
	
	# Organic materials
	_base_materials["organic_vine"] = _create_pbr_material(
		PALETTE.organic.base, 0.7, 0.0, 0.0
	)
	_base_materials["organic_fungus"] = _create_pbr_material(
		PALETTE.organic.light, 0.6, 0.0, 0.0
	)
	
	# Floor/ceiling specific
	_base_materials["floor_stone"] = _create_pbr_material(
		PALETTE.rock.dark, 0.85, 0.05, 0.0
	)
	_base_materials["ceiling_rock"] = _create_pbr_material(
		PALETTE.rock.base.darkened(0.2), 0.9, 0.0, 0.0
	)

func _generate_emissive_materials() -> void:
	# Crystal glow materials
	_emissive_materials["crystal_glow_blue"] = _create_emissive_material(
		PALETTE.crystal.glow, 2.0
	)
	_emissive_materials["crystal_glow_purple"] = _create_emissive_material(
		Color(0.7, 0.4, 1.0), 2.0
	)
	
	# Toxic glow
	_emissive_materials["toxic_glow"] = _create_emissive_material(
		PALETTE.toxic.glow, 1.5
	)
	_emissive_materials["toxic_pool"] = _create_emissive_material(
		PALETTE.toxic.glow, 0.8
	)
	
	# Magma/lava
	_emissive_materials["magma_glow"] = _create_emissive_material(
		PALETTE.magma.glow, 3.0
	)
	_emissive_materials["magma_hot"] = _create_emissive_material(
		PALETTE.magma.hot, 4.0
	)
	_emissive_materials["lava_surface"] = _create_emissive_material(
		PALETTE.magma.glow.lerp(PALETTE.magma.hot, 0.5), 2.5
	)
	
	# Hazard indicators
	_emissive_materials["hazard_red"] = _create_emissive_material(
		Color(1.0, 0.2, 0.2), 2.0
	)
	_emissive_materials["hazard_yellow"] = _create_emissive_material(
		Color(1.0, 0.9, 0.2), 1.5
	)
	
	# Interactive element highlights
	_emissive_materials["switch_active"] = _create_emissive_material(
		Color(0.2, 1.0, 0.4), 2.0
	)
	_emissive_materials["switch_inactive"] = _create_emissive_material(
		Color(1.0, 0.3, 0.2), 1.0
	)
	
	# Explosive type materials
	for type_name in EXPLOSIVE_COLORS:
		var color = EXPLOSIVE_COLORS[type_name]
		_emissive_materials["explosive_%s" % type_name.to_lower()] = _create_emissive_material(
			color, 2.5
		)

func _generate_special_materials() -> void:
	# Transparent/glass-like
	_special_materials["glass_dirty"] = _create_transparent_material(
		Color(0.8, 0.8, 0.85, 0.3), 0.1, 0.0
	)
	_special_materials["glass_clean"] = _create_transparent_material(
		Color(0.9, 0.95, 1.0, 0.15), 0.05, 0.1
	)
	
	# Force field / energy barriers
	_special_materials["energy_barrier"] = _create_energy_material(
		Color(0.3, 0.7, 1.0), 1.5
	)
	
	# Wet surfaces
	_special_materials["rock_wet"] = _create_pbr_material(
		PALETTE.rock.dark, 0.3, 0.1, 0.0  # Much less rough when wet
	)
	
	# Damaged/cracked
	_special_materials["rock_damaged"] = _create_pbr_material(
		PALETTE.rock.base.lerp(Color(0.2, 0.15, 0.1), 0.3), 0.9, 0.0, 0.0
	)

# === MATERIAL FACTORY FUNCTIONS ===

func _create_pbr_material(color: Color, roughness: float, metallic: float, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = clampf(roughness, 0.0, 1.0)
	mat.metallic = clampf(metallic, 0.0, 1.0)
	
	# Add subtle variation with noise (if Godot supports it)
	mat.metallic_specular = 0.5
	
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	
	# Optimize for performance
	mat.resource_local_to_scene = true
	
	return mat

func _create_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.3)
	mat.roughness = 0.5
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.resource_local_to_scene = true
	return mat

func _create_transparent_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.resource_local_to_scene = true
	return mat

func _create_energy_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.resource_local_to_scene = true
	return mat

# === PUBLIC API ===

## Get a base PBR material by name
func get_base(material_name: String) -> StandardMaterial3D:
	if _base_materials.has(material_name):
		return _base_materials[material_name].duplicate() as StandardMaterial3D
	push_warning("MaterialLibrary: Base material '%s' not found, using rock_base" % material_name)
	return _base_materials.get("rock_base", StandardMaterial3D.new()).duplicate()

## Get an emissive material by name
func get_emissive(material_name: String) -> StandardMaterial3D:
	if _emissive_materials.has(material_name):
		return _emissive_materials[material_name].duplicate() as StandardMaterial3D
	push_warning("MaterialLibrary: Emissive material '%s' not found" % material_name)
	return _emissive_materials.get("crystal_glow_blue", StandardMaterial3D.new()).duplicate()

## Get a special material by name
func get_special(material_name: String) -> StandardMaterial3D:
	if _special_materials.has(material_name):
		return _special_materials[material_name].duplicate() as StandardMaterial3D
	push_warning("MaterialLibrary: Special material '%s' not found" % material_name)
	return StandardMaterial3D.new()

## Get material for explosive type
func get_explosive_material(explosive_type: String) -> StandardMaterial3D:
	var key = "explosive_%s" % explosive_type.to_lower()
	return get_emissive(key)

## Get color for explosive type (for particles, UI, etc)
func get_explosive_color(explosive_type: String) -> Color:
	return EXPLOSIVE_COLORS.get(explosive_type, Color(1.0, 0.7, 0.2))

## Create a biome-tinted version of a material
func get_biome_tinted(base_material_name: String, biome: String, blend: float = 0.3) -> StandardMaterial3D:
	var mat = get_base(base_material_name)
	if PALETTE.has(biome):
		var biome_color: Color = PALETTE[biome].get("base", Color.WHITE)
		mat.albedo_color = mat.albedo_color.lerp(biome_color, blend)
	return mat

## Apply depth-based biome coloring to a node recursively
func apply_biome_to_node(node: Node, depth: int) -> void:
	var biome := _get_biome_for_depth(depth)
	_apply_biome_recursive(node, biome)

func _get_biome_for_depth(depth: int) -> String:
	if depth < 2:
		return "rock"
	elif depth < 4:
		return "toxic"
	elif depth < 6:
		return "crystal"
	else:
		return "magma"

func _apply_biome_recursive(node: Node, biome: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mat = mesh_instance.get_active_material(0)
		if mat is StandardMaterial3D:
			var new_mat := mat.duplicate() as StandardMaterial3D
			if PALETTE.has(biome):
				var biome_color: Color = PALETTE[biome].get("base", Color.WHITE)
				new_mat.albedo_color = new_mat.albedo_color.lerp(biome_color, 0.25)
				if new_mat.emission_enabled and PALETTE[biome].has("glow"):
					new_mat.emission = new_mat.emission.lerp(PALETTE[biome].glow, 0.4)
			mesh_instance.material_override = new_mat
	
	if node is Light3D:
		var light := node as Light3D
		if PALETTE.has(biome):
			var biome_color: Color = PALETTE[biome].get("glow", PALETTE[biome].get("base", Color.WHITE))
			light.light_color = light.light_color.lerp(biome_color, 0.5)
	
	for child in node.get_children():
		_apply_biome_recursive(child, biome)
