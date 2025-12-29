extends Node
class_name CameraSettingsState

signal settings_changed

@export var orbit_sensitivity: float = 0.015
@export var zoom_speed: float = 2.0
@export var min_distance: float = 6.0
@export var max_distance: float = 22.0
@export var show_input_hints: bool = true

var _config_path := "user://camera_settings.cfg"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(_config_path) == OK:
		orbit_sensitivity = float(config.get_value("camera", "orbit_sensitivity", orbit_sensitivity))
		zoom_speed = float(config.get_value("camera", "zoom_speed", zoom_speed))
		min_distance = float(config.get_value("camera", "min_distance", min_distance))
		max_distance = float(config.get_value("camera", "max_distance", max_distance))
		show_input_hints = bool(config.get_value("camera", "show_input_hints", show_input_hints))
	settings_changed.emit()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("camera", "orbit_sensitivity", orbit_sensitivity)
	config.set_value("camera", "zoom_speed", zoom_speed)
	config.set_value("camera", "min_distance", min_distance)
	config.set_value("camera", "max_distance", max_distance)
	config.set_value("camera", "show_input_hints", show_input_hints)
	config.save(_config_path)

func update_setting(key: String, value) -> void:
	match key:
		"orbit_sensitivity":
			orbit_sensitivity = float(value)
		"zoom_speed":
			zoom_speed = float(value)
		"min_distance":
			min_distance = float(value)
		"max_distance":
			max_distance = float(value)
		"show_input_hints":
			show_input_hints = bool(value)
	settings_changed.emit()
	save_settings()
