extends Node3D
class_name LevelAssembler

@export var use_generator: bool = false
@export var generator_path: NodePath = NodePath("CaveGenerator")
@export var entry_group: StringName = &"chunk_entry"
@export var exit_group: StringName = &"chunk_exit"
@export var branch_spacing: float = 22.0

@export var spawn_prob_enemy: float = 0.3
@export var spawn_prob_hazard: float = 0.2

var _enemy_scenes = [
	preload("res://scenes/enemies/basic_enemy.tscn"),
	preload("res://scenes/enemies/turret_enemy.tscn"),
	preload("res://scenes/enemies/seeker_enemy.tscn")
]

var _hazard_scenes = [
	preload("res://scenes/hazards/lava_pool.tscn"),
	preload("res://scenes/hazards/spike_trap.tscn")
]

func _ready() -> void:
	if not use_generator:
		return
	assemble_level()

func assemble_level() -> void:
	var generator := get_node_or_null(generator_path) as CaveGenerator
	if not generator:
		generator = CaveGenerator.new()

	var rooms: Array = generator.generate_cave()
	if rooms.is_empty():
		return

	var previous_exits: Dictionary = {}
	var branch_offsets: Dictionary = {0: 0.0}
	var room_exit_map: Dictionary = {}

	for room_data in rooms:
		var scene: PackedScene = null
		var metadata: Dictionary = {}
		var room_id: String = ""
		var parent_id: String = ""
		var branch_index := 0

		if room_data is PackedScene:
			scene = room_data
		elif room_data is Dictionary:
			scene = room_data.get("scene", null)
			metadata = room_data.get("meta", {})
			room_id = room_data.get("id", "")
			parent_id = room_data.get("parent_id", "")
			branch_index = metadata.get("branch_index", room_data.get("branch_index", 0))
		else:
			continue

		if scene == null:
			continue

		var room := scene.instantiate() as Node3D
		if not room:
			continue

		add_child(room)
		var entry_marker := _get_marker(room, entry_group)
		var spawn_marker: Marker3D = entry_marker
		var exit_marker := _get_marker(room, exit_group)

		var is_branch_start = not previous_exits.has(branch_index)
		var branch_offset = branch_offsets.get(branch_index, branch_spacing * branch_index)
		branch_offsets[branch_index] = branch_offset

		var previous_exit: Marker3D = previous_exits.get(branch_index, null)
		if is_branch_start and parent_id != "" and room_exit_map.has(parent_id):
			previous_exit = room_exit_map[parent_id]

		if previous_exit and spawn_marker:
			var offset := previous_exit.global_position - spawn_marker.global_position
			if is_branch_start and branch_index > 0:
				offset.x += branch_offset
			room.global_position += offset
		elif spawn_marker:
			room.global_position -= spawn_marker.global_position

		for key in metadata.keys():
			room.set_meta(key, metadata[key])
		_attach_room_trigger(room, metadata)
		
		# Apply biome coloring
		var depth = metadata.get("depth", 0)
		_apply_biome_coloring(room, depth)
		
		# Populate props
		_populate_room(room, depth)

		if exit_marker:
			previous_exits[branch_index] = exit_marker
			if room_id != "":
				room_exit_map[room_id] = exit_marker

func _populate_room(room: Node3D, depth: int) -> void:
	# Use predefined markers if available
	var prop_markers = room.find_children("PropMarker*", "Marker3D")
	if not prop_markers.is_empty():
		for marker in prop_markers:
			_spawn_prop_at(marker.global_position, depth)
		return

	# Fallback: Try to spawn in valid locations
	# This is simple/naive: Picking random points and raycasting down
	var attempts = 3 + int(depth * 0.5)
	for i in range(attempts):
		var rand_pos = room.global_position + Vector3(randf_range(-6, 6), 2, randf_range(-6, 6))
		_try_spawn_prop(rand_pos, depth)

func _try_spawn_prop(pos: Vector3, depth: int) -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * 5.0)
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		_spawn_prop_at(hit_pos, depth)

func _spawn_prop_at(pos: Vector3, depth: int) -> void:
	if randf() < spawn_prob_enemy:
		var enemy_scene = _pick_enemy(depth)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			add_child(enemy)
			enemy.global_position = pos + Vector3.UP * 0.5
	
	elif randf() < spawn_prob_hazard:
		var hazard_scene = _pick_hazard(depth)
		if hazard_scene:
			var hazard = hazard_scene.instantiate()
			add_child(hazard)
			hazard.global_position = pos

func _pick_enemy(depth: int) -> PackedScene:
	# Difficulty progression
	if depth < 2:
		return _enemy_scenes[0] # Basic
	elif depth < 5:
		return _enemy_scenes[randi() % 2] # Basic or Turret
	else:
		return _enemy_scenes[randi() % _enemy_scenes.size()] # Any

func _pick_hazard(_depth: int) -> PackedScene:
	return _hazard_scenes[randi() % _hazard_scenes.size()]

func _apply_biome_coloring(room: Node, depth: int) -> void:
	# Use MaterialLibrary for proper biome-based material and light tinting
	if MaterialLibrary.instance:
		MaterialLibrary.instance.apply_biome_to_node(room, depth)
	else:
		# Fallback to legacy light tinting
		var biome_colors = {
			0: Color(0.8, 0.9, 1.0),  # Surface - cool white
			2: Color(0.2, 0.8, 0.4),  # Toxic - green
			4: Color(0.6, 0.2, 0.9),  # Crystal - purple
			6: Color(1.0, 0.4, 0.1),  # Magma - orange
		}
		var target_color = biome_colors.get(0)
		for threshold in biome_colors.keys():
			if depth >= threshold:
				target_color = biome_colors[threshold]
		_tint_lights_recursive(room, target_color)
	
	# Start ambient effects for the room
	var biome := _get_biome_name_for_depth(depth)
	var room_id := "room_%d" % room.get_instance_id()
	FXHelper.start_room_ambient(room, room_id, biome)

func _get_biome_name_for_depth(depth: int) -> String:
	if depth < 2:
		return "cave"
	elif depth < 4:
		return "toxic"
	elif depth < 6:
		return "crystal"
	else:
		return "magma"

func _tint_lights_recursive(node: Node, color: Color) -> void:
	if node is Light3D:
		# Blend original color with target biome color
		node.light_color = node.light_color.lerp(color, 0.6)
	
	for child in node.get_children():
		_tint_lights_recursive(child, color)

func _get_marker(room: Node, group_name: StringName) -> Marker3D:
	if group_name.is_empty():
		return null
	var markers := room.get_tree().get_nodes_in_group(group_name)
	for marker in markers:
		if marker is Marker3D and room.is_ancestor_of(marker):
			return marker
	return null

func _attach_room_trigger(room: Node3D, metadata: Dictionary) -> void:
	if not metadata.has("tags"):
		return
	var tags: Array = metadata.get("tags", [])
	if tags.is_empty():
		return
	var trigger := RoomTrigger.new() as RoomTrigger
	trigger.room_tags = PackedStringArray(tags)
	trigger.room_type = metadata.get("room_type", -1)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(16.0, 6.0, 16.0)
	shape.shape = box
	trigger.add_child(shape)
	room.add_child(trigger)
