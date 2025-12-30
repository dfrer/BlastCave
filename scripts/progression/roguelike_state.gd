extends Node
class_name RoguelikeState

signal depth_changed(depth: int)
signal scrap_changed(run_scrap: int, meta_scrap: int)
signal upgrades_changed
signal synergy_activated(synergy_name: String)

# Run State
var current_depth: int = 0
var upgrades: Array = []  # List of full upgrade dictionaries
var upgrade_counts: Dictionary = {}  # id -> count for stacking
var active_synergies: Array = []
var _start_time_msec: int = 0
var _end_time_msec: int = 0
var run_scrap: int = 0

# Meta Progression
var meta_scrap: int = 0
var total_runs: int = 0
var permanent_upgrades: Array = []
var active_character_id: String = "core"

# Applied Stats (Stacked)
var explosive_force_mult: float = 1.0
var explosive_radius_mult: float = 1.0
var ability_cooldown_mult: float = 1.0
var damage_reduction: float = 0.0
var extra_jumps: int = 0
var movement_speed_mult: float = 1.0
var inventory_max_size_bonus: int = 0

# Tracked stats for current run
var stats = {
	"explosives_used": 0,
	"distance_traveled": 0.0,
	"damage_taken": 0.0,
	"enemies_defeated": 0
}

var _meta_save_path := "user://meta_progression.json"

func _ready() -> void:
	_load_meta_progression()

func start_run() -> void:
	current_depth = 0
	upgrades.clear()
	upgrade_counts.clear()
	active_synergies.clear()
	_reset_stats()
	_start_time_msec = Time.get_ticks_msec()
	_end_time_msec = 0
	run_scrap = 0
	
	_recalculate_stats()
	
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
	
	var id = upgrade_data.get("id", "unknown")
	if id in upgrade_counts:
		upgrade_counts[id] += 1
	else:
		upgrade_counts[id] = 1
	
	_recalculate_stats()
	_check_synergies()
	upgrades_changed.emit()

func add_scrap(amount: int) -> void:
	if amount <= 0:
		return
	run_scrap += amount
	scrap_changed.emit(run_scrap, meta_scrap)

func log_stat(stat_name: String, amount: float = 1.0) -> void:
	if stat_name in stats:
		stats[stat_name] += amount

func get_elapsed_time_seconds() -> float:
	var end_time = _end_time_msec
	if end_time == 0:
		end_time = Time.get_ticks_msec()
	return float(end_time - _start_time_msec) / 1000.0

func _reset_stats() -> void:
	explosive_force_mult = 1.0
	explosive_radius_mult = 1.0
	ability_cooldown_mult = 1.0
	damage_reduction = 0.0
	extra_jumps = 0
	movement_speed_mult = 1.0
	inventory_max_size_bonus = 0
	
	stats = {
		"explosives_used": 0,
		"distance_traveled": 0.0,
		"damage_taken": 0.0,
		"enemies_defeated": 0
	}

func _recalculate_stats() -> void:
	# Reset base stats
	explosive_force_mult = 1.0
	explosive_radius_mult = 1.0
	ability_cooldown_mult = 1.0
	damage_reduction = 0.0
	extra_jumps = 0
	movement_speed_mult = 1.0
	inventory_max_size_bonus = 0
	
	# Apply all upgrades with stacking logic
	for upgrade in upgrades:
		var effects = upgrade.get("effects", {})
		
		if effects.has("explosive_force_mult"):
			explosive_force_mult += float(effects["explosive_force_mult"]) - 1.0
		if effects.has("explosive_radius_mult"):
			explosive_radius_mult += float(effects["explosive_radius_mult"]) - 1.0
		if effects.has("ability_cooldown_mult"):
			# Cooldown reduction stacks multiplicatively to avoid reaching 0
			ability_cooldown_mult *= float(effects["ability_cooldown_mult"])
		if effects.has("damage_reduction"):
			damage_reduction += float(effects["damage_reduction"])
		if effects.has("extra_jumps"):
			extra_jumps += int(effects["extra_jumps"])
		if effects.has("movement_speed_mult"):
			movement_speed_mult += float(effects["movement_speed_mult"]) - 1.0
		if effects.has("inventory_size"):
			inventory_max_size_bonus += int(effects["inventory_size"])
	
	# Cap critical stats
	damage_reduction = minf(damage_reduction, 0.8)  # Max 80% reduction
	explosive_radius_mult = minf(explosive_radius_mult, 3.0) # Max 300% radius

func _check_synergies() -> void:
	# Example synergy: Blast Master (Force + Radius upgrades)
	if "force_amp" in upgrade_counts and "radius_exp" in upgrade_counts and not "blast_master" in active_synergies:
		active_synergies.append("blast_master")
		explosive_force_mult += 0.2
		explosive_radius_mult += 0.2
		synergy_activated.emit("Blast Master")
	
	# Example synergy: Demolition Expert (3+ explosive types used)
	if upgrade_counts.get("volatile_mix", 0) > 0 and upgrade_counts.get("chain_reaction", 0) > 0 and not "demolition_expert" in active_synergies:
		active_synergies.append("demolition_expert")
		explosive_force_mult += 0.3
		synergy_activated.emit("Demolition Expert")

func _load_meta_progression() -> void:
	if not FileAccess.file_exists(_meta_save_path):
		return
	var file = FileAccess.open(_meta_save_path, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		meta_scrap = int(data.get("meta_scrap", 0))
		total_runs = int(data.get("total_runs", 0))
		permanent_upgrades = data.get("permanent_upgrades", [])
		active_character_id = data.get("active_character_id", "core")

func _save_meta_progression() -> void:
	var file = FileAccess.open(_meta_save_path, FileAccess.WRITE)
	if not file:
		return
	var data = {
		"meta_scrap": meta_scrap,
		"total_runs": total_runs,
		"permanent_upgrades": permanent_upgrades,
		"active_character_id": active_character_id
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

