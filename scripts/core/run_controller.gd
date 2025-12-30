extends Node3D
class_name RunController

signal stuck_warning_changed(time_remaining: float, is_stuck: bool)

@export var player_spawn_pos: Vector3 = Vector3(0, 2, 0)
@export var hud_path: NodePath
@export var stuck_threshold: float = 3.0
@export var stuck_velocity_min: float = 0.1

var trajectory_node: TrajectoryPreview
var player_obj: RigidBody3D
var inventory: PlayerInventory
var hud: HUD
var debug_overlay: DebugOverlay
var _camera_settings: CameraSettingsState
var _roguelike_state: RoguelikeState

var explosive_types = ["ImpulseCharge", "ShapedCharge", "DelayedCharge"]
var current_type_index = 0
var _stuck_timer: float = 0.0
var _is_stuck: bool = false
@onready var game_flow = get_node("/root/GameFlow")

var explosive_scripts = {
	"ImpulseCharge": preload("res://scripts/explosives/impulse_charge.gd"),
	"ShapedCharge": preload("res://scripts/explosives/shaped_charge.gd"),
	"DelayedCharge": preload("res://scripts/explosives/delayed_charge.gd")
}

func _ready():
	player_obj = get_node_or_null("PlayerObject")
	if player_obj:
		player_spawn_pos = player_obj.global_position

	hud = get_node_or_null(hud_path) as HUD
	debug_overlay = get_node_or_null("DebugOverlay") as DebugOverlay

	trajectory_node = TrajectoryPreview.new()
	add_child(trajectory_node)

	inventory = PlayerInventory.new()
	inventory.name = "PlayerInventory"
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.scrap_changed.connect(_on_scrap_changed)
	add_child(inventory)

	_roguelike_state = get_tree().get_root().find_child("RoguelikeState", true, false) as RoguelikeState
	if _roguelike_state:
		_roguelike_state.scrap_changed.connect(_sync_scrap_to_inventory)

	_camera_settings = get_tree().get_root().find_child("CameraSettingsState", true, false) as CameraSettingsState
	if _camera_settings:
		_camera_settings.settings_changed.connect(_update_input_hints)

	_update_hud()
	_update_input_hints()

func _process(delta):
	if not _is_running():
		trajectory_node.hide_preview()
		_reset_stuck_timer()
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_hit = _get_ray_hit(mouse_pos)

	if ray_hit != Vector3.ZERO and player_obj:
		_update_trajectory_preview(ray_hit)
	else:
		trajectory_node.hide_preview()

	_check_stuck_condition(delta)

func _input(event):
	# Toggle debug with input action
	if Input.is_action_just_pressed("toggle_debug"):
		_toggle_debug_overlay()
		return
	
	# Restart run with R
	if Input.is_action_just_pressed("restart_run") and _is_running():
		_restart_current_run()
		return
	
	if not _is_running():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			spawn_blast_at_mouse()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_inventory(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_inventory(-1)

	# Use input actions for cycling
	if Input.is_action_just_pressed("cycle_explosive_next"):
		_cycle_inventory(1)
	if Input.is_action_just_pressed("cycle_explosive_prev"):
		_cycle_inventory(-1)

func _toggle_debug_overlay() -> void:
	if debug_overlay:
		debug_overlay.visible = not debug_overlay.visible

func _cycle_inventory(dir: int):
	current_type_index = (current_type_index + dir + explosive_types.size()) % explosive_types.size()
	_update_hud()
	print("Selected Explosive: ", explosive_types[current_type_index])

func spawn_blast_at_mouse():
	var type = explosive_types[current_type_index]
	if not inventory.has_explosive(type):
		print("Out of ", type)
		return

	var ray_hit = _get_ray_hit(get_viewport().get_mouse_position())
	if ray_hit != Vector3.ZERO:
		inventory.use_explosive(type)
		var script = explosive_scripts[type]
		var blast = script.new() as ExplosiveBase
		_apply_explosive_upgrades(blast)
		add_child(blast)
		blast.global_position = ray_hit

		if blast is ShapedCharge:
			if ray_hit.distance_to(player_obj.global_position) > 0.001:
				blast.look_at(player_obj.global_position)

		blast.trigger()
		# Player moved, reset stuck timer
		_reset_stuck_timer()

func _get_ray_hit(mouse_pos: Vector2) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 1000.0)
	var result = space_state.intersect_ray(query)

	if result:
		return result.position
	return Vector3.ZERO

