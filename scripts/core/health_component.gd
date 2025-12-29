extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100
@export var current_health: int = 100

func _ready() -> void:
	if current_health <= 0:
		current_health = max_health
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func is_dead() -> bool:
	return current_health <= 0
