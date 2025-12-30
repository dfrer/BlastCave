extends Node3D
class_name TrajectoryPreview

## Enhanced trajectory preview with bounce prediction, hazard warnings, and landing indicator

@export var max_steps: int = 30
@export var step_interval: float = 0.1
@export var safe_speed_threshold: float = 8.0
@export var danger_speed_threshold: float = 15.0
@export var max_bounces: int = 2
@export var bounce_energy_loss: float = 0.6

var spheres: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _collision_index: int = -1
var _landing_indicator: MeshInstance3D
var _hazard_warning: MeshInstance3D

# Colors for velocity-based feedback
var color_safe: Color = Color(0.2, 0.9, 0.3, 0.9)
var color_moderate: Color = Color(0.95, 0.85, 0.2, 0.8)
var color_danger: Color = Color(0.95, 0.3, 0.2, 0.7)
var color_collision: Color = Color(1.0, 0.1, 0.1, 1.0)
var color_bounce: Color = Color(0.3, 0.6, 1.0, 0.9)
var color_hazard: Color = Color(1.0, 0.3, 0.0, 0.8)

func _ready():
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	
	for i in range(max_steps):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_safe
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials.append(mat)
		
		var sphere = MeshInstance3D.new()
		sphere.mesh = mesh
		sphere.material_override = mat
		sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sphere)
		sphere.hide()
		spheres.append(sphere)
	
	_create_landing_indicator()
	_create_hazard_warning()

func _create_landing_indicator() -> void:
	_landing_indicator = MeshInstance3D.new()
	var circle = CylinderMesh.new()
	circle.top_radius = 0.5
	circle.bottom_radius = 0.5
	circle.height = 0.05
	_landing_indicator.mesh = circle
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.4, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_landing_indicator.material_override = mat
	_landing_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_landing_indicator)
	_landing_indicator.hide()

func _create_hazard_warning() -> void:
	_hazard_warning = MeshInstance3D.new()
	var diamond = PrismMesh.new()
	diamond.size = Vector3(0.6, 0.8, 0.6)
	_hazard_warning.mesh = diamond
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_hazard
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 2.0
	_hazard_warning.material_override = mat
	_hazard_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hazard_warning)
	_hazard_warning.hide()

func update_preview(start_pos: Vector3, initial_velocity: Vector3, gravity: Vector3):
	_collision_index = -1
	_landing_indicator.hide()
	_hazard_warning.hide()
	
	var current_pos = start_pos
	var current_vel = initial_velocity
	var bounce_count = 0
	var sphere_idx = 0
	
	while sphere_idx < max_steps:
		var t = step_interval
		var next_pos = current_pos + current_vel * t + 0.5 * gravity * t * t
		var next_vel = current_vel + gravity * t
		
		# Check for collision
		var collision_result = _check_collision_detailed(current_pos, next_pos)
		
		if collision_result.hit:
			var hit_pos = collision_result.position
			var hit_normal = collision_result.normal
			
			# Show sphere at collision point
			spheres[sphere_idx].global_position = hit_pos
			
			# Check if it's a hazard
			if collision_result.is_hazard:
				_show_hazard_warning(hit_pos)
				_materials[sphere_idx].albedo_color = color_hazard
				spheres[sphere_idx].show()
				sphere_idx += 1
				_hide_remaining(sphere_idx)
				return
			
			# Check if we can bounce
			if bounce_count < max_bounces:
				# Calculate bounce velocity
				var reflect_vel = next_vel.bounce(hit_normal) * bounce_energy_loss
				
				# Mark this as a bounce point
				_materials[sphere_idx].albedo_color = color_bounce
				spheres[sphere_idx].scale = Vector3(1.5, 1.5, 1.5)
				spheres[sphere_idx].show()
				sphere_idx += 1
				
				# Continue trajectory from bounce
				current_pos = hit_pos + hit_normal * 0.1
				current_vel = reflect_vel
				bounce_count += 1
				continue
			else:
				# Final collision - show landing indicator
				_show_landing_indicator(hit_pos, hit_normal)
				_collision_index = sphere_idx
				_materials[sphere_idx].albedo_color = color_collision
				spheres[sphere_idx].scale = Vector3(2.0, 2.0, 2.0)
				spheres[sphere_idx].show()
				sphere_idx += 1
				_hide_remaining(sphere_idx)
				return
		
		# No collision, update position
		var speed = next_vel.length()
		spheres[sphere_idx].global_position = next_pos
		_update_sphere_color(sphere_idx, speed)
		
		# Apply fade
		var fade = 1.0 - (float(sphere_idx) / float(max_steps)) * 0.6
		_materials[sphere_idx].albedo_color.a = fade
		spheres[sphere_idx].scale = Vector3.ONE
		spheres[sphere_idx].show()
		
		current_pos = next_pos
		current_vel = next_vel
		sphere_idx += 1

func _check_collision_detailed(from: Vector3, to: Vector3) -> Dictionary:
	var result = {"hit": false, "position": Vector3.ZERO, "normal": Vector3.UP, "is_hazard": false}
	
	var space = get_world_3d().direct_space_state
	if not space:
		return result
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var hit = space.intersect_ray(query)
	if hit.is_empty():
		return result
	
	result.hit = true
	result.position = hit.position
	result.normal = hit.normal
	
	# Check if we hit a hazard
	var collider = hit.collider
	if collider:
		if collider.is_in_group("hazard") or collider.name.contains("Lava") or collider.name.contains("Spike"):
			result.is_hazard = true
	
	return result

func _show_landing_indicator(pos: Vector3, normal: Vector3) -> void:
	_landing_indicator.global_position = pos + normal * 0.1
	# Align to surface normal
	if abs(normal.dot(Vector3.UP)) < 0.99:
		_landing_indicator.look_at(pos + normal, Vector3.UP)
	_landing_indicator.show()

func _show_hazard_warning(pos: Vector3) -> void:
	_hazard_warning.global_position = pos + Vector3.UP * 0.5
	_hazard_warning.show()
	# Pulsing animation handled in _process

func _process(delta: float) -> void:
	# Animate hazard warning
	if _hazard_warning.visible:
		_hazard_warning.rotate_y(delta * 3.0)
		var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.2
		_hazard_warning.scale = Vector3(pulse, pulse, pulse)

func _hide_remaining(from_index: int):
	for i in range(from_index, max_steps):
		spheres[i].hide()

func _update_sphere_color(index: int, speed: float):
	var color: Color
	if speed < safe_speed_threshold:
		var t = speed / safe_speed_threshold
		color = color_safe.lerp(color_moderate, t)
	elif speed < danger_speed_threshold:
		var t = (speed - safe_speed_threshold) / (danger_speed_threshold - safe_speed_threshold)
		color = color_moderate.lerp(color_danger, t)
	else:
		color = color_danger
	
	_materials[index].albedo_color = color
	spheres[index].scale = Vector3.ONE

func hide_preview():
	for i in range(max_steps):
		spheres[i].hide()
		spheres[i].scale = Vector3.ONE
	_landing_indicator.hide()
	_hazard_warning.hide()
	_collision_index = -1

func get_collision_point() -> Vector3:
	if _collision_index >= 0 and _collision_index < spheres.size():
		return spheres[_collision_index].global_position
	return Vector3.ZERO

func has_collision() -> bool:
	return _collision_index >= 0
