extends CanvasLayer
class_name HUD

@onready var selected_label: Label = $RightVisor/Panel/VBox/SelectedTypeLabel
@onready var counts_container: VBoxContainer = $RightVisor/Panel/VBox/CountsScroll/CountsContainer
@onready var objective_label: Label = $TopVisor/Panel/VBox/ObjectiveLabel
@onready var depth_label: Label = $TopVisor/Panel/VBox/DepthLabel
@onready var health_bar: ProgressBar = $LeftVisor/Panel/VBox/HealthBar
@onready var ability_label: Label = $LeftVisor/Panel/VBox/AbilityLabel
@onready var ability_cooldown: ProgressBar = $LeftVisor/Panel/VBox/AbilityCooldown
@onready var scrap_label: Label = $RightVisor/Panel/VBox/ScrapLabel
@onready var input_hints: Label = $BottomVisor/VBox/InputHints
@onready var velocity_label: Label = $BottomVisor/VBox/VelocityLabel
@onready var stuck_warning: Label = $BottomVisor/VBox/StuckWarning
@onready var character_label: Label = $LeftVisor/Panel/VBox/CharacterLabel

var _explosive_hotbar: ExplosiveHotbar
var _health_component: HealthComponent
var _roguelike_state: RoguelikeState
var _player: CharacterObject
var _run_controller: RunController

func _ready() -> void:
	call_deferred("_attach_player_health")
	call_deferred("_attach_roguelike_state")
	call_deferred("_attach_player")
	call_deferred("_attach_run_controller")
	call_deferred("_setup_explosive_hotbar")
	if stuck_warning:
		stuck_warning.visible = false

func _process(_delta: float) -> void:
	_update_velocity_display()

func set_selected_type(type_name: String) -> void:
	if selected_label:
		selected_label.text = "ORDNANCE: %s" % type_name.to_upper().replace("CHARGE", "")
	# Update hotbar selection
	if _explosive_hotbar:
		var index = _explosive_hotbar.explosive_types.find(type_name)
		if index >= 0:
			_explosive_hotbar.set_selected(index)

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

func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "OBJ: %s" % text.to_upper()

func set_depth(depth: int) -> void:
	if depth_label:
		depth_label.text = "DEPTH: %d" % depth

func set_ability_label(text: String) -> void:
	if ability_label:
		ability_label.text = text

func set_ability_cooldown(current: float, max_value: float) -> void:
	if ability_cooldown:
		ability_cooldown.max_value = max_value
		ability_cooldown.value = current

func set_scrap(amount: int) -> void:
	if scrap_label:
		scrap_label.text = "Scrap: %d" % amount

func set_input_hints(text: String) -> void:
	if input_hints:
		input_hints.text = text

func set_character_name(character_name: String) -> void:
	if character_label:
		character_label.text = "PILOT: %s" % character_name.to_upper()

func set_stuck_warning(time_remaining: float, is_stuck: bool) -> void:
	if not stuck_warning:
		return
	stuck_warning.visible = is_stuck
	if is_stuck:
		stuck_warning.text = "STUCK! Resetting in %.1f..." % time_remaining
		stuck_warning.modulate = Color(1.0, 0.3, 0.3)

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

func _attach_roguelike_state() -> void:
	var root = get_tree().get_root()
	if not root:
		return
	_roguelike_state = root.find_child("RoguelikeState", true, false) as RoguelikeState
	if not _roguelike_state:
		return
	_roguelike_state.depth_changed.connect(_on_depth_changed)
	_on_depth_changed(_roguelike_state.current_depth)

func _attach_player() -> void:
	var player = get_tree().get_root().find_child("PlayerObject", true, false) as CharacterObject
	if not player:
		return
	_player = player
	if _player.has_signal("ability_cooldown_changed"):
		_player.ability_cooldown_changed.connect(_on_ability_cooldown_changed)
	if _player.has_signal("ability_state_changed"):
		_player.ability_state_changed.connect(_on_ability_state_changed)
	_on_ability_state_changed(_player.ability_label, _player.ability_cooldown_remaining, _player.ability_cooldown)
	
	# Show current character
	set_character_name(_player.current_character_id.capitalize())

	var inventory = get_tree().get_root().find_child("PlayerInventory", true, false) as PlayerInventory
	if inventory:
		inventory.scrap_changed.connect(set_scrap)
		set_scrap(inventory.scrap)

func _attach_run_controller() -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	_run_controller = scene as RunController
	if not _run_controller:
		_run_controller = scene.find_child("Main", true, false) as RunController
	if _run_controller and _run_controller.has_signal("stuck_warning_changed"):
		_run_controller.stuck_warning_changed.connect(_on_stuck_warning_changed)

func _update_velocity_display() -> void:
	if not velocity_label or not _player:
		return
	var speed = _player.linear_velocity.length()
	velocity_label.text = "SPD: %.1f m/s" % speed
	# Color based on speed
	if speed < 0.5:
		velocity_label.modulate = Color(0.6, 0.6, 0.6)
	elif speed < 5.0:
		velocity_label.modulate = Color(1.0, 1.0, 1.0)
	else:
		velocity_label.modulate = Color(0.5, 1.0, 0.5)

func _on_health_changed(current_health: int, max_health: int) -> void:
	if not health_bar:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.tooltip_text = "Health: %d/%d" % [current_health, max_health]
	# Color gradient based on health percentage
	var health_pct = float(current_health) / float(max_health)
	if health_pct > 0.6:
		health_bar.modulate = Color(0.3, 1.0, 0.3)
	elif health_pct > 0.3:
		health_bar.modulate = Color(1.0, 0.8, 0.2)
	else:
		health_bar.modulate = Color(1.0, 0.3, 0.3)

func _on_player_died() -> void:
	_on_health_changed(0, int(health_bar.max_value))

func _on_depth_changed(depth: int) -> void:
	set_depth(depth)

func _on_ability_state_changed(label_text: String, cooldown_remaining: float, cooldown_max: float) -> void:
	set_ability_label(label_text)
	set_ability_cooldown(cooldown_remaining, cooldown_max)

func _on_ability_cooldown_changed(cooldown_remaining: float, cooldown_max: float) -> void:
	set_ability_cooldown(cooldown_remaining, cooldown_max)

func _on_stuck_warning_changed(time_remaining: float, is_stuck: bool) -> void:
	set_stuck_warning(time_remaining, is_stuck)

func _setup_explosive_hotbar() -> void:
	# Create the explosive hotbar and add it to the bottom center
	_explosive_hotbar = ExplosiveHotbar.new()
	_explosive_hotbar.name = "ExplosiveHotbar"
	
	# Position at bottom center
	var hotbar_container = Control.new()
	hotbar_container.name = "HotbarContainer"
	hotbar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hotbar_container.offset_top = -80
	hotbar_container.offset_bottom = 0
	add_child(hotbar_container)
	
	# Add the hotbar centered
	_explosive_hotbar.set_anchors_preset(Control.PRESET_CENTER)
	_explosive_hotbar.position.x = -105  # Offset for 3 slots of ~70px each
	_explosive_hotbar.position.y = -30
	hotbar_container.add_child(_explosive_hotbar)
