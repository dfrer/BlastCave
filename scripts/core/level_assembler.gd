extends Node3D
class_name LevelAssembler

@export var use_generator: bool = false
@export var generator_path: NodePath = NodePath("CaveGenerator")
@export var entry_group: StringName = &"chunk_entry"
@export var exit_group: StringName = &"chunk_exit"
@export var branch_spacing: float = 22.0

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

		if exit_marker:
			previous_exits[branch_index] = exit_marker
			if room_id != "":
				room_exit_map[room_id] = exit_marker

func _apply_biome_coloring(room: Node, depth: int) -> void:
	# Biome Colors
	var surface_color = Color(0.8, 0.9, 1.0) # Cool White
	var toxic_color = Color(0.2, 0.8, 0.4)   # Toxic Green
	var crystal_color = Color(0.6, 0.2, 0.9) # Purple
	var magma_color = Color(1.0, 0.4, 0.1)   # Orange/Red
	
	var target_color = surface_color
	if depth >= 2 and depth < 4:
		target_color = toxic_color
	elif depth >= 4 and depth < 6:
		target_color = crystal_color
	elif depth >= 6:
		target_color = magma_color
		
	# Find all lights recursively
	_tint_lights_recursive(room, target_color)

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
