extends Node3D
class_name EnemySpawner

@export var spawn_scenes: Array[PackedScene] = []
@export var spawn_points: Array[NodePath] = []
@export var max_alive: int = 4
@export var spawn_interval: float = 3.5
@export var initial_burst: int = 2

var _spawned: Array = []
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	call_deferred("_start_spawning")

func _start_spawning() -> void:
	for _i in range(initial_burst):
		_spawn_enemy()
	_timer.start()

func _on_timeout() -> void:
	_spawn_enemy()

func _spawn_enemy() -> void:
	if not is_inside_tree():
		return
	_cleanup_spawned()
	if _spawned.size() >= max_alive:
		return
	if spawn_scenes.is_empty():
		return
	var scene = spawn_scenes[randi() % spawn_scenes.size()]
	if scene == null:
		return
	var instance = scene.instantiate() as Node3D
	if not instance:
		return
	var spawn_pos = _resolve_spawn_position()
	var parent_node = get_parent()
	if not parent_node:
		return
	parent_node.add_child(instance)
	instance.global_position = spawn_pos
	_spawned.append(instance)

func _cleanup_spawned() -> void:
	_spawned = _spawned.filter(func(node): return node != null and is_instance_valid(node))

func _pick_spawn_point() -> Node3D:
	if spawn_points.is_empty():
		return null
	var path = spawn_points[randi() % spawn_points.size()]
	return get_node_or_null(path) as Node3D

func _resolve_spawn_position() -> Vector3:
	var spawn_pos = global_position
	var point = _pick_spawn_point()
	if point and point.is_inside_tree():
		spawn_pos = point.global_position
	return spawn_pos
