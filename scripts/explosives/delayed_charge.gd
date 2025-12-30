extends ExplosiveBase
class_name DelayedCharge

## Delayed charge with visual countdown timer
## Shows pulsing glow and beeping as countdown progresses

@export var delay_seconds: float = 2.0

var _time_remaining: float = 0.0
var _countdown_active: bool = false
var _mesh: MeshInstance3D
var _base_emission: float = 1.5
var _beep_interval: float = 0.5
var _last_beep_time: float = 0.0
var _countdown_label: Label3D

func _ready():
	explosive_type = "DelayedCharge"
	_time_remaining = delay_seconds
	
	if is_preview:
		return
	
	_mesh = get_node_or_null("Mesh")
	if not _mesh:
		_mesh = get_node_or_null("MeshInstance3D")
	
	_create_countdown_label()
	_countdown_active = true

func _process(delta: float) -> void:
	if not _countdown_active or is_preview:
		return
	
	_time_remaining -= delta
	
	# Update visual countdown
	_update_countdown_visual()
	
	# Play beeps with increasing frequency
	_update_beeps()
	
	# Update label
	if _countdown_label:
		_countdown_label.text = "%.1f" % maxf(_time_remaining, 0.0)
	
	if _time_remaining <= 0:
		_on_timeout()

func _create_countdown_label() -> void:
	_countdown_label = Label3D.new()
	_countdown_label.text = "%.1f" % delay_seconds
	_countdown_label.font_size = 48
	_countdown_label.position = Vector3(0, 0.5, 0)
	_countdown_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_countdown_label.modulate = Color(1.0, 0.4, 0.6)
	_countdown_label.outline_size = 4
	add_child(_countdown_label)

func _update_countdown_visual() -> void:
	if not _mesh or not _mesh.material_override:
		return
	
	var mat = _mesh.material_override as StandardMaterial3D
	if not mat or not mat.emission_enabled:
		return
	
	# Calculate countdown progress (0 = just started, 1 = about to explode)
	var progress = 1.0 - (_time_remaining / delay_seconds)
	
	# Pulsing effect - faster as countdown progresses
	var pulse_speed = 2.0 + (progress * 8.0)
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.001 * pulse_speed * TAU) * 0.5
	
	# Increase emission as countdown progresses
	var emission_mult = _base_emission + (progress * 3.0) + (pulse * 2.0)
	mat.emission_energy_multiplier = emission_mult
	
	# Shift color towards red as time runs out
	var end_color = Color(1.0, 0.2, 0.1)
	var start_color = Color(0.9, 0.3, 0.6)
	mat.emission = start_color.lerp(end_color, progress)

func _update_beeps() -> void:
	# Beep interval decreases as countdown progresses
	var progress = 1.0 - (_time_remaining / delay_seconds)
	var current_interval = _beep_interval * (1.0 - progress * 0.7)
	current_interval = maxf(current_interval, 0.1)
	
	var time_since_last = delay_seconds - _time_remaining - _last_beep_time
	if time_since_last >= current_interval:
		_last_beep_time = delay_seconds - _time_remaining
		_play_beep()

func _play_beep() -> void:
	if AudioManager.instance:
		AudioManager.instance.play_ui("click", -6.0)

func _on_timeout():
	_countdown_active = false
	explode()
	queue_free()

func trigger():
	# Manual trigger can speed up the countdown or detonate immediately
	if _time_remaining > 0.5:
		_time_remaining = 0.5  # Quick detonate
	else:
		_on_timeout()

