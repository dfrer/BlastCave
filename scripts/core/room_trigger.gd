extends Area3D
class_name RoomTrigger

@export var room_tags: PackedStringArray = []
@export var room_type: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name != "PlayerObject":
		return
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if not run_manager:
		return
	if "reward" in room_tags:
		run_manager._show_reward_selection()
	elif "shop" in room_tags:
		run_manager.show_shop_menu()
	elif "boss" in room_tags:
		run_manager._update_hud_objective()
	# Use set_deferred to avoid "Function blocked during in/out signal" error
	set_deferred("monitoring", false)
