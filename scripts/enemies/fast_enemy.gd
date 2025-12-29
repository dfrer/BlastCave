extends CharacterBody3D
class_name FastEnemy

enum State { IDLE, ALERT, ATTACK }

@export var move_speed: float = 5.5
@export var acceleration: float = 14.0
@export var knockback_multiplier: float = 1.2
@export var stun_duration: float = 0.8
@export var detection_range: float = 14.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 0.9
@export var attack_damage: int = 6

var blast_response: float = 1.1
var _stun_timer: float = 0.0
var _target: Node3D
var _state: int = State.IDLE
var _attack_timer: float = 0.0

@onready var _health_component: HealthComponent = $HealthComponent
@onready var _damage_source: DamageSource = $DamageSource

func _ready() -> void:
	_target = get_tree().get_root().find_child("PlayerObject", true, false)
	if _health_component:
		_health_component.died.connect(_on_died)
	if _damage_source:
		_damage_source.damage_amount = attack_damage
		_damage_source.monitoring = false

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
			_move_toward_target(delta)
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

func _move_toward_target(delta: float) -> void:
	if not _target:
		return
	var dir = _target.global_position - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		var desired_velocity = dir.normalized() * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)

func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if _damage_source:
		_damage_source.monitoring = true
		get_tree().create_timer(0.15).timeout.connect(_disable_damage_source)

func _disable_damage_source() -> void:
	if _damage_source:
		_damage_source.monitoring = false

func _on_died() -> void:
	queue_free()
