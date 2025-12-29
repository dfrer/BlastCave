extends CanvasLayer
class_name HUD

@onready var selected_label: Label = $Panel/VBox/SelectedTypeLabel
@onready var counts_container: VBoxContainer = $Panel/VBox/CountsContainer

func set_selected_type(type_name: String) -> void:
	if selected_label:
		selected_label.text = "Selected: %s" % type_name

func set_counts(counts: Dictionary) -> void:
	if not counts_container:
		return
	for child in counts_container.get_children():
		child.queue_free()

	for key in counts.keys():
		var row = HBoxContainer.new()
		var swatch = ColorRect.new()
		swatch.color = _color_for_type(key)
		swatch.custom_minimum_size = Vector2(12, 12)
		row.add_child(swatch)

		var label = Label.new()
		label.text = "%s: %d" % [key, counts[key]]
		row.add_child(label)

		counts_container.add_child(row)

func _color_for_type(type_name: String) -> Color:
	match type_name:
		"ImpulseCharge":
			return Color(1.0, 0.9, 0.2)
		"ShapedCharge":
			return Color(0.4, 0.9, 1.0)
		"DelayedCharge":
			return Color(1.0, 0.4, 0.6)
		_:
			return Color(0.8, 0.8, 0.8)
