extends RigidBody3D
class_name CharacterObject

signal ability_state_changed(label_text: String, cooldown_remaining: float, cooldown_max: float)
signal ability_cooldown_changed(cooldown_remaining: float, cooldown_max: float)

var blast_response: float = 1.0
var current_character_id: String = ""
var ability: String = "none"
var ability_label: String = "Ability: None"
var ability_cooldown: float = 0.0
var ability_duration: float = 0.0
var ability_power: float = 1.0
var _base_ability_cooldown: float = 0.0

var is_pinned: bool = false
var pin_duration_remaining: float = 0.0
var pin_cooldown_remaining: float = 0.0
var ability_cooldown_remaining: float = 0.0
var _gyro_active_remaining: float = 0.0

var characters_data: Dictionary = {}
var movement_controller: PlayerMovement

# Look-at system
var _head_pivot: Node3D
var _face_pivot: Node3D
var _look_target: Vector3 = Vector3.ZERO
var _has_look_target: bool = false
@export var look_speed: float = 8.0

# Sphere physics - rolling character
@export var sphere_radius: float = 0.5
## Maximum linear velocity - increased for rolling momentum
const MAX_LINEAR_VELOCITY: float = 75.0
## Momentum preservation when rolling (0-1)
@export var momentum_preservation: float = 0.98
## Bounce coefficient for surfaces
@export var bounce_coefficient: float = 0.4
## Speed threshold for reduced friction (roll faster = less grip)
@export var speed_friction_threshold: float = 8.0

# Face stabilization - keep face upright while body rolls
@export var face_stabilization_strength: float = 12.0
@export var face_stabilization_damp: float = 8.0
var _target_face_rotation: Basis = Basis.IDENTITY

# Angular velocity dampening for rolling control
@export var grounded_angular_damp: float = 0.92
const SLOW_ANGULAR_DAMP_THRESHOLD: float = 3.0
const SLOW_ANGULAR_DAMP: float = 0.85
const GROUND_CHECK_DISTANCE: float = 0.6

# Impact detection
var _last_velocity: Vector3 = Vector3.ZERO
const IMPACT_THRESHOLD: float = 10.0

# Eye feedback system
var _eye_main: MeshInstance3D
var _explosive_colors: Dictionary = {
	"ImpulseCharge": Color(0.1, 0.9, 0.6),
	"ShapedCharge": Color(0.95, 0.8, 0.1),
	"DelayedCharge": Color(0.9, 0.2, 0.8)
}

func _ready():
	_load_characters()
	if current_character_id == "":
		set_character("core")
	if not movement_controller:
		movement_controller = PlayerMovement.new()
		movement_controller.name = "PlayerMovement"
		add_child(movement_controller)
	
	# Find pivots for look-at and face stabilization
	_head_pivot = get_node_or_null("HeadPivot")
	_face_pivot = get_node_or_null("FacePivot")
	
	# Find EyeMain for color feedback
	if _head_pivot:
		_eye_main = _head_pivot.get_node_or_null("EyeMain") as MeshInstance3D
	
	# Initialize target face rotation
	_target_face_rotation = global_transform.basis

