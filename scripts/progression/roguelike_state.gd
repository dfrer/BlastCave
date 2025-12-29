extends Node
class_name RoguelikeState

signal depth_changed(depth: int)
signal scrap_changed(run_scrap: int, meta_scrap: int)
signal upgrades_changed

var current_depth: int = 0
var upgrades: Array = []
var _start_time_msec: int = 0
var _end_time_msec: int = 0
var run_scrap: int = 0
var meta_scrap: int = 0
var total_runs: int = 0
var permanent_upgrades: Array = []

var explosive_force_mult: float = 1.0
var explosive_radius_mult: float = 1.0
var ability_cooldown_mult: float = 1.0

var _meta_save_path := "user://meta_progression.json"

func _ready() -> void:
	_load_meta_progression()

func start_run() -> void:
	current_depth = 0
	upgrades.clear()
	_start_time_msec = Time.get_ticks_msec()
	_end_time_msec = 0
	run_scrap = 0
	explosive_force_mult = 1.0
	explosive_radius_mult = 1.0
	ability_cooldown_mult = 1.0
	depth_changed.emit(current_depth)
	scrap_changed.emit(run_scrap, meta_scrap)

func end_run() -> void:
	if _end_time_msec == 0:
		_end_time_msec = Time.get_ticks_msec()
		total_runs += 1
		meta_scrap += run_scrap
		_save_meta_progression()
		scrap_changed.emit(run_scrap, meta_scrap)

func advance_depth() -> void:
	current_depth += 1
	depth_changed.emit(current_depth)

func add_upgrade(upgrade_data: Dictionary) -> void:
	upgrades.append(upgrade_data)
	_apply_upgrade_effects(upgrade_data)
	upgrades_changed.emit()

func add_scrap(amount: int) -> void:
	if amount <= 0:
		return
	run_scrap += amount
	scrap_changed.emit(run_scrap, meta_scrap)

func get_elapsed_time_seconds() -> float:
	var end_time = _end_time_msec
	if end_time == 0:
		end_time = Time.get_ticks_msec()
	return float(end_time - _start_time_msec) / 1000.0

func _apply_upgrade_effects(upgrade_data: Dictionary) -> void:
	if not (upgrade_data is Dictionary):
		return
	var effects = upgrade_data.get("effects", {})
	if effects.has("explosive_force_mult"):
		explosive_force_mult *= float(effects["explosive_force_mult"])
	if effects.has("explosive_radius_mult"):
		explosive_radius_mult *= float(effects["explosive_radius_mult"])
	if effects.has("ability_cooldown_mult"):
		ability_cooldown_mult *= float(effects["ability_cooldown_mult"])

func _load_meta_progression() -> void:
	var file = FileAccess.open(_meta_save_path, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		meta_scrap = data.get("meta_scrap", meta_scrap)
		total_runs = data.get("total_runs", total_runs)
		permanent_upgrades = data.get("permanent_upgrades", permanent_upgrades)

func _save_meta_progression() -> void:
	var file = FileAccess.open(_meta_save_path, FileAccess.WRITE)
	if not file:
		return
	var data = {
		"meta_scrap": meta_scrap,
		"total_runs": total_runs,
		"permanent_upgrades": permanent_upgrades
	}
	file.store_string(JSON.stringify(data))

func get_narrative_line(depth: int) -> String:
	var lines = [
		"Surface echoes fade. The cave hums with charge.",
		"Strange vents hiss. Your charge feels heavier.",
		"Old markings glow faintly. Something watches.",
		"The air tastes metallic. Depth pulls you down.",
		"Vault doors creak. The cave remembers the blast.",
		"Silence before the heart. Every fuse matters."
	]
	if depth < lines.size():
		return lines[depth]
	return "The abyss deepens. Your signal flickers."
