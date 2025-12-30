extends Node
class_name ParticleLibrary

## Centralized particle effect library with unique effects per type
## Provides high-quality, properly configured particle systems

# Singleton access
static var instance: ParticleLibrary

# Cached particle configurations (not instances - those are created per-use)
var _particle_configs: Dictionary = {}

# Default particle settings
const DEFAULT_AMOUNT := 32
const DEFAULT_LIFETIME := 0.8

func _ready() -> void:
	instance = self
	_setup_particle_configs()

func _setup_particle_configs() -> void:
	# Explosion particles for each type
	_particle_configs["explosion_impulse"] = {
		"amount": 48,
		"lifetime": 0.6,
		"color": Color(1.0, 0.7, 0.2),
		"color_end": Color(1.0, 0.3, 0.1, 0.0),
		"velocity_min": 8.0,
		"velocity_max": 15.0,
		"gravity": Vector3(0, -5.0, 0),
		"scale_min": 0.3,
		"scale_max": 0.8,
		"spread": 180.0,
		"mesh_type": "sphere",
	}
	
	_particle_configs["explosion_shaped"] = {
		"amount": 36,
		"lifetime": 0.5,
		"color": Color(0.2, 0.8, 1.0),
		"color_end": Color(0.1, 0.4, 0.8, 0.0),
		"velocity_min": 12.0,
		"velocity_max": 20.0,
		"gravity": Vector3(0, -2.0, 0),
		"scale_min": 0.2,
		"scale_max": 0.5,
		"spread": 45.0,  # Narrow cone
		"mesh_type": "box",
	}
	
	_particle_configs["explosion_delayed"] = {
		"amount": 64,
		"lifetime": 0.8,
		"color": Color(0.9, 0.3, 0.6),
		"color_end": Color(0.6, 0.1, 0.3, 0.0),
		"velocity_min": 10.0,
		"velocity_max": 18.0,
		"gravity": Vector3(0, -8.0, 0),
		"scale_min": 0.25,
		"scale_max": 0.7,
		"spread": 180.0,
		"mesh_type": "prism",
	}
	
	_particle_configs["explosion_cluster"] = {
		"amount": 80,
		"lifetime": 0.4,
		"color": Color(0.6, 1.0, 0.4),
		"color_end": Color(0.3, 0.7, 0.2, 0.0),
		"velocity_min": 6.0,
		"velocity_max": 12.0,
		"gravity": Vector3(0, -4.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.3,
		"spread": 180.0,
		"mesh_type": "sphere",
	}
	
	_particle_configs["explosion_repulsor"] = {
		"amount": 40,
		"lifetime": 0.7,
		"color": Color(0.8, 0.4, 1.0),
		"color_end": Color(0.4, 0.2, 0.6, 0.0),
		"velocity_min": 5.0,
		"velocity_max": 10.0,
		"gravity": Vector3(0, 2.0, 0),  # Floats up
		"scale_min": 0.4,
		"scale_max": 1.0,
		"spread": 180.0,
		"mesh_type": "ring",
	}
	
	# Impact particles
	_particle_configs["impact_rock"] = {
		"amount": 24,
		"lifetime": 0.5,
		"color": Color(0.5, 0.45, 0.4),
		"color_end": Color(0.4, 0.35, 0.3, 0.0),
		"velocity_min": 3.0,
		"velocity_max": 8.0,
		"gravity": Vector3(0, -15.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.3,
		"spread": 120.0,
		"mesh_type": "box",
	}
	
	_particle_configs["impact_metal"] = {
		"amount": 32,
		"lifetime": 0.3,
		"color": Color(1.0, 0.9, 0.7),
		"color_end": Color(0.8, 0.6, 0.3, 0.0),
		"velocity_min": 5.0,
		"velocity_max": 12.0,
		"gravity": Vector3(0, -10.0, 0),
		"scale_min": 0.05,
		"scale_max": 0.15,
		"spread": 90.0,
		"mesh_type": "sphere",
	}
	
	_particle_configs["impact_crystal"] = {
		"amount": 20,
		"lifetime": 0.6,
		"color": Color(0.5, 0.8, 1.0),
		"color_end": Color(0.3, 0.5, 0.8, 0.0),
		"velocity_min": 2.0,
		"velocity_max": 6.0,
		"gravity": Vector3(0, -5.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.25,
		"spread": 60.0,
		"mesh_type": "prism",
	}
	
	# Dust/debris
	_particle_configs["dust_cloud"] = {
		"amount": 48,
		"lifetime": 1.5,
		"color": Color(0.7, 0.65, 0.55, 0.6),
		"color_end": Color(0.6, 0.55, 0.45, 0.0),
		"velocity_min": 1.0,
		"velocity_max": 4.0,
		"gravity": Vector3(0, 0.5, 0),  # Floats up
		"scale_min": 0.5,
		"scale_max": 2.0,
		"spread": 180.0,
		"mesh_type": "billboard_sphere",
	}
	
	_particle_configs["debris_small"] = {
		"amount": 16,
		"lifetime": 0.8,
		"color": Color(0.4, 0.35, 0.3),
		"color_end": Color(0.3, 0.25, 0.2, 0.5),
		"velocity_min": 4.0,
		"velocity_max": 10.0,
		"gravity": Vector3(0, -15.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.4,
		"spread": 120.0,
		"mesh_type": "box",
	}
	
	# Sparks
	_particle_configs["sparks"] = {
		"amount": 24,
		"lifetime": 0.4,
		"color": Color(1.0, 0.9, 0.6),
		"color_end": Color(1.0, 0.5, 0.2, 0.0),
		"velocity_min": 8.0,
		"velocity_max": 15.0,
		"gravity": Vector3(0, -12.0, 0),
		"scale_min": 0.02,
		"scale_max": 0.08,
		"spread": 90.0,
		"mesh_type": "sphere",
		"emission": true,
		"emission_energy": 3.0,
	}
	
	# Ambient particles
	_particle_configs["ambient_dust"] = {
		"amount": 32,
		"lifetime": 4.0,
		"color": Color(0.8, 0.75, 0.7, 0.3),
		"color_end": Color(0.7, 0.65, 0.6, 0.0),
		"velocity_min": 0.1,
		"velocity_max": 0.5,
		"gravity": Vector3(0, 0.1, 0),
		"scale_min": 0.05,
		"scale_max": 0.15,
		"spread": 180.0,
		"mesh_type": "billboard_sphere",
		"continuous": true,
		"emission_box": Vector3(10, 5, 10),
	}
	
	_particle_configs["ambient_drips"] = {
		"amount": 8,
		"lifetime": 1.0,
		"color": Color(0.6, 0.7, 0.8, 0.7),
		"color_end": Color(0.5, 0.6, 0.7, 0.0),
		"velocity_min": 0.0,
		"velocity_max": 0.5,
		"gravity": Vector3(0, -8.0, 0),
		"scale_min": 0.05,
		"scale_max": 0.1,
		"spread": 10.0,
		"mesh_type": "sphere",
		"continuous": true,
		"emission_box": Vector3(8, 0.5, 8),
	}
	
	_particle_configs["ambient_embers"] = {
		"amount": 16,
		"lifetime": 3.0,
		"color": Color(1.0, 0.6, 0.2),
		"color_end": Color(0.8, 0.3, 0.1, 0.0),
		"velocity_min": 0.5,
		"velocity_max": 2.0,
		"gravity": Vector3(0, 1.0, 0),
		"scale_min": 0.03,
		"scale_max": 0.1,
		"spread": 180.0,
		"mesh_type": "sphere",
		"emission": true,
		"emission_energy": 2.0,
		"continuous": true,
		"emission_box": Vector3(5, 2, 5),
	}
	
	_particle_configs["ambient_toxic_bubbles"] = {
		"amount": 12,
		"lifetime": 2.0,
		"color": Color(0.4, 0.9, 0.3, 0.7),
		"color_end": Color(0.3, 0.7, 0.2, 0.0),
		"velocity_min": 0.5,
		"velocity_max": 1.5,
		"gravity": Vector3(0, 2.0, 0),
		"scale_min": 0.1,
		"scale_max": 0.3,
		"spread": 30.0,
		"mesh_type": "sphere",
		"emission": true,
		"emission_energy": 1.0,
		"continuous": true,
		"emission_box": Vector3(3, 0.2, 3),
	}

# === PARTICLE CREATION ===

func _create_particle_system(config: Dictionary, one_shot: bool = true) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	
	# Basic settings
	particles.amount = config.get("amount", DEFAULT_AMOUNT)
	particles.lifetime = config.get("lifetime", DEFAULT_LIFETIME)
	particles.one_shot = one_shot
	particles.explosiveness = 0.9 if one_shot else 0.0
	particles.emitting = true
	
	# Create process material
	var process_mat := ParticleProcessMaterial.new()
	
	# Velocity and direction
	process_mat.initial_velocity_min = config.get("velocity_min", 5.0)
	process_mat.initial_velocity_max = config.get("velocity_max", 10.0)
	process_mat.spread = config.get("spread", 180.0)
	process_mat.direction = Vector3.UP
	process_mat.gravity = config.get("gravity", Vector3(0, -9.8, 0))
	
	# Damping
	process_mat.damping_min = config.get("damping_min", 1.0)
	process_mat.damping_max = config.get("damping_max", 3.0)
	
	# Scale
	process_mat.scale_min = config.get("scale_min", 0.5)
	process_mat.scale_max = config.get("scale_max", 1.0)
	
	# Color
	var color_start: Color = config.get("color", Color.WHITE)
	var color_end: Color = config.get("color_end", color_start)
	
	# Create color gradient
	var gradient := Gradient.new()
	gradient.set_color(0, color_start)
	gradient.add_point(1.0, color_end)
	var gradient_tex := GradientTexture1D.new()
	gradient_tex.gradient = gradient
	process_mat.color_ramp = gradient_tex
	
	# Emission shape
	if config.has("emission_box"):
		var box_size: Vector3 = config.get("emission_box")
		process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		process_mat.emission_box_extents = box_size
	
	# Angular velocity for tumbling
	process_mat.angular_velocity_min = -180.0
	process_mat.angular_velocity_max = 180.0
	
	particles.process_material = process_mat
	
	# Create mesh
	var mesh := _create_particle_mesh(config)
	particles.draw_pass_1 = mesh
	
	# Shadow settings
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	return particles

func _create_particle_mesh(config: Dictionary) -> Mesh:
	var mesh_type: String = config.get("mesh_type", "sphere")
	var mesh: Mesh
	
	match mesh_type:
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 8
			sphere.rings = 4
			mesh = sphere
		"box":
			var box := BoxMesh.new()
			box.size = Vector3(0.5, 0.5, 0.5)
			mesh = box
		"prism":
			var prism := PrismMesh.new()
			prism.size = Vector3(0.5, 0.7, 0.4)
			mesh = prism
		"ring":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.3
			torus.outer_radius = 0.5
			mesh = torus
		"billboard_sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 6
			sphere.rings = 3
			mesh = sphere
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			mesh = sphere
	
	# Apply material
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if config.get("emission", false):
		mat.emission_enabled = true
		mat.emission = config.get("color", Color.WHITE)
		mat.emission_energy_multiplier = config.get("emission_energy", 2.0)
	
	if mesh_type == "billboard_sphere":
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	mesh.surface_set_material(0, mat)
	return mesh

# === PUBLIC API ===

## Spawn an explosion particle effect
func spawn_explosion(parent: Node, position: Vector3, explosive_type: String) -> void:
	var config_name := "explosion_%s" % explosive_type.to_lower().replace("charge", "")
	var config = _particle_configs.get(config_name, _particle_configs.get("explosion_impulse"))
	_spawn_particles(parent, position, config, true)

## Spawn impact particles based on surface type
func spawn_impact(parent: Node, position: Vector3, normal: Vector3, surface_type: String = "rock", velocity: float = 5.0) -> void:
	var config_name := "impact_%s" % surface_type.to_lower()
	var config = _particle_configs.get(config_name, _particle_configs.get("impact_rock")).duplicate()
	
	# Scale particle count based on velocity
	var scale := clampf(velocity / 10.0, 0.5, 2.0)
	config["amount"] = int(config.get("amount", 16) * scale)
	
	var particles := _spawn_particles(parent, position, config, true)
	
	# Orient particles to bounce off surface
	if particles:
		# Avoid colinear vectors by using a different up when normal is close to UP
		var up_vector := Vector3.UP
		if abs(normal.dot(Vector3.UP)) > 0.99:
			up_vector = Vector3.FORWARD
		var basis := Basis.looking_at(normal, up_vector)
		particles.transform.basis = basis

## Spawn dust cloud
func spawn_dust(parent: Node, position: Vector3, amount: int = -1) -> void:
	var config = _particle_configs.get("dust_cloud").duplicate()
	if amount > 0:
		config["amount"] = amount
	_spawn_particles(parent, position, config, true)

## Spawn debris
func spawn_debris(parent: Node, position: Vector3) -> void:
	var config = _particle_configs.get("debris_small")
	_spawn_particles(parent, position, config, true)

## Spawn sparks
func spawn_sparks(parent: Node, position: Vector3, amount: int = -1) -> void:
	var config = _particle_configs.get("sparks").duplicate()
	if amount > 0:
		config["amount"] = amount
	_spawn_particles(parent, position, config, true)

## Create an ambient particle emitter (continuous, returns node for management)
func create_ambient(ambient_type: String) -> GPUParticles3D:
	var config_name := "ambient_%s" % ambient_type.to_lower()
	var config = _particle_configs.get(config_name, _particle_configs.get("ambient_dust"))
	return _create_particle_system(config, false)

func _spawn_particles(parent: Node, position: Vector3, config: Dictionary, one_shot: bool) -> GPUParticles3D:
	if not parent:
		return null
	
	var particles := _create_particle_system(config, one_shot)
	parent.add_child(particles)
	particles.global_position = position
	
	# Auto-cleanup for one-shot particles
	if one_shot:
		var lifetime: float = config.get("lifetime", 1.0)
		parent.get_tree().create_timer(lifetime + 0.2).timeout.connect(particles.queue_free)
	
	return particles

## Combine explosion + dust + sparks for a full effect
func spawn_full_explosion(parent: Node, position: Vector3, explosive_type: String) -> void:
	spawn_explosion(parent, position, explosive_type)
	spawn_dust(parent, position, 24)
	spawn_sparks(parent, position, 16)
	spawn_debris(parent, position)
