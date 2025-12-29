extends Area3D
class_name DamageSource

@export var damage_amount: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var health_component = _find_health_component(body)
	if health_component:
		health_component.take_damage(damage_amount)
		if body is Node3D:
			FXHelper.spawn_burst(body.get_parent(), body.global_position, Color(1.0, 0.2, 0.2))
			FXHelper.spawn_sfx(body.get_parent(), body.global_position, 0.9)

func _find_health_component(target: Node) -> HealthComponent:
	if target is HealthComponent:
		return target
	if target.has_node("HealthComponent"):
		return target.get_node("HealthComponent") as HealthComponent
	return target.find_child("HealthComponent", true, false) as HealthComponent
