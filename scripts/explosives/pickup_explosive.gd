extends Area3D

@export_enum("ImpulseCharge", "ShapedCharge", "DelayedCharge") var explosive_type: String = "ImpulseCharge"
@export var amount: int = 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Assuming there's a way to find the inventory. 
	# For simplicity, we'll try to find it on a parent or global.
	# But according to requirements, test_input.gd handles inventory.
	# We can broadcast a signal or find the test_input node.
	
	# Let's check if the body is the player object
	if body is RigidBody3D and body.name == "PlayerObject":
		var root = get_tree().current_scene
		var inventory_node = root.find_child("PlayerInventory", true, false)
		if inventory_node and inventory_node is PlayerInventory:
			inventory_node.add_explosive(explosive_type, amount)
			queue_free()
		else:
			# Fallback: check if the parent of player_object or similar has it
			# Or if it's a singleton (not requested but common)
			pass
