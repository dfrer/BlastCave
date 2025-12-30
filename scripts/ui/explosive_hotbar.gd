extends HBoxContainer
class_name ExplosiveHotbar

## Horizontal hotbar showing all explosive types with counts and selection state
# Signal for external use (e.g., if you want to connect UI buttons)
# signal type_selected(type_name: String, index: int)

var explosive_types: Array = ["ImpulseCharge", "ShapedCharge", "DelayedCharge"]
var slots: Array[Control] = []
var _current_index: int = 0
var _inventory: PlayerInventory

# Colors for each explosive type
var type_colors: Dictionary = {
	"ImpulseCharge": Color(0.2, 0.9, 0.5),
	"ShapedCharge": Color(0.95, 0.8, 0.2),
	"DelayedCharge": Color(0.8, 0.3, 0.9)
}

# Style colors
var selected_border_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var normal_border_color: Color = Color(0.4, 0.4, 0.4, 0.8)
var empty_overlay_color: Color = Color(0.3, 0.3, 0.3, 0.7)
var low_ammo_threshold: int = 2

func _ready() -> void:
	_setup_slots()
	call_deferred("_attach_inventory")

func _setup_slots() -> void:
	for i in range(explosive_types.size()):
		var type_name = explosive_types[i]
		var slot = _create_slot(i, type_name)
		add_child(slot)
		slots.append(slot)

func _create_slot(index: int, type_name: String) -> Control:
	var slot = PanelContainer.new()
	slot.name = "Slot_%d" % index
	slot.custom_minimum_size = Vector2(70, 60)
	
	# Create stylebox
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = normal_border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.add_child(vbox)
	
	# Hotkey label (1, 2, 3)
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = "[%d]" % (index + 1)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(key_label)
	
	# Type indicator (colored box)
	var color_rect = ColorRect.new()
	color_rect.name = "TypeColor"
	color_rect.color = type_colors.get(type_name, Color.WHITE)
	color_rect.custom_minimum_size = Vector2(50, 8)
	color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(color_rect)
	
	# Count label
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = "5"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(count_label)
	
	# Short name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = _get_short_name(type_name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(name_label)
	
	# Empty overlay (shown when count is 0)
	var empty_overlay = ColorRect.new()
	empty_overlay.name = "EmptyOverlay"
	empty_overlay.color = empty_overlay_color
	empty_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_overlay.visible = false
	empty_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(empty_overlay)
	
	return slot

func _get_short_name(type_name: String) -> String:
	match type_name:
		"ImpulseCharge": return "IMP"
		"ShapedCharge": return "SHP"
		"DelayedCharge": return "DLY"
		_: return type_name.left(3).to_upper()

func _attach_inventory() -> void:
	_inventory = get_tree().get_root().find_child("PlayerInventory", true, false) as PlayerInventory
	if _inventory:
		_inventory.inventory_changed.connect(_update_counts)
		_update_counts()

func set_selected(index: int) -> void:
	_current_index = clampi(index, 0, slots.size() - 1)
	_update_selection_visuals()

func _update_selection_visuals() -> void:
	for i in range(slots.size()):
		var slot = slots[i] as PanelContainer
		var style = slot.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style = style.duplicate()
			if i == _current_index:
				style.border_color = selected_border_color
				style.border_width_left = 3
				style.border_width_right = 3
				style.border_width_top = 3
				style.border_width_bottom = 3
				slot.modulate = Color(1.2, 1.2, 1.2)
			else:
				style.border_color = normal_border_color
				style.border_width_left = 2
				style.border_width_right = 2
				style.border_width_top = 2
				style.border_width_bottom = 2
				slot.modulate = Color(0.85, 0.85, 0.85)
			slot.add_theme_stylebox_override("panel", style)

func _update_counts() -> void:
	if not _inventory:
		return
	
	for i in range(explosive_types.size()):
		if i >= slots.size():
			break
		var type_name = explosive_types[i]
		var count = _inventory.get_count(type_name)
		var slot = slots[i]
		
		# Update count label
		var count_label = slot.find_child("CountLabel", true, false) as Label
		if count_label:
			count_label.text = str(count)
			# Color based on count
			if count == 0:
				count_label.modulate = Color(0.6, 0.3, 0.3)
			elif count <= low_ammo_threshold:
				count_label.modulate = Color(1.0, 0.7, 0.2)
				# Pulse effect for low ammo
				_apply_low_ammo_pulse(count_label)
			else:
				count_label.modulate = Color(1.0, 1.0, 1.0)
		
		# Show/hide empty overlay
		var empty_overlay = slot.find_child("EmptyOverlay", true, false) as ColorRect
		if empty_overlay:
			empty_overlay.visible = count == 0

func _apply_low_ammo_pulse(label: Label) -> void:
	var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	label.modulate.a = pulse

func _process(_delta: float) -> void:
	# Continuous pulse update for low ammo slots
	if not _inventory:
		return
	
	for i in range(explosive_types.size()):
		if i >= slots.size():
			break
		var type_name = explosive_types[i]
		var count = _inventory.get_count(type_name)
		if count > 0 and count <= low_ammo_threshold:
			var count_label = slots[i].find_child("CountLabel", true, false) as Label
			if count_label:
				_apply_low_ammo_pulse(count_label)
