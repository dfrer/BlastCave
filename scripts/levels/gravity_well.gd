extends Node3D
class_name GravityWell

## Pulls rigid bodies toward its center with configurable force

@export var pull_force: float = 8.0
@export var max_pull_range: float = 4.0
@export var falloff_power: float = 2.0

var _field_area: Area3D
var _bodies_in_field: Array = []

func _ready() -> void:
	_field_area = $FieldArea
	if _field_area:
		_field_area.body_entered.connect(_on_body_entered)
		_field_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in _bodies_in_field:
		if is_instance_valid(body) and body is RigidBody3D:
			_apply_pull(body, delta)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body not in _bodies_in_field:
		_bodies_in_field.append(body)

func _on_body_exited(body: Node3D) -> void:
	_bodies_in_field.erase(body)

func _apply_pull(body: RigidBody3D, delta: float) -> void:
	var to_center = global_position - body.global_position
	var distance = to_center.length()
	
	if distance < 0.5:
		return  # Don't pull when very close
	
	# Calculate pull strength with falloff
	var normalized_dist = clampf(distance / max_pull_range, 0.0, 1.0)
	var strength = pow(1.0 - normalized_dist, falloff_power) * pull_force
	
	var pull_impulse = to_center.normalized() * strength * delta
	body.apply_central_impulse(pull_impulse)

# Animate rings
func _process(delta: float) -> void:
	var ring1 = get_node_or_null("Ring1")
	var ring2 = get_node_or_null("Ring2")
	
	if ring1:
		ring1.rotate_y(delta * 0.5)
	if ring2:
		ring2.rotate_x(delta * 0.7)
