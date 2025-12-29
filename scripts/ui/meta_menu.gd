extends CanvasLayer
class_name MetaMenu

@onready var scrap_label: Label = $Panel/MarginContainer/VBox/ScrapLabel
@onready var runs_label: Label = $Panel/MarginContainer/VBox/RunsLabel
@onready var upgrades_label: Label = $Panel/MarginContainer/VBox/UpgradesLabel
@onready var start_button: Button = $Panel/MarginContainer/VBox/StartButton
@onready var menu_button: Button = $Panel/MarginContainer/VBox/MenuButton

var _state: RoguelikeState

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func set_state(state: RoguelikeState) -> void:
	_state = state
	_update_labels()

func _update_labels() -> void:
	if not _state:
		return
	if scrap_label:
		scrap_label.text = "Meta Scrap: %d" % _state.meta_scrap
	if runs_label:
		runs_label.text = "Total Runs: %d" % _state.total_runs
	if upgrades_label:
		upgrades_label.text = "Permanent Upgrades: %d" % _state.permanent_upgrades.size()

func _on_start_pressed() -> void:
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if run_manager and run_manager.has_method("start_new_run"):
		run_manager.start_new_run()
	queue_free()

func _on_menu_pressed() -> void:
	var run_manager = get_tree().get_root().find_child("RunManager", true, false)
	if run_manager and run_manager.has_method("return_to_menu"):
		run_manager.return_to_menu()
	queue_free()
