extends RigidBody3D
class_name CharacterObject

var blast_response: float = 1.0
var current_character_id: String = ""
var ability: String = "none"

var is_pinned: bool = false
var pin_duration_remaining: float = 0.0
var pin_cooldown_remaining: float = 0.0

var characters_data: Dictionary = {}
var movement_controller: PlayerMovement

func _ready():
	_load_characters()
	# Optional: Set default if not set by run_start
	if current_character_id == "":
		set_character("core")
	if not movement_controller:
		movement_controller = PlayerMovement.new()
		movement_controller.name = "PlayerMovement"
		add_child(movement_controller)

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
		
		if not physics_material_override:
			physics_material_override = PhysicsMaterial.new()
		physics_material_override.friction = data.get("friction", 0.5)
		
		# Reset ability state
		is_pinned = false
		freeze = false
		pin_duration_remaining = 0.0
		pin_cooldown_remaining = 0.0
		
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
	# Ability: Gyro Stabilize
	if ability == "gyro_stabilize":
		angular_velocity *= 0.95
	
	# Ability: Anchor Pin
	if pin_cooldown_remaining > 0:
		pin_cooldown_remaining -= delta
		
	if is_pinned:
		pin_duration_remaining -= delta
		if pin_duration_remaining <= 0:
			unpin()
			
	if ability == "anchor_pin" and Input.is_key_pressed(KEY_F) and not is_pinned and pin_cooldown_remaining <= 0:
		pin()

func pin():
	is_pinned = true
	freeze = true
	pin_duration_remaining = 2.0
	print("Anchor Pin Active! (2s)")

func unpin():
	is_pinned = false
	freeze = false
	pin_cooldown_remaining = 6.0
	print("Anchor Pin Released. Cooldown (6s)...")
