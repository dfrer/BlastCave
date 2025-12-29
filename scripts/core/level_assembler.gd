extends Node3D
class_name LevelAssembler

@export var use_generator: bool = false
@export var generator_path: NodePath = NodePath("CaveGenerator")
@export var entry_group: StringName = &"chunk_entry"
@export var exit_group: StringName = &"chunk_exit"

func _ready() -> void:
	if not use_generator:
		return
	assemble_level()

func assemble_level() -> void:
	var generator := get_node_or_null(generator_path) as CaveGenerator
	if not generator:
		generator = CaveGenerator.new()

	var rooms := generator.generate_cave()
	if rooms.is_empty():
		return

	var previous_exit: Marker3D = null
	for room_scene in rooms:
		if room_scene == null:
			continue
		var room := room_scene.instantiate() as Node3D
		if not room:
			continue

		add_child(room)
		var entry_marker := _get_marker(room, entry_group)
		var exit_marker := _get_marker(room, exit_group)

		if previous_exit and entry_marker:
			var offset := previous_exit.global_position - entry_marker.global_position
			room.global_position += offset
		elif entry_marker:
			room.global_position -= entry_marker.global_position

		if exit_marker:
			previous_exit = exit_marker

func _get_marker(room: Node, group_name: StringName) -> Marker3D:
	if group_name.is_empty():
		return null
	var markers := room.get_tree().get_nodes_in_group(group_name)
	for marker in markers:
		if marker is Marker3D and room.is_ancestor_of(marker):
			return marker
	return null
