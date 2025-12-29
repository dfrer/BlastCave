extends Node
class_name PlayerInventory

signal inventory_changed

var explosives = {
	"ImpulseCharge": 5,
	"ShapedCharge": 5,
	"DelayedCharge": 5
}

func get_count(type: String) -> int:
	return explosives.get(type, 0)

func has_explosive(type: String) -> bool:
	return get_count(type) > 0

func use_explosive(type: String) -> bool:
	if has_explosive(type):
		explosives[type] -= 1
		inventory_changed.emit()
		return true
	return false

func add_explosive(type: String, amount: int = 1):
	if explosives.has(type):
		explosives[type] += amount
		inventory_changed.emit()

func get_total_count() -> int:
	var total = 0
	for count in explosives.values():
		total += count
	return total