func _load_characters():
	var file = FileAccess.open("res://data/characters.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data is Dictionary:
			characters_data = data
		file.close()

func set_character(character_id: String) -> void:
	if not characters_data.is_empty() and characters_data.has(character_id):
		var data = characters_data[character_id]
		current_character_id = character_id
		
		mass = data.get("mass", 1.0)
		linear_damp = data.get("linear_damp", 0.1)
		angular_damp = data.get("angular_damp", 0.1)
		blast_response = data.get("blast_response", 1.0)
		ability = data.get("ability", "none")
		var ability_config: Dictionary = data.get("ability_config", {})
		ability_label = "Ability: %s" % ability_config.get("label", ability.capitalize())
		_base_ability_cooldown = float(ability_config.get("cooldown", 0.0))
		ability_cooldown = _base_ability_cooldown
		ability_duration = float(ability_config.get("duration", 0.0))
		ability_power = float(ability_config.get("power", 1.0))
		var roguelike_state = get_tree().get_root().find_child("RoguelikeState", true, false) as RoguelikeState
		if roguelike_state:
			ability_cooldown = _base_ability_cooldown * roguelike_state.ability_cooldown_mult
		
		if not physics_material_override:
			physics_material_override = PhysicsMaterial.new()
		physics_material_override.friction = data.get("friction", 0.3)
		physics_material_override.bounce = bounce_coefficient
		
		# Reset ability state
		is_pinned = false
		freeze = false
		pin_duration_remaining = 0.0
		pin_cooldown_remaining = 0.0
		ability_cooldown_remaining = 0.0
		_emit_ability_state()
		
		print("Character set: ", data.get("display_name", character_id))
	else:
		if characters_data.is_empty(): _load_characters()
		if characters_data.has(character_id):
			set_character(character_id)
		else:
			print("Error: Could not find character ", character_id)

func get_current_id() -> String:
	return current_character_id

func _physics_process(delta):
	# Apply movement if not pinned
	if movement_controller and not is_pinned:
		movement_controller.apply_movement(self, delta)
	
	# Sphere physics: velocity clamping and momentum
	_apply_velocity_clamping()
	_apply_rolling_physics(delta)
	
	# Keep face upright while body rolls
	_stabilize_face(delta)
	
	# Detect high-velocity impacts for feedback
	_detect_impacts()
	
	# Update ability cooldowns
	if ability_cooldown_remaining > 0.0:
		ability_cooldown_remaining = maxf(ability_cooldown_remaining - delta, 0.0)
		_emit_cooldown()
	if _gyro_active_remaining > 0.0:
		_gyro_active_remaining = maxf(_gyro_active_remaining - delta, 0.0)
	
	# Ability: Gyro Stabilize - dampen angular velocity
	if ability == "gyro_stabilize":
		if _gyro_active_remaining > 0.0:
			angular_velocity *= lerp(1.0, 0.75, ability_power)
		else:
			angular_velocity *= 0.95
	
	# Ability: Anchor Pin cooldown
	if pin_cooldown_remaining > 0:
		pin_cooldown_remaining -= delta
		ability_cooldown_remaining = pin_cooldown_remaining
		_emit_cooldown()
		
	if is_pinned:
		pin_duration_remaining -= delta
		if pin_duration_remaining <= 0:
			unpin()
			
	if ability == "anchor_pin" and Input.is_action_just_pressed("ability_activate") and not is_pinned and pin_cooldown_remaining <= 0:
		pin()
	elif ability == "gyro_stabilize" and Input.is_action_just_pressed("ability_activate") and ability_cooldown_remaining <= 0.0:
		_trigger_gyro_stabilize()
	
	# Look-at logic
	_update_head_look(delta)
	
	# Store velocity for next frame's impact detection
	_last_velocity = linear_velocity

func _apply_velocity_clamping() -> void:
	if linear_velocity.length() > MAX_LINEAR_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_LINEAR_VELOCITY

func _apply_rolling_physics(_delta: float) -> void:
	## Rolling-specific physics adjustments
	var grounded = _is_grounded()
	var speed = linear_velocity.length()
	
	# Dynamic friction based on speed - roll faster = less friction
	if grounded and physics_material_override:
		var base_friction = physics_material_override.friction
		if speed > speed_friction_threshold:
			# Reduce friction at high speeds for better momentum
			var speed_factor = clampf((speed - speed_friction_threshold) / 20.0, 0.0, 0.5)
			physics_material_override.friction = base_friction * (1.0 - speed_factor)
		else:
			# Restore base friction when slow
			var char_data = characters_data.get(current_character_id, {})
			physics_material_override.friction = char_data.get("friction", 0.3)
	
	# Angular dampening - smoother control
	if grounded:
		if speed < SLOW_ANGULAR_DAMP_THRESHOLD:
			angular_velocity *= SLOW_ANGULAR_DAMP
		else:
			angular_velocity *= grounded_angular_damp

func _stabilize_face(delta: float) -> void:
	## Keep the face/head pivots upright while the body rolls
	## This creates a "gyroscope" effect for the character's face
	
	if not _head_pivot and not _face_pivot:
		return
	
	# Calculate target rotation - face should point "forward" in world space
	# but follow the body's general direction of travel
	var move_dir = Vector3(linear_velocity.x, 0, linear_velocity.z)
	if move_dir.length_squared() > 0.5:
		# Face the direction of movement
		var target_basis = Basis.looking_at(-move_dir.normalized(), Vector3.UP)
		_target_face_rotation = _target_face_rotation.slerp(target_basis, delta * 3.0)
	
	# Apply counter-rotation to keep pivots upright
	var body_rotation_inverse = global_transform.basis.inverse()
	var world_up_local = body_rotation_inverse * Vector3.UP
	var world_forward_local = body_rotation_inverse * _target_face_rotation.z
	
	# Construct upright basis in local space
	var stable_basis = Basis()
	stable_basis.y = world_up_local.normalized()
	stable_basis.z = world_forward_local.slide(stable_basis.y).normalized()
	if stable_basis.z.length_squared() < 0.01:
		stable_basis.z = body_rotation_inverse * Vector3.FORWARD
	stable_basis.x = stable_basis.y.cross(stable_basis.z).normalized()
	stable_basis = stable_basis.orthonormalized()
	
	# Apply stabilized rotation to face pivots
	if _head_pivot:
		_head_pivot.transform.basis = _head_pivot.transform.basis.slerp(stable_basis, delta * face_stabilization_strength)
	if _face_pivot:
		_face_pivot.transform.basis = _face_pivot.transform.basis.slerp(stable_basis, delta * face_stabilization_strength)

func _is_grounded() -> bool:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return false
	var from = global_position
	var to = from + Vector3.DOWN * GROUND_CHECK_DISTANCE
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return not result.is_empty()

func _detect_impacts() -> void:
	var velocity_change = (linear_velocity - _last_velocity).length()
	if velocity_change > IMPACT_THRESHOLD:
		var impact_strength = velocity_change / IMPACT_THRESHOLD
		var contact_point = global_position + Vector3.DOWN * sphere_radius
		FXHelper.spawn_impact(get_parent(), contact_point, Vector3.UP, "rock", velocity_change)
		FXHelper.screen_shake(self, clampf(impact_strength * 0.12, 0.0, 0.4))

func pin():
	is_pinned = true
	freeze = true
	pin_duration_remaining = ability_duration if ability_duration > 0.0 else 2.0
	pin_cooldown_remaining = ability_cooldown if ability_cooldown > 0.0 else 6.0
	ability_cooldown_remaining = pin_cooldown_remaining
	print("Anchor Pin Active! (2s)")
	_emit_ability_state()

func unpin():
	is_pinned = false
	freeze = false
	pin_cooldown_remaining = ability_cooldown if ability_cooldown > 0.0 else 6.0
	ability_cooldown_remaining = pin_cooldown_remaining
	print("Anchor Pin Released. Cooldown (6s)...")
	_emit_ability_state()

func _trigger_gyro_stabilize() -> void:
	ability_cooldown_remaining = ability_cooldown if ability_cooldown > 0.0 else 5.0
	_gyro_active_remaining = ability_duration if ability_duration > 0.0 else 1.5
	_emit_ability_state()

func _emit_ability_state() -> void:
	ability_state_changed.emit(ability_label, ability_cooldown_remaining, ability_cooldown)

func _emit_cooldown() -> void:
	ability_cooldown_changed.emit(ability_cooldown_remaining, ability_cooldown)

func apply_ability_cooldown_multiplier(multiplier: float) -> void:
	if multiplier <= 0.0:
		return
	ability_cooldown = _base_ability_cooldown * multiplier
	_emit_ability_state()

# --- Look-at System ---
func set_look_target(target_pos: Vector3) -> void:
	_look_target = target_pos
	_has_look_target = true

func clear_look_target() -> void:
	_has_look_target = false

func _update_head_look(delta: float) -> void:
	if not _head_pivot or not _has_look_target:
		return
	# Note: Head looking is now handled by _stabilize_face for basic orientation
	# This adds additional pitch/yaw for looking at specific targets
	var head_global_pos = _head_pivot.global_position
	var direction = (_look_target - head_global_pos).normalized()
	if direction.length_squared() < 0.001:
		return
	# Convert to local space for rotation adjustment
	var local_dir = _head_pivot.transform.basis.inverse() * (_head_pivot.global_transform.basis.inverse() * direction)
	var target_pitch = -asin(clampf(local_dir.y, -0.6, 0.6))
	var current_rot = _head_pivot.rotation
	_head_pivot.rotation.x = lerp(current_rot.x, target_pitch, look_speed * delta * 0.5)

# --- Eye Feedback System ---
func set_explosive_type(type_name: String) -> void:
	if not _eye_main:
		return
	var color = _explosive_colors.get(type_name, Color(0.1, 0.9, 0.6))
	var mat = _eye_main.get_active_material(0)
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		mat.albedo_color = color
		mat.emission = color
		_eye_main.material_override = mat
