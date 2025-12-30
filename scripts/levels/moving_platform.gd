extends AnimatableBody3D
class_name MovingPlatform

@export var move_to_vector: Vector3 = Vector3(0, 5, 0)
@export var speed: float = 2.0
@export var pause_time: float = 1.0
@export var active: bool = true

var _start_pos: Vector3
var _target_pos: Vector3
var _direction: int = 1
var _wait_timer: float = 0.0
var _current_t: float = 0.0

func _ready():
	_start_pos = global_position
	_target_pos = _start_pos + move_to_vector

func _physics_process(delta):
	if not active:
		return
		
	if _wait_timer > 0:
		_wait_timer -= delta
		return
		
	var dist_total = _start_pos.distance_to(_target_pos)
	if dist_total < 0.01:
		return
		
	var move_step = speed * delta / dist_total
	
	if _direction == 1:
		_current_t += move_step
		if _current_t >= 1.0:
			_current_t = 1.0
			_direction = -1
			_wait_timer = pause_time
	else:
		_current_t -= move_step
		if _current_t <= 0.0:
			_current_t = 0.0
			_direction = 1
			_wait_timer = pause_time
			
	# Quintic or Cubic easing for smoother motion
	var t_eased = _ease_in_out_sine(_current_t)
	global_position = _start_pos.lerp(_target_pos, t_eased)

func _ease_in_out_sine(x: float) -> float:
	return -(cos(PI * x) - 1) / 2
