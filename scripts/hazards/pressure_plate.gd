extends Node3D
class_name PressurePlate

## Hazard that triggers a small explosion when stepped on

@export var blast_force: float = 12.0
@export var blast_radius: float = 4.0
@export var blast_damage: float = 15.0
@export var trigger_delay: float = 0.5

var _triggered: bool = false
var _mesh: MeshInstance3D
var _light: OmniLight3D
var _mat_active: StandardMaterial3D
var _mat_idle: StandardMaterial3D

func _ready() -> void:
	_mesh = $MeshInstance3D
	_light = $OmniLight3D
	
	_mat_idle = _mesh.material_override
	_mat_active = StandardMaterial3D.new()
	_mat_active.albedo_color = Color(1.0, 0.2, 0.2)
	_mat_active.emission_enabled = true
	_mat_active.emission = Color(1.0, 0.0, 0.0)
	_mat_active.emission_energy_multiplier = 3.0
	
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	
	if body is RigidBody3D or body is CharacterBody3D:
		_trigger()

func _trigger() -> void:
	_triggered = true
	
	# Visual feedback
	if _mesh:
		_mesh.material_override = _mat_active
	if _light:
		_light.visible = true
	
	# Audio feedback
	if AudioManager.instance:
		AudioManager.instance.play_ui("click", 0.0)
	
	# Delayed explosion
	get_tree().create_timer(trigger_delay).timeout.connect(_explode)

func _explode() -> void:
	FXHelper.spawn_explosion(self, global_position, "ImpulseCharge", blast_radius)
	
	# Apply damage and force
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = blast_radius
	query.shape = shape
	query.transform = Transform3D.IDENTITY.translated(global_position)
	query.collision_mask = 1 | 2 # Default layers
	
	var results = space.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is RigidBody3D:
			var direction = (collider.global_position - global_position).normalized()
			var dist = global_position.distance_to(collider.global_position)
			var force = (1.0 - (dist / blast_radius)) * blast_force
			collider.apply_central_impulse(direction * force)
			
			if collider.has_node("HealthComponent"):
				collider.get_node("HealthComponent").take_damage(blast_damage, direction * force, collider.global_position)
		
		elif collider is CharacterBody3D:
			if collider.has_method("apply_blast_impulse"):
				var direction = (collider.global_position - global_position).normalized()
				var dist = global_position.distance_to(collider.global_position)
				var force = (1.0 - (dist / blast_radius)) * blast_force
				collider.apply_blast_impulse(direction * force)
			
			if collider.has_node("HealthComponent"):
				collider.get_node("HealthComponent").take_damage(blast_damage, Vector3.UP, collider.global_position)
	
	# Reset after a while
	get_tree().create_timer(5.0).timeout.connect(_reset)

func _reset() -> void:
	_triggered = false
	if _mesh:
		_mesh.material_override = _mat_idle
	if _light:
		_light.visible = false
