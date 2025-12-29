extends Node3D
class_name BossController

@export var gate_path: NodePath
@export var reward_scene: PackedScene
@export var reward_spawn_path: NodePath
@export var reset_delay: float = 8.0

@onready var reset_timer: Timer = get_node_or_null("ResetTimer")

var _targets: Array[BossBlastTarget] = []
var _completed: bool = false
var _reward_spawned: bool = false

func _ready() -> void:
	_collect_targets()
	_setup_timer()
	_update_gate_state(false)

func _collect_targets() -> void:
	_targets.clear()
	for child in get_children():
		if child is BossBlastTarget:
			_targets.append(child)
			child.connect("activated", Callable(self, "_on_target_activated"))

func _setup_timer() -> void:
	if not reset_timer:
		return
	reset_timer.wait_time = reset_delay
	reset_timer.one_shot = true
	if not reset_timer.is_connected("timeout", Callable(self, "_on_reset_timeout")):
		reset_timer.connect("timeout", Callable(self, "_on_reset_timeout"))

func _on_target_activated(_target: BossBlastTarget) -> void:
	if _completed:
		return
	_restart_reset_timer()
	if _all_targets_active():
		_complete_encounter()

func _all_targets_active() -> bool:
	if _targets.is_empty():
		return false
	for target in _targets:
		if not target.is_active:
			return false
	return true

func _restart_reset_timer() -> void:
	if reset_timer:
		reset_timer.start()

func _complete_encounter() -> void:
	_completed = true
	if reset_timer:
		reset_timer.stop()
	_update_gate_state(true)
	_spawn_reward_if_needed()

func _on_reset_timeout() -> void:
	if _completed:
		return
	for target in _targets:
		target.reset_target()
	_update_gate_state(false)

func _update_gate_state(open: bool) -> void:
	var gate = get_node_or_null(gate_path)
	if gate and gate.has_method("set_open"):
		gate.set_open(open, true)

func _spawn_reward_if_needed() -> void:
	if _reward_spawned or reward_scene == null:
		return
	var spawn_parent: Node = get_parent()
	if reward_spawn_path != NodePath():
		var explicit_parent = get_node_or_null(reward_spawn_path)
		if explicit_parent:
			spawn_parent = explicit_parent
	var reward = reward_scene.instantiate()
	spawn_parent.add_child(reward)
	if reward is Node3D:
		reward.global_transform = global_transform
	_reward_spawned = true
