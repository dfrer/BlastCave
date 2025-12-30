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
var _look_target: Vector3 = Vector3.ZERO
var _has_look_target: bool = false
@export var look_speed: float = 8.0

# Eye feedback system
var _eye_main: MeshInstance3D
var _explosive_colors: Dictionary = {
	"ImpulseCharge": Color(0.1, 0.9, 0.6),
	"ShapedCharge": Color(0.95, 0.8, 0.1),
	"DelayedCharge": Color(0.9, 0.2, 0.8)
}

func _ready():
	_load_characters()
	# Optional: Set default if not set by run_start
	if current_character_id == "":
		set_character("core")
	if not movement_controller:
		movement_controller = PlayerMovement.new()
		movement_controller.name = "PlayerMovement"
		add_child(movement_controller)
	# Find HeadPivot for look-at
	_head_pivot = get_node_or_null("HeadPivot")
	# Find EyeMain for color feedback
	if _head_pivot:
		_eye_main = _head_pivot.get_node_or_null("EyeMain") as MeshInstance3D

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
		physics_material_override.friction = data.get("friction", 0.5)
		
		# Reset ability state
		is_pinned = false
		freeze = false
		pin_duration_remaining = 0.0
		pin_cooldown_remaining = 0.0
		ability_cooldown_remaining = 0.0
		_emit_ability_state()
		
		print("Character set: ", data.get("display_name", character_id))
	else:
		# Fallback if JSON failed or ID missing
		if characters_data.is_empty(): _load_characters()
		if characters_data.has(character_id):
			set_character(character_id)
		else:
			print("Error: Could not find character ", character_id)

func get_current_id() -> String:
	return current_character_id

func _physics_process(delta):
	if movement_controller and not is_pinned:
		movement_controller.apply_movement(self, delta)
	if ability_cooldown_remaining > 0.0:
		ability_cooldown_remaining = maxf(ability_cooldown_remaining - delta, 0.0)
		_emit_cooldown()
	if _gyro_active_remaining > 0.0:
		_gyro_active_remaining = maxf(_gyro_active_remaining - delta, 0.0)
	# Ability: Gyro Stabilize
	if ability == "gyro_stabilize":
		if _gyro_active_remaining > 0.0:
			angular_velocity *= lerp(1.0, 0.75, ability_power)
		else:
			angular_velocity *= 0.95
	
	# Ability: Anchor Pin
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
	# Calculate direction from head to target in local space of the RigidBody
	var head_global_pos = _head_pivot.global_position
	var direction = (_look_target - head_global_pos).normalized()
	if direction.length_squared() < 0.001:
		return
	# Convert to local space for rotation
	var local_dir = global_transform.basis.inverse() * direction
	# Calculate target rotation (only Y-axis yaw, limited X-axis pitch)
	var target_yaw = atan2(local_dir.x, local_dir.z)
	var target_pitch = -asin(clampf(local_dir.y, -0.8, 0.8))
	# Smooth interpolation
	var current_rot = _head_pivot.rotation
	_head_pivot.rotation.y = lerp_angle(current_rot.y, target_yaw, look_speed * delta)
	_head_pivot.rotation.x = lerp(current_rot.x, target_pitch, look_speed * delta)

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
