extends Node

var current_selection: String = "core"
var selections: Array = ["core", "slug", "shard", "anchor", "gyro"]

func _ready():
	print("--- BLAST CAVE: RUN START ---")
	print("Select character with keys 1-5.")
	print("1:Core, 2:Slug, 3:Shard, 4:Anchor, 5:Gyro")
	print("Default: ", current_selection)
	print("Press ENTER to start run and spawn player.")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: _set_selection(0)
		elif event.keycode == KEY_2: _set_selection(1)
		elif event.keycode == KEY_3: _set_selection(2)
		elif event.keycode == KEY_4: _set_selection(3)
		elif event.keycode == KEY_5: _set_selection(4)
		elif event.keycode == KEY_ENTER:
			start_run()

func _set_selection(index: int):
	current_selection = selections[index]
	print("Selected Character: ", current_selection)

func start_run():
	print("Starting Run with: ", current_selection)
	
	# Find essential nodes in the scene tree
	var root = get_tree().current_scene
	if not root:
		print("Error: No current scene found.")
		return
		
	var player = root.find_child("PlayerObject", true, false)
	var spawn_point = root.find_child("SpawnPoint", true, false)
	
	if player and player is RigidBody3D:
		var spawn_pos = Vector3(0, 2, 0)
		if spawn_point:
			spawn_pos = spawn_point.global_position
			
		# Reset position and motion
		player.linear_velocity = Vector3.ZERO
		player.angular_velocity = Vector3.ZERO
		player.global_position = spawn_pos
		
		# Apply character profile
		if player.has_method("set_character"):
			player.set_character(current_selection)
		
		print("Player moved to spawn point: ", spawn_pos)
		
		# Optional: tell other scripts run started if needed
		# But we just need test_input to keep working.
	else:
		print("Error: Could not find PlayerObject.")
