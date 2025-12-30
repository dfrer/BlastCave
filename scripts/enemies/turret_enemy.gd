extends StaticBody3D
class_name TurretEnemy

## Stationary turret that fires projectiles at the player
## Can be destroyed by explosions

signal destroyed(position: Vector3)

enum State { IDLE, TRACKING, FIRING, STUNNED }

@export var detection_range: float = 15.0
@export var fire_rate: float = 1.5
@export var projectile_speed: float = 12.0
@export var projectile_damage: int = 10
@export var rotation_speed: float = 2.0
@export var wind_up_time: float = 0.5
@export var max_health: float = 30.0

var current_health: float
var _state: int = State.IDLE
var _target: Node3D
var _fire_timer: float = 0.0
var _wind_up_timer: float = 0.0
var _stun_timer: float = 0.0

# Visual components
var _barrel: Node3D
var _base: MeshInstance3D
var _laser_sight: MeshInstance3D

func _ready() -> void:
	current_health = max_health
	_target = get_tree().get_root().find_child("PlayerObject", true, false)
	_barrel = get_node_or_null("Barrel")
	_base = get_node_or_null("Base")
	_laser_sight = get_node_or_null("LaserSight")
	
	if _laser_sight:
		_laser_sight.visible = false

func _physics_process(delta: float) -> void:
	if not _target:
		_target = get_tree().get_root().find_child("PlayerObject", true, false)
		return
	
	# Handle stun
	if _stun_timer > 0.0:
		_stun_timer -= delta
		_state = State.STUNNED
		return
	
	var distance = global_position.distance_to(_target.global_position)
	
	# Update state based on distance
	if distance > detection_range:
		_state = State.IDLE
		if _laser_sight:
			_laser_sight.visible = false
	else:
		_rotate_toward_target(delta)
		
		# Check if we can see the target
		if _has_line_of_sight():
			if _state == State.IDLE:
				_state = State.TRACKING
				_wind_up_timer = wind_up_time
				if _laser_sight:
					_laser_sight.visible = true
			
			if _state == State.TRACKING:
				_wind_up_timer -= delta
				if _wind_up_timer <= 0:
					_state = State.FIRING
			
			if _state == State.FIRING:
				_fire_timer -= delta
				if _fire_timer <= 0:
					_fire()
					_fire_timer = fire_rate
		else:
			_state = State.IDLE
			if _laser_sight:
				_laser_sight.visible = false

func _rotate_toward_target(delta: float) -> void:
	if not _barrel:
		return
	
	var target_dir = (_target.global_position - _barrel.global_position).normalized()
	var current_forward = -_barrel.global_transform.basis.z
	
	var angle_diff = current_forward.angle_to(target_dir)
	if angle_diff > 0.01:
		var rotation_axis = current_forward.cross(target_dir).normalized()
		if rotation_axis.length() > 0.001:
			var rotation_amount = minf(rotation_speed * delta, angle_diff)
			_barrel.rotate(rotation_axis, rotation_amount)

func _has_line_of_sight() -> bool:
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3.UP * 0.5
	var to = _target.global_position
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return false
	
	return result.collider == _target or result.collider.get_parent() == _target

func _fire() -> void:
	# Create projectile
	var projectile = _create_projectile()
	get_parent().add_child(projectile)
	projectile.global_position = _barrel.global_position + (-_barrel.global_transform.basis.z * 0.5)
	
	# Visual feedback
	_flash_barrel()
	
	# Play sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(global_position, "metal", 8.0)

func _create_projectile() -> Node3D:
	var projectile = Area3D.new()
	projectile.name = "TurretProjectile"
	
	# Collision
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.15
	shape.shape = sphere
	projectile.add_child(shape)
	
	# Visual
	var mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	mesh.mesh = sphere_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.3)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	projectile.add_child(mesh)
	
	# Velocity direction
	var direction = (-_barrel.global_transform.basis.z).normalized()
	
	# Movement script
	var script = GDScript.new()
	script.source_code = """
extends Area3D

var velocity: Vector3 = Vector3.ZERO
var damage: int = 10
var lifetime: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.has_method(\"take_damage\"):
		body.take_damage(damage, velocity.normalized(), global_position)
	elif body.has_node(\"HealthComponent\"):
		var health = body.get_node(\"HealthComponent\")
		if health.has_method(\"take_damage\"):
			health.take_damage(damage, velocity.normalized(), global_position)
	
	# Spawn impact effect
	FXHelper.spawn_sparks(get_parent(), global_position, 8)
	queue_free()
"""
	script.reload()
	projectile.set_script(script)
	projectile.set("velocity", direction * projectile_speed)
	projectile.set("damage", projectile_damage)
	
	return projectile

func _flash_barrel() -> void:
	if _barrel and _barrel.has_node("Flash"):
		var flash = _barrel.get_node("Flash") as MeshInstance3D
		if flash:
			flash.visible = true
			get_tree().create_timer(0.1).timeout.connect(func(): flash.visible = false)

## Called when hit by explosions
func apply_blast_impulse(impulse: Vector3) -> void:
	take_damage(impulse.length() * 0.5, impulse, global_position)
	_stun_timer = 0.5

func take_damage(damage: float, _impulse: Vector3, _hit_position: Vector3) -> void:
	current_health -= damage
	
	# Visual feedback
	FXHelper.spawn_sparks(get_parent(), global_position + Vector3.UP * 0.5, 12)
	
	if current_health <= 0:
		_destroy()

func _destroy() -> void:
	FXHelper.spawn_explosion(get_parent(), global_position, "ImpulseCharge")
	destroyed.emit(global_position)
	queue_free()
