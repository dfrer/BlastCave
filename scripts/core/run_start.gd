extends Node

var current_selection: String = "core"
var selections: Array = ["core", "slug", "shard", "anchor", "gyro"]
@onready var game_flow = get_node("/root/GameFlow")

func _ready():
	print("--- BLAST CAVE: RUN START ---")
	print("Select character with keys 1-5.")
	print("1:Core, 2:Slug, 3:Shard, 4:Anchor, 5:Gyro")
	print("Default: ", current_selection)
	print("Press ENTER to start run and spawn player.")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			start_run()
	
	# Use input actions for character selection
	if Input.is_action_just_pressed("select_char_1"): _set_selection(0)
	if Input.is_action_just_pressed("select_char_2"): _set_selection(1)
	if Input.is_action_just_pressed("select_char_3"): _set_selection(2)
	if Input.is_action_just_pressed("select_char_4"): _set_selection(3)
	if Input.is_action_just_pressed("select_char_5"): _set_selection(4)

func _set_selection(index: int):
	current_selection = selections[index]
	print("Selected Character: ", current_selection)

func start_run():
	print("Starting Run with: ", current_selection)
	if game_flow:
		game_flow.set_state(game_flow.State.RUNNING)
	
	# Find essential nodes in the scene tree
	var root = get_tree().current_scene
	if not root:
		print("Error: No current scene found.")
		return
		
	var player = root.find_child("PlayerObject", true, false)
	var spawn_point = root.find_child("SpawnPoint", true, false)
	
	if player and player is RigidBody3D:
		var spawn_pos = Vector3(0, 2, 0)
		
		# Try to find a dynamic spawn point from the level assembly
		var entries = get_tree().get_nodes_in_group("chunk_entry")
		var found_dynamic_spawn = false
		for entry in entries:
			if entry is Marker3D:
				spawn_pos = entry.global_position
				# Offset inward so we don't spawn on the wall/boundary
				spawn_pos.z -= 2.0
				spawn_pos.y += 0.5  # Slight vertical offset for safety
				found_dynamic_spawn = true
				print("Found dynamic spawn point (chunk_entry): ", entry.global_position, " -> Offset to: ", spawn_pos)
				break
		
		if not found_dynamic_spawn:
			if spawn_point:
				spawn_pos = spawn_point.global_position
				print("Using fallback SpawnPoint node: ", spawn_pos)
			else:
				print("No spawn point found, using default: ", spawn_pos)
		
		# Validate spawn position with raycast to ensure not inside geometry
		spawn_pos = _validate_spawn_position(player, spawn_pos)
		
		# Reset position and motion
		player.linear_velocity = Vector3.ZERO
		player.angular_velocity = Vector3.ZERO
		player.global_position = spawn_pos
		
		# Apply character profile
		if player.has_method("set_character"):
			player.set_character(current_selection)
		
		print("Player final spawn position: ", player.global_position)
		
	else:
		print("Error: Could not find PlayerObject.")

func _validate_spawn_position(player: RigidBody3D, spawn_pos: Vector3) -> Vector3:
	var space_state = player.get_world_3d().direct_space_state
	if not space_state:
		return spawn_pos
	
	# Cast ray downward to find ground
	var from = spawn_pos + Vector3.UP * 2.0
	var to = spawn_pos + Vector3.DOWN * 2.0
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	var result = space_state.intersect_ray(query)
	
	if result:
		# Found ground, spawn slightly above it
		var ground_pos = result.position
		return ground_pos + Vector3.UP * 1.0
	
	# Cast ray from origin to spawn_pos to check for obstacles
	var center_query = PhysicsRayQueryParameters3D.create(Vector3(0, 5, 0), spawn_pos)
	center_query.exclude = [player]
	var center_result = space_state.intersect_ray(center_query)
	
	if center_result:
		# Hit something, spawn at hit point with offset
		return center_result.position + center_result.normal * 1.5
	
	return spawn_pos
