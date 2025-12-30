extends CharacterBody3D
class_name BasicEnemy

## Basic enemy with attack telegraphs and knockback resistance

signal destroyed(position: Vector3)

enum State { IDLE, ALERT, ATTACK, TELEGRAPHING }

@export var move_speed: float = 3.5
@export var acceleration: float = 10.0
@export var knockback_multiplier: float = 1.0
@export var knockback_resistance: float = 0.0  # 0-1, reduces knockback
@export var stun_duration: float = 1.0
@export var detection_range: float = 12.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.3
@export var attack_damage: int = 8
@export var telegraph_duration: float = 0.4

var blast_response: float = 1.0
var _stun_timer: float = 0.0
var _target: Node3D
var _state: int = State.IDLE
var _attack_timer: float = 0.0
var _telegraph_timer: float = 0.0
var _mesh: MeshInstance3D
var _base_material_color: Color

@onready var _health_component: HealthComponent = $HealthComponent
@onready var _damage_source: DamageSource = $DamageSource

func _ready() -> void:
	_target = get_tree().get_root().find_child("PlayerObject", true, false)
	if _health_component:
		_health_component.died.connect(_on_died)
	if _damage_source:
		_damage_source.damage_amount = attack_damage
		_damage_source.monitoring = false
	
	_mesh = get_node_or_null("Mesh")
	if not _mesh:
		_mesh = get_node_or_null("MeshInstance3D")
	if _mesh and _mesh.material_override is StandardMaterial3D:
		_base_material_color = (_mesh.material_override as StandardMaterial3D).albedo_color

func _physics_process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_root().find_child("PlayerObject", true, false)

	if _stun_timer > 0.0:
		_stun_timer = maxf(_stun_timer - delta, 0.0)
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		_update_stun_visual()
		return

	if _attack_timer > 0.0:
		_attack_timer -= delta

	var distance = _get_target_distance()
	_update_state(distance, delta)

	match _state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_reset_visual()
		State.ALERT:
			_move_toward_target(delta)
			_reset_visual()
		State.TELEGRAPHING:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_telegraph_timer -= delta
			_update_telegraph_visual()
			if _telegraph_timer <= 0:
				_execute_attack()
		State.ATTACK:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)

	move_and_slide()

func apply_blast_impulse(impulse: Vector3) -> void:
	# Apply knockback resistance
	var reduced_impulse = impulse * (1.0 - knockback_resistance) * knockback_multiplier
	velocity += reduced_impulse
	_stun_timer = stun_duration * (1.0 - knockback_resistance * 0.5)
	
	# Visual feedback
	_flash_on_hit()

func _get_target_distance() -> float:
	if not _target:
		return INF
	return global_position.distance_to(_target.global_position)

func _update_state(distance: float, _delta: float) -> void:
	if _state == State.TELEGRAPHING or _state == State.ATTACK:
		return  # Don't interrupt attack sequence
	
	if distance <= attack_range and _attack_timer <= 0:
		_start_telegraph()
	elif distance <= detection_range:
		_state = State.ALERT
	else:
		_state = State.IDLE

func _start_telegraph() -> void:
	_state = State.TELEGRAPHING
	_telegraph_timer = telegraph_duration
	
	# Play telegraph sound
	if AudioManager.instance:
		AudioManager.instance.play_ui("hover", -3.0)

func _update_telegraph_visual() -> void:
	if not _mesh or not _mesh.material_override:
		return
	
	var mat = _mesh.material_override as StandardMaterial3D
	if not mat:
		return
	
	# Rapid flashing during telegraph
	var flash_speed = 15.0
	var flash = sin(Time.get_ticks_msec() * 0.001 * flash_speed * TAU)
	if flash > 0:
		mat.albedo_color = Color(1.0, 0.3, 0.2)
	else:
		mat.albedo_color = _base_material_color
	
	# Scale up slightly
	var scale_pulse = 1.0 + (1.0 - _telegraph_timer / telegraph_duration) * 0.2
	_mesh.scale = Vector3(scale_pulse, scale_pulse, scale_pulse)

func _execute_attack() -> void:
	_state = State.ATTACK
	_attack_timer = attack_cooldown
	
	if _damage_source:
		_damage_source.monitoring = true
		get_tree().create_timer(0.2).timeout.connect(_disable_damage_source)
	
	# Play attack sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "organic", 8.0)
	
	# Attack lunge
	if _target:
		var to_target = (_target.global_position - global_position).normalized()
		velocity = to_target * move_speed * 2.0

func _reset_visual() -> void:
	if not _mesh:
		return
	_mesh.scale = Vector3.ONE
	if _mesh.material_override is StandardMaterial3D:
		(_mesh.material_override as StandardMaterial3D).albedo_color = _base_material_color

func _update_stun_visual() -> void:
	if not _mesh:
		return
	# Wobble while stunned
	var wobble = sin(Time.get_ticks_msec() * 0.02) * 0.1
	_mesh.rotation.z = wobble

func _flash_on_hit() -> void:
	if not _mesh or not _mesh.material_override:
		return
	var mat = _mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1.0, 1.0, 1.0)
		get_tree().create_timer(0.1).timeout.connect(func():
			if mat:
				mat.albedo_color = _base_material_color
		)

func _move_toward_target(delta: float) -> void:
	if not _target:
		return
	var dir = _target.global_position - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		var desired_velocity = dir.normalized() * move_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)

func _disable_damage_source() -> void:
	if _damage_source:
		_damage_source.monitoring = false
	_state = State.ALERT  # Return to chase after attack

func _on_died() -> void:
	FXHelper.spawn_burst(get_parent(), global_position, Color(0.6, 0.3, 0.2))
	destroyed.emit(global_position)
	queue_free()

