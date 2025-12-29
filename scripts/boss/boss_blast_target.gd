extends Area3D
class_name BossBlastTarget

signal activated(target: BossBlastTarget)
signal reset(target: BossBlastTarget)

@export var is_active: bool = false
@export var required_impulse: float = 0.0
@export var active_color: Color = Color(0.2, 1.0, 0.3)
@export var inactive_color: Color = Color(1.0, 0.2, 0.2)
@export var active_energy: float = 2.5
@export var inactive_energy: float = 0.5

@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	_update_feedback()

func apply_blast_impulse(impulse: Vector3) -> void:
	if required_impulse > 0.0 and impulse.length() < required_impulse:
		return
	set_active(true)

func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	_update_feedback()
	if is_active:
		emit_signal("activated", self)
	else:
		emit_signal("reset", self)

func reset_target() -> void:
	set_active(false)

func _update_feedback() -> void:
	if indicator_light:
		indicator_light.light_color = active_color if is_active else inactive_color
		indicator_light.light_energy = active_energy if is_active else inactive_energy
	if mesh_instance and mesh_instance.material_override is StandardMaterial3D:
		var material := mesh_instance.material_override as StandardMaterial3D
		material.albedo_color = active_color if is_active else inactive_color
