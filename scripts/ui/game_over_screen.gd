extends CanvasLayer
class_name GameOverScreen

signal restart_requested
signal menu_requested

@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var stats_container: VBoxContainer = $Panel/MarginContainer/VBox/StatsContainer
@onready var restart_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/RestartButton
@onready var menu_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/MenuButton

var _roguelike_state: RoguelikeState

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_game_over(roguelike_state: RoguelikeState = null) -> void:
	_roguelike_state = roguelike_state
	visible = true
	get_tree().paused = true
	_populate_stats()

func _populate_stats() -> void:
	if not stats_container:
		return
	
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()
	
	if not _roguelike_state:
		_add_stat_line("No stats available")
		return
	
	# Time survived
	var time_secs = _roguelike_state.get_elapsed_time_seconds()
	var minutes = int(floorf(time_secs / 60.0))
	var seconds = int(time_secs) % 60
	_add_stat_line("Time Survived: %d:%02d" % [minutes, seconds])
	
	# Depth reached
	_add_stat_line("Depth Reached: %d" % _roguelike_state.current_depth)
	
	# Scrap collected
	_add_stat_line("Scrap Collected: %d" % _roguelike_state.run_scrap)
	
	# Upgrades acquired
	_add_stat_line("Upgrades: %d" % _roguelike_state.upgrades.size())
	
	# Total runs (meta)
	_add_stat_line("Total Runs: %d" % _roguelike_state.total_runs)

func _add_stat_line(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(label)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	restart_requested.emit()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
