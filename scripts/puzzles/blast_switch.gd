extends Area3D
class_name BlastSwitch

signal toggled(active: bool)

@export var is_active: bool = false
@export var required_impulse: float = 0.0
@export var active_color: Color = Color(0.2, 1.0, 0.3)
@export var inactive_color: Color = Color(1.0, 0.2, 0.2)
@export var active_energy: float = 2.5
@export var inactive_energy: float = 0.5

@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

func _ready() -> void:
	_update_feedback(false)

func apply_blast_impulse(impulse: Vector3) -> void:
	if required_impulse > 0.0 and impulse.length() < required_impulse:
		return
	toggle()

func toggle() -> void:
	set_active(!is_active)

func set_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	_update_feedback(true)
	emit_signal("toggled", is_active)

func _update_feedback(play_sound: bool) -> void:
	if indicator_light:
		indicator_light.light_color = active_color if is_active else inactive_color
		indicator_light.light_energy = active_energy if is_active else inactive_energy
	if play_sound:
		_play_toggle_sound()

func _play_toggle_sound() -> void:
	if not audio_player:
		return
	if audio_player.stream == null:
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = 44100
		audio_player.stream = generator
	if not audio_player.playing:
		audio_player.play()
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return

	var mix_rate = 44100.0
	var duration = 0.08
	var frames = int(duration * mix_rate)
	var frequency = 880.0 if is_active else 440.0
	var amplitude = 0.2
	for i in range(frames):
		var t = float(i) / mix_rate
		var sample = sin(TAU * frequency * t) * amplitude
		playback.push_frame(AudioFrame(sample, sample))
