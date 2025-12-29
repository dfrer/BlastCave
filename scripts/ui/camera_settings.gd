extends CanvasLayer
class_name CameraSettings

@onready var orbit_slider: HSlider = $Panel/MarginContainer/VBox/OrbitSensitivity
@onready var zoom_slider: HSlider = $Panel/MarginContainer/VBox/ZoomSpeed
@onready var min_distance_slider: HSlider = $Panel/MarginContainer/VBox/MinDistance
@onready var max_distance_slider: HSlider = $Panel/MarginContainer/VBox/MaxDistance
@onready var hints_toggle: CheckBox = $Panel/MarginContainer/VBox/HintsToggle
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton

var _settings: CameraSettingsState

func _ready() -> void:
	visible = false
	_settings = get_tree().get_root().find_child("CameraSettingsState", true, false) as CameraSettingsState
	if _settings:
		_sync_from_settings()
		_settings.settings_changed.connect(_sync_from_settings)
	_connect_controls()

func _connect_controls() -> void:
	if orbit_slider:
		orbit_slider.value_changed.connect(func(value): _update_setting("orbit_sensitivity", value))
	if zoom_slider:
		zoom_slider.value_changed.connect(func(value): _update_setting("zoom_speed", value))
	if min_distance_slider:
		min_distance_slider.value_changed.connect(func(value): _update_setting("min_distance", value))
	if max_distance_slider:
		max_distance_slider.value_changed.connect(func(value): _update_setting("max_distance", value))
	if hints_toggle:
		hints_toggle.toggled.connect(func(value): _update_setting("show_input_hints", value))
	if close_button:
		close_button.pressed.connect(hide)

func _sync_from_settings() -> void:
	if not _settings:
		return
	if orbit_slider:
		orbit_slider.value = _settings.orbit_sensitivity
	if zoom_slider:
		zoom_slider.value = _settings.zoom_speed
	if min_distance_slider:
		min_distance_slider.value = _settings.min_distance
	if max_distance_slider:
		max_distance_slider.value = _settings.max_distance
	if hints_toggle:
		hints_toggle.button_pressed = _settings.show_input_hints

func _update_setting(key: String, value) -> void:
	if _settings:
		_settings.update_setting(key, value)

func toggle() -> void:
	visible = not visible
