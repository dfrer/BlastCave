extends CanvasLayer
class_name MainMenu

@onready var start_button: Button = $Panel/MarginContainer/VBox/StartButton
@onready var exit_button: Button = $Panel/MarginContainer/VBox/ExitButton

@export var start_scene: String = "res://scenes/main.tscn"

func _ready() -> void:
	get_tree().paused = false
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	if start_scene != "":
		get_tree().change_scene_to_file(start_scene)

func _on_exit_pressed() -> void:
	get_tree().quit()
