extends CanvasLayer
class_name PauseMenu

@onready var resume_button: Button = $Panel/MarginContainer/VBox/ResumeButton
@onready var restart_button: Button = $Panel/MarginContainer/VBox/RestartButton
@onready var quit_button: Button = $Panel/MarginContainer/VBox/QuitButton
@onready var camera_settings_button: Button = $Panel/MarginContainer/VBox/CameraSettingsButton

@export var main_menu_scene: String = "res://scenes/ui/main_menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if camera_settings_button:
		camera_settings_button.pressed.connect(_on_camera_settings_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# Use ui_cancel action (ESC by default) instead of hardcoded key
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	if get_tree().paused:
		_resume()
	else:
		_pause()

func _pause() -> void:
	get_tree().paused = true
	visible = true

func _resume() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	_resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	visible = false
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)

func _on_camera_settings_pressed() -> void:
	var settings = get_tree().get_root().find_child("CameraSettings", true, false)
	if settings and settings.has_method("toggle"):
		settings.toggle()
