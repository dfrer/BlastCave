extends Node3D
class_name LavaPool

## Damaging hazard that deals damage over time to entities inside

@export var damage_per_second: float = 15.0
@export var damage_interval: float = 0.25
@export var knockback_force: float = 3.0

var _damage_area: Area3D
var _damage_timer: float = 0.0
var _bodies_in_pool: Array = []

func _ready() -> void:
	_damage_area = $DamageArea
	if _damage_area:
		_damage_area.body_entered.connect(_on_body_entered)
		_damage_area.body_exited.connect(_on_body_exited)
	
	# Start ambient particles
	_spawn_ambient_effects()

func _physics_process(delta: float) -> void:
	_damage_timer += delta
	
	if _damage_timer >= damage_interval:
		_damage_timer = 0.0
		_apply_damage_to_all()

func _on_body_entered(body: Node3D) -> void:
	if body not in _bodies_in_pool:
		_bodies_in_pool.append(body)
		# Initial burst of damage/feedback on contact
		_apply_damage(body)
		FXHelper.spawn_sparks(self, body.global_position, 8)

func _on_body_exited(body: Node3D) -> void:
	_bodies_in_pool.erase(body)

func _apply_damage_to_all() -> void:
	for body in _bodies_in_pool:
		if is_instance_valid(body):
			_apply_damage(body)

func _apply_damage(body: Node3D) -> void:
	var damage = damage_per_second * damage_interval
	
	# Apply damage if the body has health
	if body.has_node("HealthComponent"):
		var health = body.get_node("HealthComponent")
		if health.has_method("take_damage"):
			var impulse = (body.global_position - global_position).normalized() * knockback_force
			impulse.y = abs(impulse.y) + knockback_force * 0.5  # Push upward
			health.take_damage(damage, impulse, body.global_position)
	
	# Apply knockback if it's a rigid body
	if body is RigidBody3D:
		var impulse = (body.global_position - global_position).normalized() * knockback_force
		impulse.y = knockback_force  # Push upward out of lava
		body.apply_central_impulse(impulse)
	
	# Spawn bubbles/steam effect
	if randf() < 0.3:
		FXHelper.spawn_dust(self, body.global_position + Vector3(randf_range(-0.5, 0.5), 0.2, randf_range(-0.5, 0.5)), 4)

func _spawn_ambient_effects() -> void:
	if ParticleLibrary.instance:
		var embers = ParticleLibrary.instance.create_ambient("embers")
		if embers:
			add_child(embers)
			embers.position = Vector3.UP * 0.5
