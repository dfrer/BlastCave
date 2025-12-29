extends CanvasLayer
class_name RunSummary

@onready var time_label: Label = $Panel/MarginContainer/VBox/TimeLabel
@onready var depth_label: Label = $Panel/MarginContainer/VBox/DepthLabel
@onready var upgrades_container: VBoxContainer = $Panel/MarginContainer/VBox/UpgradesContainer

func set_summary(state: RoguelikeState) -> void:
	if not state:
		return
	time_label.text = "Time: %s" % _format_time(state.get_elapsed_time_seconds())
	depth_label.text = "Depth: %d" % state.current_depth
	_update_upgrades(state.upgrades)

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
