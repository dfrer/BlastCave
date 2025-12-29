extends CharacterBody3D

@export var move_speed: float = 3.5
@export var acceleration: float = 10.0
@export var knockback_multiplier: float = 1.0
@export var stun_duration: float = 1.0

var blast_response: float = 1.0
var _stun_timer: float = 0.0
var _target: Node3D

func _ready() -> void:
	_target = get_tree().get_root().find_child("PlayerObject", true, false)

func _physics_process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_root().find_child("PlayerObject", true, false)

	if _stun_timer > 0.0:
		_stun_timer = maxf(_stun_timer - delta, 0.0)
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return

	if _target:
		var dir = _target.global_position - global_position
		dir.y = 0.0
		if dir.length() > 0.1:
			var desired_velocity = dir.normalized() * move_speed
			velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)

	move_and_slide()

func apply_blast_impulse(impulse: Vector3) -> void:
	velocity += impulse * knockback_multiplier
	_stun_timer = stun_duration
