extends CanvasLayer
class_name LevelCompleteScreen

signal continue_requested
signal menu_requested

@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var stats_container: VBoxContainer = $Panel/MarginContainer/VBox/StatsContainer
@onready var narrative_label: Label = $Panel/MarginContainer/VBox/NarrativeLabel
@onready var continue_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/ContinueButton
@onready var menu_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/MenuButton

var _roguelike_state: RoguelikeState
var _next_scene: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_level_complete(roguelike_state: RoguelikeState = null, next_scene: String = "") -> void:
	_roguelike_state = roguelike_state
	_next_scene = next_scene
	visible = true
	get_tree().paused = true
	_populate_stats()
	_update_narrative()

func _populate_stats() -> void:
	if not stats_container:
		return
	
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()
	
	if not _roguelike_state:
		_add_stat_line("Level Complete!")
		return
	
	# Current depth
	_add_stat_line("Depth: %d → %d" % [_roguelike_state.current_depth, _roguelike_state.current_depth + 1])
	
	# Time so far
	var time_secs = _roguelike_state.get_elapsed_time_seconds()
	var minutes = int(floorf(time_secs / 60.0))
	var seconds = int(time_secs) % 60
	_add_stat_line("Time: %d:%02d" % [minutes, seconds])
	
	# Scrap collected
	_add_stat_line("Scrap: %d" % _roguelike_state.run_scrap)
	
	# Upgrades acquired
	_add_stat_line("Upgrades: %d" % _roguelike_state.upgrades.size())

func _add_stat_line(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(label)

func _update_narrative() -> void:
	if not narrative_label or not _roguelike_state:
		if narrative_label:
			narrative_label.text = "The cave beckons deeper..."
		return
	
	var next_depth = _roguelike_state.current_depth + 1
	narrative_label.text = _roguelike_state.get_narrative_line(next_depth)

func _on_continue_pressed() -> void:
	get_tree().paused = false
	visible = false
	
	# Advance depth in roguelike state
	if _roguelike_state:
		_roguelike_state.advance_depth()
	
	continue_requested.emit()
	
	# If there's a next scene, load it; otherwise just reload
	if _next_scene != "":
		get_tree().change_scene_to_file(_next_scene)
	else:
		# Reload current scene to progress to next level
		get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
