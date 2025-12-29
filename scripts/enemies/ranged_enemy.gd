extends CharacterBody3D
class_name RangedEnemy

enum State { IDLE, ALERT, ATTACK }

@export var move_speed: float = 2.8
@export var acceleration: float = 10.0
@export var knockback_multiplier: float = 0.9
@export var stun_duration: float = 1.0
@export var detection_range: float = 16.0
@export var attack_range: float = 10.0
@export var keep_distance: float = 6.0
@export var attack_cooldown: float = 1.6
@export var attack_damage: int = 10

var blast_response: float = 0.9
var _stun_timer: float = 0.0
var _target: Node3D
var _state: int = State.IDLE
var _attack_timer: float = 0.0

@onready var _health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	_target = get_tree().get_root().find_child("PlayerObject", true, false)
	if _health_component:
		_health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_root().find_child("PlayerObject", true, false)

	if _stun_timer > 0.0:
		_stun_timer = maxf(_stun_timer - delta, 0.0)
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return

	if _attack_timer > 0.0:
		_attack_timer -= delta

	var distance = _get_target_distance()
	_update_state(distance)

	match _state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		State.ALERT:
			_move_to_spacing(delta, distance)
		State.ATTACK:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_try_attack()

	move_and_slide()

func apply_blast_impulse(impulse: Vector3) -> void:
	velocity += impulse * knockback_multiplier
	_stun_timer = stun_duration

func _get_target_distance() -> float:
	if not _target:
		return INF
	return global_position.distance_to(_target.global_position)

func _update_state(distance: float) -> void:
	if distance <= attack_range:
		_state = State.ATTACK
	elif distance <= detection_range:
		_state = State.ALERT
	else:
		_state = State.IDLE

func _move_to_spacing(delta: float, distance: float) -> void:
	if not _target:
		return
	var dir = _target.global_position - global_position
	dir.y = 0.0
	if distance < keep_distance:
		dir = -dir
	if dir.length() > 0.1:
		var desired_velocity = dir.normalized() * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)

func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	var health = _target.find_child("HealthComponent", true, false) as HealthComponent
	if not health:
		return
	if _has_line_of_sight():
		health.take_damage(attack_damage)

func _has_line_of_sight() -> bool:
	if not _target:
		return false
	var space_state = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3.UP * 0.6
	var to_pos = _target.global_position + Vector3.UP * 0.6
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result and result.collider != _target:
		return false
	return true

func _on_died() -> void:
	queue_free()
