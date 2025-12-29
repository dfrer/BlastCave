extends CanvasLayer
class_name PauseMenu

@onready var resume_button: Button = $Panel/MarginContainer/VBox/ResumeButton
@onready var quit_button: Button = $Panel/MarginContainer/VBox/QuitButton

@export var main_menu_scene: String = "res://scenes/ui/main_menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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

func _on_quit_pressed() -> void:
	get_tree().paused = false
	visible = false
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)
