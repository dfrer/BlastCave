extends Node3D
class_name SpikeTrap

## Spike trap that cycles between retracted and extended states
## Damages entities when spikes are extended

@export var damage_amount: float = 20.0
@export var knockback_force: float = 8.0
@export var extended_time: float = 2.0
@export var retracted_time: float = 3.0
@export var extension_speed: float = 8.0

var _is_extended: bool = false
var _cycle_timer: float = 0.0

var _damage_area: Area3D
var _spikes_container: Node3D
var _damaged_bodies: Array = []  # Prevent multi-hit in same extension

const SPIKE_RETRACTED_Y: float = -0.3
const SPIKE_EXTENDED_Y: float = 0.6

func _ready() -> void:
	_damage_area = $DamageArea
	_spikes_container = $Spikes
	
	if _damage_area:
		_damage_area.body_entered.connect(_on_body_entered)
		_damage_area.monitoring = false
	
	# Initialize spikes in retracted position
	_set_spike_height(SPIKE_RETRACTED_Y)
	
	# Create spike meshes
	_create_spike_meshes()
	
	# Random offset to prevent all traps syncing
	_cycle_timer = randf() * retracted_time

func _physics_process(delta: float) -> void:
	_cycle_timer += delta
	
	if _is_extended:
		if _cycle_timer >= extended_time:
			_retract()
	else:
		if _cycle_timer >= retracted_time:
			_extend()
	
	# Animate spike position
	var target_y = SPIKE_EXTENDED_Y if _is_extended else SPIKE_RETRACTED_Y
	var current_y = _spikes_container.position.y if _spikes_container else 0.0
	var new_y = move_toward(current_y, target_y, extension_speed * delta)
	_set_spike_height(new_y)
	
	# Enable damage when mostly extended
	if _damage_area:
		_damage_area.monitoring = _is_extended and new_y > SPIKE_EXTENDED_Y * 0.7

func _extend() -> void:
	_is_extended = true
	_cycle_timer = 0.0
	_damaged_bodies.clear()
	
	# Play warning sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "metal", 5.0)

func _retract() -> void:
	_is_extended = false
	_cycle_timer = 0.0
	
	# Play retract sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "rock", 3.0)

func _set_spike_height(y: float) -> void:
	if _spikes_container:
		_spikes_container.position.y = y

func _create_spike_meshes() -> void:
	if not _spikes_container:
		return
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.55)
	mat.roughness = 0.4
	mat.metallic = 0.7
	
	for spike in _spikes_container.get_children():
		if spike is MeshInstance3D and spike.mesh == null:
			var cone = CylinderMesh.new()
			cone.top_radius = 0.02
			cone.bottom_radius = 0.12
			cone.height = 0.8
			spike.mesh = cone
			spike.material_override = mat

func _on_body_entered(body: Node3D) -> void:
	# Prevent multi-hit in same extension
	if body in _damaged_bodies:
		return
	_damaged_bodies.append(body)
	
	# Calculate knockback direction (upward and away)
	var knockback_dir = (body.global_position - global_position).normalized()
	knockback_dir.y = 0.5
	knockback_dir = knockback_dir.normalized()
	var impulse = knockback_dir * knockback_force
	
	# Apply damage
	if body.has_node("HealthComponent"):
		var health = body.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(damage_amount, impulse, body.global_position)
	
	# Apply knockback
	if body is RigidBody3D:
		body.apply_central_impulse(impulse)
	
	# Visual feedback
	FXHelper.spawn_sparks(self, body.global_position, 12)
	FXHelper.screen_shake(self, 0.2)
	
	if AudioManager.instance:
		AudioManager.instance.play_impact(body.global_position, "metal", 10.0)
