extends CanvasLayer
class_name HUD

@onready var selected_label: Label = $Panel/VBox/SelectedTypeLabel
@onready var counts_container: VBoxContainer = $Panel/VBox/CountsContainer
@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar

var _health_component: HealthComponent

func _ready() -> void:
	call_deferred("_attach_player_health")

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

func _attach_player_health() -> void:
	var player = get_tree().get_root().find_child("PlayerObject", true, false)
	if not player:
		return
	_health_component = player.get_node_or_null("HealthComponent") as HealthComponent
	if not _health_component:
		return
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.died.connect(_on_player_died)
	_on_health_changed(_health_component.current_health, _health_component.max_health)

func _on_health_changed(current_health: int, max_health: int) -> void:
	if not health_bar:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.tooltip_text = "Health: %d/%d" % [current_health, max_health]

func _on_player_died() -> void:
	_on_health_changed(0, health_bar.max_value)
