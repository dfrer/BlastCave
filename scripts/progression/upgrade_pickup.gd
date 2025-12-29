extends Area3D

@export var upgrade_id: String = "upgrade"
@export var display_name: String = "Upgrade"
@export var description: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.name == "PlayerObject":
		var run_manager = get_tree().current_scene.find_child("RunManager", true, false)
		if run_manager and run_manager.has_method("register_upgrade"):
			run_manager.register_upgrade({
				"id": upgrade_id,
				"name": display_name,
				"description": description
			})
		queue_free()
