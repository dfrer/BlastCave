extends Node
class_name FXHelper

## Unified FX spawning facade - uses AudioManager and ParticleLibrary singletons
## Provides convenient static methods for common effects

# === EXPLOSION EFFECTS ===

## Spawn a full explosion effect with particles and sound
static func spawn_explosion(parent: Node, position: Vector3, explosive_type: String = "ImpulseCharge", volume_db: float = 0.0) -> void:
	if parent == null:
		return
	
	# Use particle library for full visual effect
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_full_explosion(parent, position, explosive_type)
	else:
		# Fallback if singletons not ready
		_spawn_fallback_burst(parent, position)
	
	# Use audio manager for sound
	if AudioManager.instance:
		AudioManager.instance.play_explosion(position, explosive_type, volume_db)

## Legacy compatibility - spawn_burst now uses proper particles
static func spawn_burst(parent: Node, position: Vector3, color: Color, _amount: int = 24, _lifetime: float = 0.6) -> void:
	if parent == null:
		return
	
	if ParticleLibrary.instance:
		# Use explosion particles with closest matching color
		var type := _get_explosive_type_for_color(color)
		ParticleLibrary.instance.spawn_explosion(parent, position, type)
	else:
		_spawn_fallback_burst(parent, position)

# === DUST AND DEBRIS ===

## Spawn dust cloud effect
static func spawn_dust(parent: Node, position: Vector3, amount: int = 32) -> void:
	if parent == null:
		return
	
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_dust(parent, position, amount)
	else:
		_spawn_fallback_dust(parent, position)

## Spawn debris particles
static func spawn_debris(parent: Node, position: Vector3) -> void:
	if parent == null:
		return
	
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_debris(parent, position)

## Spawn sparks (for metal impacts, sliding, etc)
static func spawn_sparks(parent: Node, position: Vector3, amount: int = 16) -> void:
	if parent == null:
		return
	
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_sparks(parent, position, amount)

# === IMPACT EFFECTS ===

## Spawn impact effect with surface-appropriate particles and sound
static func spawn_impact(parent: Node, position: Vector3, normal: Vector3, surface_type: String = "rock", velocity: float = 5.0) -> void:
	if parent == null:
		return
	
	if ParticleLibrary.instance:
		ParticleLibrary.instance.spawn_impact(parent, position, normal, surface_type, velocity)
	
	if AudioManager.instance:
		AudioManager.instance.play_impact(position, surface_type, velocity)

# === CAMERA EFFECTS ===

## Apply screen shake
static func screen_shake(parent: Node, intensity: float) -> void:
	if parent == null:
		return
	var rig = parent.get_tree().get_root().find_child("CameraRig", true, false)
	if rig and rig.has_method("apply_trauma"):
		rig.apply_trauma(intensity)

# === AUDIO ===

## Play a sound effect at 3D position
static func spawn_sfx(parent: Node, position: Vector3, pitch: float = 1.0, _sound_type: String = "impact_rock") -> void:
	if parent == null:
		return
	
	if AudioManager.instance:
		AudioManager.instance.play_impact(position, "default", pitch * 5.0)
	# Legacy fallback removed - we now always use proper audio

## Play UI sound
static func play_ui_sound(action: String) -> void:
	if AudioManager.instance:
		AudioManager.instance.play_ui(action)

## Play pickup sound
static func play_pickup_sound() -> void:
	if AudioManager.instance:
		AudioManager.instance.play_ui("pickup")

## Play error sound (e.g., out of ammo)
static func play_error_sound() -> void:
	if AudioManager.instance:
		AudioManager.instance.play_ui("error")

# === AMBIENT EFFECTS ===

## Start ambient particles and sound for a room
static func start_room_ambient(room: Node, room_id: String, biome: String) -> void:
	if room == null:
		return
	
	if ParticleLibrary.instance:
		var ambient_particles := ParticleLibrary.instance.create_ambient(biome)
		if ambient_particles:
			room.add_child(ambient_particles)
			ambient_particles.name = "AmbientParticles"
	
	if AudioManager.instance:
		var room_center := Vector3.ZERO
		if room is Node3D:
			room_center = room.global_position
		AudioManager.instance.start_ambient(room_id, biome, room_center)

## Stop ambient effects for a room
static func stop_room_ambient(room_id: String) -> void:
	if AudioManager.instance:
		AudioManager.instance.stop_ambient(room_id)

# === HELPER FUNCTIONS ===

static func _get_explosive_type_for_color(color: Color) -> String:
	# Match color to closest explosive type
	var types := {
		"ImpulseCharge": Color(1.0, 0.7, 0.2),
		"ShapedCharge": Color(0.2, 0.8, 1.0),
		"DelayedCharge": Color(0.9, 0.3, 0.6),
	}
	
	var best_match := "ImpulseCharge"
	var best_distance := 999.0
	
	for type_name in types:
		var type_color: Color = types[type_name]
		var distance: float = abs(color.r - type_color.r) + abs(color.g - type_color.g) + abs(color.b - type_color.b)
		if distance < best_distance:
			best_distance = distance
			best_match = type_name
	
	return best_match

# === FALLBACK IMPLEMENTATIONS ===
# Used when singletons aren't ready (should rarely happen)

static func _spawn_fallback_burst(parent: Node, position: Vector3) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 24
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	
	var material = ParticleProcessMaterial.new()
	material.initial_velocity_min = 8.0
	material.initial_velocity_max = 12.0
	material.spread = 180.0
	material.gravity = Vector3(0, -9.8, 0)
	material.color = Color(1.0, 0.7, 0.2)
	particles.process_material = material
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	particles.draw_pass_1 = mesh
	
	parent.add_child.call_deferred(particles)
	particles.set_deferred("global_position", position)
	parent.get_tree().create_timer(0.8).timeout.connect(particles.queue_free)

static func _spawn_fallback_dust(parent: Node, position: Vector3) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 16
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.emitting = true
	
	var material = ParticleProcessMaterial.new()
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, 0.5, 0)
	material.color = Color(0.7, 0.65, 0.55, 0.5)
	particles.process_material = material
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	particles.draw_pass_1 = mesh
	
	parent.add_child.call_deferred(particles)
	particles.set_deferred("global_position", position)
	parent.get_tree().create_timer(1.2).timeout.connect(particles.queue_free)
