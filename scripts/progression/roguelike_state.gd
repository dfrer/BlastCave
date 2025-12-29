extends Node
class_name RoguelikeState

var current_depth: int = 0
var upgrades: Array = []
var _start_time_msec: int = 0
var _end_time_msec: int = 0

func start_run() -> void:
	current_depth = 0
	upgrades.clear()
	_start_time_msec = Time.get_ticks_msec()
	_end_time_msec = 0

func end_run() -> void:
	if _end_time_msec == 0:
		_end_time_msec = Time.get_ticks_msec()

func advance_depth() -> void:
	current_depth += 1

func add_upgrade(upgrade_data: Dictionary) -> void:
	upgrades.append(upgrade_data)

func get_elapsed_time_seconds() -> float:
	var end_time = _end_time_msec
	if end_time == 0:
		end_time = Time.get_ticks_msec()
	return float(end_time - _start_time_msec) / 1000.0
