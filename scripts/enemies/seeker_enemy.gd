extends CharacterBody3D
class_name SeekerEnemy

## Fast, agile enemy that chases the player and can leap

signal destroyed(position: Vector3)

enum State { IDLE, SEEKING, LEAPING, STUNNED }

@export var move_speed: float = 5.0
@export var acceleration: float = 15.0
@export var detection_range: float = 15.0
@export var leap_range: float = 6.0
@export var leap_force: float = 12.0
@export var leap_cooldown: float = 2.5
@export var knockback_multiplier: float = 1.5
@export var contact_damage: int = 12
@export var max_health: float = 25.0

var blast_response: float = 1.3  # Takes more knockback
var current_health: float
var _target: Node3D
var _state: int = State.IDLE
var _leap_timer: float = 0.0
var _stun_timer: float = 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	current_health = max_health
	_target = get_tree().get_root().find_child("PlayerObject", true, false)
	_mesh = get_node_or_null("Mesh")
	
	# Connect damage dealing
	var damage_area = get_node_or_null("DamageArea")
	if damage_area:
		damage_area.body_entered.connect(_on_body_contact)

func _physics_process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_root().find_child("PlayerObject", true, false)
		return
	
	# Handle stun
	if _stun_timer > 0.0:
		_stun_timer -= delta
		_state = State.STUNNED
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return
	
	# Update leap cooldown
	if _leap_timer > 0.0:
		_leap_timer -= delta
	
	var distance = _get_target_distance()
	var to_target = _target.global_position - global_position
	
	# State machine
	match _state:
		State.IDLE:
			if distance <= detection_range:
				_state = State.SEEKING
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		
		State.SEEKING:
			if distance > detection_range:
				_state = State.IDLE
			elif distance <= leap_range and _leap_timer <= 0:
				_start_leap(to_target)
			else:
				_move_toward_target(delta)
		
		State.LEAPING:
			# Leaping - check if we've landed
			if is_on_floor():
				_state = State.SEEKING
				_leap_timer = leap_cooldown
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	
	# Visual feedback - glow when about to leap
	_update_visuals()
	
	move_and_slide()

func _get_target_distance() -> float:
	if not _target:
		return INF
	return global_position.distance_to(_target.global_position)

func _move_toward_target(delta: float) -> void:
	if not _target:
		return
	
	var dir = _target.global_position - global_position
	dir.y = 0.0
	
	if dir.length() > 0.5:
		var desired_velocity = dir.normalized() * move_speed
		velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
		
		# Face target
		look_at(_target.global_position, Vector3.UP)
		rotation.x = 0
		rotation.z = 0

func _start_leap(to_target: Vector3) -> void:
	_state = State.LEAPING
	
	# Calculate leap velocity
	var horizontal_dir = Vector3(to_target.x, 0, to_target.z).normalized()
	var leap_velocity = horizontal_dir * leap_force * 0.7
	leap_velocity.y = leap_force * 0.5
	
	velocity = leap_velocity
	
	# Play leap sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "organic", 6.0)

func _update_visuals() -> void:
	if not _mesh or not _mesh.material_override:
		return
	
	var mat = _mesh.material_override as StandardMaterial3D
	if not mat or not mat.emission_enabled:
		return
	
	# Glow more intensely when about to leap
	if _state == State.SEEKING and _leap_timer <= 0:
		mat.emission_energy_multiplier = 2.5 + sin(Time.get_ticks_msec() * 0.01) * 1.0
	elif _state == State.LEAPING:
		mat.emission_energy_multiplier = 4.0
	else:
		mat.emission_energy_multiplier = 1.5

func _on_body_contact(body: Node3D) -> void:
	if body == _target:
		# Deal damage to player
		if body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			if health.has_method("take_damage"):
				var impulse = (body.global_position - global_position).normalized() * 5.0
				health.take_damage(contact_damage, impulse, body.global_position)

func apply_blast_impulse(impulse: Vector3) -> void:
	velocity += impulse * knockback_multiplier
	_stun_timer = 0.8
	take_damage(impulse.length() * 0.3)

func take_damage(damage: float) -> void:
	current_health -= damage
	
	# Flash red
	_flash_damage()
	
	if current_health <= 0:
		_destroy()

func _flash_damage() -> void:
	if not _mesh or not _mesh.material_override:
		return
	var mat = _mesh.material_override as StandardMaterial3D
	if mat:
		mat.emission = Color(1.0, 0.2, 0.2)
		get_tree().create_timer(0.1).timeout.connect(func():
			if mat:
				mat.emission = Color(0.8, 0.4, 0.9)
		)

func _destroy() -> void:
	FXHelper.spawn_burst(get_parent(), global_position, Color(0.8, 0.3, 0.9))
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "organic", 12.0)
	destroyed.emit(global_position)
	queue_free()
