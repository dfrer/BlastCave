extends Node
class_name UpgradeDatabase

@export var upgrades_path: String = "res://data/upgrades.json"

var upgrades: Array = []

func _ready() -> void:
	_load_upgrades()

func _load_upgrades() -> void:
	var file = FileAccess.open(upgrades_path, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Array:
		upgrades = data

func get_random_upgrades(count: int, exclude_ids: Array = []) -> Array:
	if upgrades.is_empty():
		_load_upgrades()
	var pool = upgrades.filter(func(upgrade): return upgrade.get("id", "") not in exclude_ids)
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

func get_upgrade_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in upgrades:
		if upgrade.get("id", "") == upgrade_id:
			return upgrade
	return {}
