extends Node
class_name BouncePadLogic

## Enhanced bounce pad for rolling gameplay
## Adds velocity preservation and directional bouncing

@export var bounce_force: float = 22.0  # Increased from 15.0
@export var bounce_area: Area3D
@export var velocity_preservation: float = 0.6  # How much incoming speed is added
@export var directional_mode: bool = false  # If true, bounce in pad's forward direction
@export var directional_strength: float = 0.7  # Blend between up and forward

# Visual feedback
var _base_emission: float = 2.0
var _bounce_emission: float = 6.0
var _top_mesh: MeshInstance3D
var _cooldown: float = 0.0  # Prevent double-bouncing
const BOUNCE_COOLDOWN: float = 0.15

func _ready() -> void:
	if bounce_area:
		bounce_area.body_entered.connect(_on_body_entered)
	
	# Find the glowing top mesh for visual feedback
	_top_mesh = get_parent().get_node_or_null("Top")

func _process(delta: float) -> void:
	if _cooldown > 0:
		_cooldown -= delta

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and _cooldown <= 0:
		_bounce_body(body)
		_cooldown = BOUNCE_COOLDOWN

func _bounce_body(body: RigidBody3D) -> void:
	var incoming_speed = body.linear_velocity.length()
	var incoming_vertical = max(0, -body.linear_velocity.y)  # Only count downward velocity
	
	# Calculate bounce direction
	var bounce_dir: Vector3
	if directional_mode:
		# Blend between up and pad's forward direction
		var pad_forward = -get_parent().global_transform.basis.z
		bounce_dir = Vector3.UP.lerp(pad_forward, directional_strength).normalized()
	else:
		bounce_dir = Vector3.UP
	
	# Calculate bounce strength
	# Base force + portion of incoming velocity
	var speed_bonus = incoming_speed * velocity_preservation
	var vertical_bonus = incoming_vertical * 0.3  # Extra boost for falling onto pad
	var total_force = bounce_force + speed_bonus + vertical_bonus
	
	# Apply impulse
	var impulse = bounce_dir * total_force
	
	# Cancel downward velocity first for cleaner bounce
	if body.linear_velocity.y < 0:
		body.linear_velocity.y = 0
	
	body.apply_central_impulse(impulse)
	
	# Preserve some horizontal momentum
	# (Already preserved since we only zeroed Y)
	
	# Play bounce effect
	_play_bounce_effect(body.global_position)

func _play_bounce_effect(position: Vector3) -> void:
	# Visual feedback - flash the pad brighter
	if _top_mesh and _top_mesh.material_override is StandardMaterial3D:
		var mat := _top_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = _bounce_emission
		
		# Reset after short delay
		get_tree().create_timer(0.12).timeout.connect(func():
			if mat:
				mat.emission_energy_multiplier = _base_emission
		)
	
	# Spawn particles
	FXHelper.spawn_burst(get_parent(), position + Vector3.UP * 0.3, Color(0.2, 1.0, 0.5))
	
	# Play sound
	if AudioManager.instance:
		AudioManager.instance.play_impact(position, "crystal", 10.0)
