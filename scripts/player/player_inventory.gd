extends Node
class_name PlayerInventory

signal inventory_changed
signal scrap_changed(new_scrap: int)

var explosives = {
	"ImpulseCharge": 8,  # Increased for blast-propulsion (was 5)
	"ShapedCharge": 6,   # Increased (was 5)
	"DelayedCharge": 6   # Increased (was 5)
}

var scrap: int = 0

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

func add_scrap(amount: int) -> void:
	if amount <= 0:
		return
	scrap += amount
	scrap_changed.emit(scrap)

func spend_scrap(amount: int) -> bool:
	if amount <= 0:
		return false
	if scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true

func get_total_count() -> int:
	var total = 0
	for count in explosives.values():
		total += count
	return total
