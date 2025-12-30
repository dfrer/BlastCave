extends Area3D

@export_enum("ImpulseCharge", "ShapedCharge", "DelayedCharge") var explosive_type: String = "ImpulseCharge"
@export var amount: int = 2  # Increased default from 1 to 2
@export var scrap_value: int = 2

# Magnet effect - pickups attract to player when close
@export var magnet_range: float = 4.0
@export var magnet_strength: float = 8.0
var _player: RigidBody3D = null

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Magnet effect - move toward nearby player
	if not _player:
		_find_player()
	
	if _player:
		var dist = global_position.distance_to(_player.global_position)
		if dist < magnet_range and dist > 0.5:
			var dir = (_player.global_position - global_position).normalized()
			var pull_strength = (1.0 - dist / magnet_range) * magnet_strength
			global_position += dir * pull_strength * delta

func _find_player() -> void:
	var root = get_tree().current_scene
	if root:
		_player = root.find_child("PlayerObject", true, false) as RigidBody3D

func _on_body_entered(body: Node3D):
	if body is RigidBody3D and body.name == "PlayerObject":
		var root = get_tree().current_scene
		var inventory_node = root.find_child("PlayerInventory", true, false)
		var roguelike_state = root.find_child("RoguelikeState", true, false) as RoguelikeState
		if inventory_node and inventory_node is PlayerInventory:
			inventory_node.add_explosive(explosive_type, amount)
			inventory_node.add_scrap(scrap_value)
			if roguelike_state:
				roguelike_state.add_scrap(scrap_value)
			FXHelper.spawn_burst(get_parent(), global_position, Color(0.4, 0.9, 1.0))
			FXHelper.play_pickup_sound()
			queue_free()
