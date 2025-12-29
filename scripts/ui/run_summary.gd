extends CanvasLayer
class_name RunSummary

@onready var time_label: Label = $Panel/MarginContainer/VBox/TimeLabel
@onready var depth_label: Label = $Panel/MarginContainer/VBox/DepthLabel
@onready var scrap_label: Label = $Panel/MarginContainer/VBox/ScrapLabel
@onready var upgrades_container: VBoxContainer = $Panel/MarginContainer/VBox/UpgradesContainer
@onready var restart_button: Button = $Panel/MarginContainer/VBox/RestartButton
@onready var meta_button: Button = $Panel/MarginContainer/VBox/MetaButton
@onready var menu_button: Button = $Panel/MarginContainer/VBox/MenuButton

var _state: RoguelikeState

func set_summary(state: RoguelikeState) -> void:
	if not state:
		return
	_state = state
	time_label.text = "Time: %s" % _format_time(state.get_elapsed_time_seconds())
	depth_label.text = "Depth: %d" % state.current_depth
	if scrap_label:
		scrap_label.text = "Scrap: %d" % state.run_scrap
	_update_upgrades(state.upgrades)
	_connect_buttons()

func _connect_buttons() -> void:
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if meta_button and not meta_button.pressed.is_connected(_on_meta_pressed):
		meta_button.pressed.connect(_on_meta_pressed)
	if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)

func _update_upgrades(upgrades: Array) -> void:
	for child in upgrades_container.get_children():
		child.queue_free()

	if upgrades.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No upgrades collected."
		upgrades_container.add_child(empty_label)
		return

	for upgrade in upgrades:
		var label = Label.new()
		var name_text = "Unknown Upgrade"
		var description_text = ""
		if upgrade is Dictionary:
			name_text = upgrade.get("name", upgrade.get("id", name_text))
			description_text = upgrade.get("description", "")
		label.text = name_text if description_text == "" else "%s - %s" % [name_text, description_text]
		upgrades_container.add_child(label)

func _format_time(total_seconds: float) -> String:
	var seconds = int(total_seconds)
	var minutes = int(seconds / 60.0)
	seconds = seconds % 60
	return "%d:%02d" % [minutes, seconds]

func _on_restart_pressed() -> void:
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if run_manager and run_manager.has_method("start_new_run"):
		run_manager.start_new_run()
	queue_free()

func _on_meta_pressed() -> void:
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if run_manager and run_manager.has_method("show_meta_menu"):
		run_manager.show_meta_menu()
	queue_free()

func _on_menu_pressed() -> void:
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if run_manager and run_manager.has_method("return_to_menu"):
		run_manager.return_to_menu()
	queue_free()
