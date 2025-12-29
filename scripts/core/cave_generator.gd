extends Node
class_name CaveGenerator

enum MetaTag { NONE, NO_RETURN, COSTLY_RETURN }
enum RoomType { START, COMBAT, PUZZLE, SHOP, REWARD, BOSS, EXIT }

@export var generation_seed: int = 1337
@export var main_depth: int = 6
@export var branch_chance: float = 0.35
@export var branch_depth_min: int = 1
@export var branch_depth_max: int = 2

@export var start_scene: PackedScene = preload("res://scenes/levels/room_01_intro.tscn")
@export var combat_scene: PackedScene = preload("res://scenes/levels/room_02_traversal.tscn")
@export var puzzle_scene: PackedScene = preload("res://scenes/levels/room_02_traversal.tscn")
@export var shop_scene: PackedScene = preload("res://scenes/levels/room_02_traversal.tscn")
@export var reward_scene: PackedScene = preload("res://scenes/levels/room_02_traversal.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/levels/room_04_boss.tscn")
@export var exit_scene: PackedScene = preload("res://scenes/levels/room_03_exit.tscn")

func generate_cave() -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = generation_seed

	var rooms: Array = []
	var id_counter := 0
	var remaining_required := {
		RoomType.SHOP: 1,
		RoomType.PUZZLE: 1,
		RoomType.REWARD: 1,
	}
	var last_types: Array[RoomType] = []

	var main_length = max(main_depth, 3)
	var room_plan: Array[RoomType] = []
	room_plan.append(RoomType.START)

	for i in range(1, main_length):
		var chosen = _pick_room_type(i, last_types, remaining_required, rng)
		room_plan.append(chosen)
		last_types.append(chosen)
		if remaining_required.has(chosen):
			remaining_required[chosen] = max(remaining_required[chosen] - 1, 0)

	room_plan.append(RoomType.BOSS)
	room_plan.append(RoomType.EXIT)

	var branch_index := 1
	var room_ids: Array = []
	for idx in range(room_plan.size()):
		var room_type = room_plan[idx]
		var depth = idx
		var room_id = "room_%d" % id_counter
		id_counter += 1
		room_ids.append(room_id)
		rooms.append(_build_room_data(room_id, room_type, depth, 0, ""))

	for idx in range(1, room_plan.size() - 2):
		if rng.randf() > branch_chance:
			continue
		var branch_len = rng.randi_range(branch_depth_min, branch_depth_max)
		var parent_id = room_ids[idx]
		var branch_root_id = ""
		for branch_depth in range(branch_len):
			var branch_type = _pick_branch_type(rng)
			var branch_room_id = "room_%d" % id_counter
			id_counter += 1
			if branch_root_id == "":
				branch_root_id = branch_room_id
			var data = _build_room_data(branch_room_id, branch_type, idx + branch_depth + 1, branch_index, parent_id)
			data["meta"]["branch_depth"] = branch_depth
			data["meta"]["branch_root_id"] = branch_root_id
			data["meta"]["branch_reward_bias"] = branch_depth == branch_len - 1
			rooms.append(data)
			parent_id = branch_room_id
		branch_index += 1

	return rooms

func stitch_chunk(_chunk_scene: PackedScene, _tags: Array[MetaTag]):
	pass

func _build_room_data(room_id: String, room_type: int, depth: int, branch_index: int, parent_id: String) -> Dictionary:
	var scene = _scene_for_type(room_type)
	var meta: Dictionary = {
		"room_type": room_type,
		"depth": depth,
		"branch_index": branch_index,
		"branch": branch_index > 0,
		"difficulty_scale": 1.0 + float(depth) * 0.15,
		"tags": _tags_for_room(room_type, depth, branch_index),
		"narrative_line": _narrative_for_depth(depth)
	}
	return {
		"id": room_id,
		"parent_id": parent_id,
		"scene": scene,
		"meta": meta
	}

func _scene_for_type(room_type: int) -> PackedScene:
	match room_type:
		RoomType.START:
			return start_scene
		RoomType.COMBAT:
			return combat_scene
		RoomType.PUZZLE:
			return puzzle_scene
		RoomType.SHOP:
			return shop_scene
		RoomType.REWARD:
			return reward_scene
		RoomType.BOSS:
			return boss_scene
		RoomType.EXIT:
			return exit_scene
		_:
			return combat_scene

func _pick_room_type(depth: int, last_types: Array[RoomType], remaining_required: Dictionary, rng: RandomNumberGenerator) -> int:
	for key in remaining_required.keys():
		if remaining_required[key] > 0 and depth >= 2 and rng.randf() < 0.45:
			return key

	var pool: Array[int] = [RoomType.COMBAT, RoomType.PUZZLE, RoomType.SHOP, RoomType.REWARD]
	var last_type = last_types.back() if not last_types.is_empty() else RoomType.START
	if last_type == RoomType.SHOP:
		pool.erase(RoomType.SHOP)
	if last_type == RoomType.REWARD:
		pool.erase(RoomType.REWARD)

	return pool[rng.randi_range(0, pool.size() - 1)]

func _pick_branch_type(rng: RandomNumberGenerator) -> int:
	var pool: Array[int] = [RoomType.COMBAT, RoomType.PUZZLE, RoomType.SHOP, RoomType.REWARD]
	return pool[rng.randi_range(0, pool.size() - 1)]

func _tags_for_room(room_type: int, depth: int, branch_index: int) -> Array:
	var tags: Array = []
	if room_type == RoomType.SHOP:
		tags.append("shop")
	if room_type == RoomType.REWARD:
		tags.append("reward")
	if room_type == RoomType.BOSS:
		tags.append("boss")
	if branch_index > 0:
		tags.append("optional")
	if depth >= 4:
		tags.append("deep")
	return tags

func _narrative_for_depth(depth: int) -> String:
	var narrative_lines = [
		"Surface echoes fade. The cave hums with charge.",
		"Strange vents hiss. Your charge feels heavier.",
		"Old markings glow faintly. Something watches.",
		"The air tastes metallic. Depth pulls you down.",
		"Vault doors creak. The cave remembers the blast.",
		"Silence before the heart. Every fuse matters."
	]
	if depth < narrative_lines.size():
		return narrative_lines[depth]
	return "The abyss deepens. Your signal flickers."