func _update_trajectory_preview(blast_pos: Vector3):
	var type = explosive_types[current_type_index]
	var script = explosive_scripts[type]

	var temp_blast = script.new() as ExplosiveBase
	_apply_explosive_upgrades(temp_blast)
	temp_blast.is_preview = true
	add_child(temp_blast)
	temp_blast.global_position = blast_pos

	if temp_blast is ShapedCharge:
		if blast_pos.distance_to(player_obj.global_position) > 0.001:
			temp_blast.look_at(player_obj.global_position)

	var impulse = temp_blast.calculate_impulse(player_obj.global_position)
	remove_child(temp_blast)
	temp_blast.free()

	if impulse.length() > 0.01:
		var initial_velocity = player_obj.linear_velocity + (impulse / player_obj.mass)
		var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * ProjectSettings.get_setting("physics/3d/default_gravity_vector")
		trajectory_node.update_preview(player_obj.global_position, initial_velocity, gravity)
	else:
		trajectory_node.hide_preview()

func _check_stuck_condition(delta: float):
	if not player_obj:
		return
	
	var is_slow = player_obj.linear_velocity.length() < stuck_velocity_min
	var no_explosives = inventory.get_total_count() == 0
	
	if is_slow and no_explosives:
		_stuck_timer += delta
		if _stuck_timer >= stuck_threshold:
			reset_object()
			_reset_stuck_timer()
		else:
			# Emit warning so HUD can show countdown
			_is_stuck = true
			stuck_warning_changed.emit(stuck_threshold - _stuck_timer, true)
	else:
		if _is_stuck:
			_reset_stuck_timer()

func _reset_stuck_timer() -> void:
	if _stuck_timer > 0.0 or _is_stuck:
		_stuck_timer = 0.0
		_is_stuck = false
		stuck_warning_changed.emit(0.0, false)

func reset_object():
	player_obj.linear_velocity = Vector3.ZERO
	player_obj.angular_velocity = Vector3.ZERO
	player_obj.global_position = player_spawn_pos
	# Reset inventory on stuck reset
	inventory.explosives = {
		"ImpulseCharge": 5,
		"ShapedCharge": 5,
		"DelayedCharge": 5
	}
	inventory.inventory_changed.emit()
	_update_hud()
	print("Player reset to spawn - inventory refilled")

func _restart_current_run() -> void:
	get_tree().reload_current_scene()

func _on_inventory_changed():
	_update_hud()
	# If player just used an explosive, they're not stuck
	if inventory.get_total_count() > 0:
		_reset_stuck_timer()

func _on_scrap_changed(_amount: int) -> void:
	_update_hud()

func _update_hud():
	if not hud:
		return
	hud.set_selected_type(explosive_types[current_type_index])
	hud.set_counts(inventory.explosives)
	hud.set_scrap(inventory.scrap)

func _update_input_hints() -> void:
	if not hud:
		return
	var hint_text = ""
	if not _camera_settings or _camera_settings.show_input_hints:
		hint_text = "LMB: Place | Q/E: Cycle | RMB: Orbit | F: Ability | R: Restart"
	hud.set_input_hints(hint_text)

func _apply_explosive_upgrades(blast: ExplosiveBase) -> void:
	if not blast or not _roguelike_state:
		return
	blast.blast_force *= _roguelike_state.explosive_force_mult
	blast.blast_radius *= _roguelike_state.explosive_radius_mult

func _sync_scrap_to_inventory(run_scrap: int, _meta_scrap: int) -> void:
	inventory.scrap = run_scrap
	inventory.scrap_changed.emit(run_scrap)

func get_current_explosive_type() -> String:
	if explosive_types.is_empty():
		return ""
	return explosive_types[current_type_index]

func _is_running() -> bool:
	return game_flow != null and game_flow.is_running()
