extends CanvasLayer
class_name MainMenu

@onready var start_button: Button = $Panel/MarginContainer/VBox/StartButton
@onready var settings_button: Button = $Panel/MarginContainer/VBox/SettingsButton
@onready var exit_button: Button = $Panel/MarginContainer/VBox/ExitButton
@onready var stats_label: Label = $Panel/MarginContainer/VBox/StatsLabel
@onready var controls_label: Label = $Panel/MarginContainer/VBox/ControlsLabel

@export var start_scene: String = "res://scenes/main.tscn"

func _ready() -> void:
	get_tree().paused = false
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	
	_load_meta_stats()
	_update_controls_hint()

func _load_meta_stats() -> void:
	if not stats_label:
		return
	
	# Try to load meta progression data
	var file = FileAccess.open("user://meta_progression.json", FileAccess.READ)
	if not file:
		stats_label.text = "Total Runs: 0"
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data is Dictionary:
		var total_runs = data.get("total_runs", 0)
		var meta_scrap = data.get("meta_scrap", 0)
		stats_label.text = "Total Runs: %d | Scrap Earned: %d" % [total_runs, meta_scrap]
	else:
		stats_label.text = "Total Runs: 0"

func _update_controls_hint() -> void:
	if not controls_label:
		return
	controls_label.text = "Controls: WASD Move | Space Jump | LMB Blast | Q/E Cycle | F Ability | ESC Pause"

func _on_start_pressed() -> void:
	if start_scene != "":
		get_tree().change_scene_to_file(start_scene)

func _on_settings_pressed() -> void:
	# Open camera settings if available
	var settings = get_tree().get_root().find_child("CameraSettings", true, false)
	if settings and settings.has_method("toggle"):
		settings.toggle()
	else:
		print("Settings menu not yet implemented in main menu context")

func _on_exit_pressed() -> void:
	get_tree().quit()
