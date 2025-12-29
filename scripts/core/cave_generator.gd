extends Node
class_name CaveGenerator

enum MetaTag { NONE, NO_RETURN, COSTLY_RETURN }

@export var room_scenes: Array[PackedScene] = [
	preload("res://scenes/levels/room_01_intro.tscn"),
	preload("res://scenes/levels/room_02_traversal.tscn"),
	preload("res://scenes/levels/room_03_exit.tscn"),
	preload("res://scenes/levels/room_04_boss.tscn")
]

func generate_cave() -> Array[PackedScene]:
	# Linear placeholder generation until procedural stitching is ready.
	return room_scenes.duplicate()

func stitch_chunk(_chunk_scene: PackedScene, _tags: Array[MetaTag]):
	# Logic for adding a chunk based on metadata
	pass
