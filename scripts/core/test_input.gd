extends Node3D

@export var player_spawn_pos: Vector3 = Vector3(0, 2, 0)

var trajectory_node: TrajectoryPreview
var player_obj: RigidBody3D
var inventory: PlayerInventory
var placement_ghost: PlacementGhost

var explosive_types = ["ImpulseCharge", "ShapedCharge", "DelayedCharge"]
var current_type_index = 0

var explosive_scenes = {
	"ImpulseCharge": preload("res://scenes/explosives/impulse_charge.tscn"),
	"ShapedCharge": preload("res://scenes/explosives/shaped_charge.tscn"),
	"DelayedCharge": preload("res://scenes/explosives/delayed_charge.tscn")
}

# Hold-to-aim state for ShapedCharge
var _is_aiming_shaped: bool = false
var _shaped_aim_start_pos: Vector3 = Vector3.ZERO
var _shaped_aim_direction: Vector3 = Vector3.ZERO
var _current_ray_hit: Vector3 = Vector3.ZERO

func _ready():
	player_obj = get_node_or_null("PlayerObject")
	if player_obj:
		player_spawn_pos = player_obj.global_position
		
	trajectory_node = TrajectoryPreview.new()
	add_child(trajectory_node)
	
	inventory = PlayerInventory.new()
	inventory.name = "PlayerInventory"
	add_child(inventory)
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Set up placement ghost
	placement_ghost = PlacementGhost.new()
	placement_ghost.name = "PlacementGhost"
	add_child(placement_ghost)
	if player_obj:
		placement_ghost.set_player(player_obj)
	placement_ghost.set_explosive_type(explosive_types[current_type_index])
	
	# Update HUD with initial state
	_update_hud_inventory()
	_update_hud_selected_type()

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_hit = _get_ray_hit(mouse_pos)
	_current_ray_hit = ray_hit
	
	if ray_hit != Vector3.ZERO and player_obj:
		# Update placement ghost
		placement_ghost.update_position(ray_hit)
		
		# Update trajectory preview (considers aim direction for ShapedCharge)
		_update_trajectory_preview(ray_hit)
		
		# Pass look target to character
		if player_obj.has_method("set_look_target"):
			player_obj.set_look_target(ray_hit)
		
		# Update ShapedCharge aim direction while holding
		if _is_aiming_shaped:
			_update_shaped_aim(ray_hit)
	else:
		trajectory_node.hide_preview()
		placement_ghost.hide_ghost()
		if player_obj and player_obj.has_method("clear_look_target"):
			player_obj.clear_look_target()
		
	_check_stuck_condition(delta)

func _input(event):
	if event is InputEventMouseButton:
		var type = explosive_types[current_type_index]
		
		# Left mouse button - placement/aim
		if event.button_index == MOUSE_BUTTON_LEFT:
			if type == "ShapedCharge":
				_handle_shaped_charge_input(event.pressed)
			elif event.pressed:
				spawn_blast_at_mouse()
		
		# Right mouse button - cancel placement
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_placement()
		
		# Scroll wheel - cycle explosives
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_inventory(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_inventory(-1)
	
	if event is InputEventKey and event.pressed:
		# Number keys 1-3 for quick explosive selection
		if event.keycode == KEY_1: _select_type(0)
		elif event.keycode == KEY_2: _select_type(1)
		elif event.keycode == KEY_3: _select_type(2)
		# Q/E also cycle
		elif event.keycode == KEY_E: _cycle_inventory(1)
		elif event.keycode == KEY_Q: _cycle_inventory(-1)

func _handle_shaped_charge_input(pressed: bool):
	if pressed:
		# Start aiming
		if _current_ray_hit != Vector3.ZERO and placement_ghost.is_placement_valid():
			_is_aiming_shaped = true
			_shaped_aim_start_pos = _current_ray_hit
			_shaped_aim_direction = Vector3.ZERO
	else:
		# Release - fire if we were aiming
		if _is_aiming_shaped:
			_fire_shaped_charge()
			_is_aiming_shaped = false

func _update_shaped_aim(current_hit: Vector3):
	if not _is_aiming_shaped:
		return
	
	# Direction from placement position toward current mouse position (for visual)
	# But ShapedCharge blasts TOWARD the player, so we aim opposite
	# Actually let player aim freely - direction is from explosive to where they drag
	var drag_direction = (current_hit - _shaped_aim_start_pos).normalized()
	if drag_direction.length_squared() > 0.1:
		_shaped_aim_direction = drag_direction
		placement_ghost.set_aim_direction(_shaped_aim_direction)

func _fire_shaped_charge():
	var type = "ShapedCharge"
	if not inventory.has_explosive(type):
		_play_empty_sound()
		return
	
	if not placement_ghost.is_placement_valid():
		return
	
	inventory.use_explosive(type)
	var scene = explosive_scenes[type]
	var blast = scene.instantiate() as ExplosiveBase
	add_child(blast)
	blast.global_position = _shaped_aim_start_pos
	
	# Apply custom aim direction or fallback to player
	if _shaped_aim_direction.length_squared() > 0.01:
		var target = blast.global_position + _shaped_aim_direction * 10.0
		blast.look_at(target, Vector3.UP)
	elif _shaped_aim_start_pos.distance_to(player_obj.global_position) > 0.001:
		blast.look_at(player_obj.global_position)
	
	blast.trigger()
	_update_hud_inventory()

func _cancel_placement():
	_is_aiming_shaped = false
	_shaped_aim_direction = Vector3.ZERO
	placement_ghost.hide_ghost()

func _select_type(index: int):
	if index >= 0 and index < explosive_types.size():
		current_type_index = index
		var type = explosive_types[current_type_index]
		placement_ghost.set_explosive_type(type)
		_update_hud_selected_type()
		# Update character eye color
		if player_obj and player_obj.has_method("set_explosive_type"):
			player_obj.set_explosive_type(type)

func _cycle_inventory(dir: int):
	current_type_index = (current_type_index + dir + explosive_types.size()) % explosive_types.size()
	var type = explosive_types[current_type_index]
	placement_ghost.set_explosive_type(type)
	_update_hud_selected_type()
	# Update character eye color
	if player_obj and player_obj.has_method("set_explosive_type"):
		player_obj.set_explosive_type(type)

func spawn_blast_at_mouse():
	var type = explosive_types[current_type_index]
	if not inventory.has_explosive(type):
		_play_empty_sound()
		return
	
	if not placement_ghost.is_placement_valid():
		return
		
	var ray_hit = _current_ray_hit
	if ray_hit == Vector3.ZERO:
		return
	
	inventory.use_explosive(type)
	var scene = explosive_scenes[type]
	var blast = scene.instantiate() as ExplosiveBase
	add_child(blast)
	blast.global_position = ray_hit
	
	# ShapedCharge handled separately with hold-to-aim
	blast.trigger()
	_update_hud_inventory()

func _play_empty_sound():
	# Play "empty" click feedback via proper audio system
	print("CLICK - Out of ammo!")
	FXHelper.play_error_sound()

func _get_ray_hit(mouse_pos: Vector2) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera: return Vector3.ZERO
	
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
	var scene = explosive_scenes[type]
	
	var temp_blast = scene.instantiate() as ExplosiveBase
	temp_blast.is_preview = true
	add_child(temp_blast)
	temp_blast.global_position = blast_pos
	
	# For ShapedCharge, use current aim direction or fallback to player
	if temp_blast is ShapedCharge:
		if _is_aiming_shaped and _shaped_aim_direction.length_squared() > 0.01:
			var target = blast_pos + _shaped_aim_direction * 10.0
			temp_blast.look_at(target, Vector3.UP)
		elif blast_pos.distance_to(player_obj.global_position) > 0.001:
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

func _on_inventory_changed():
	_update_hud_inventory()

func _update_hud_inventory():
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("set_counts"):
		hud.set_counts(inventory.explosives)

func _update_hud_selected_type():
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("set_selected_type"):
		hud.set_selected_type(explosive_types[current_type_index])

var _stuck_timer: float = 0.0
const STUCK_THRESHOLD: float = 3.0

func _check_stuck_condition(delta: float):
	if not player_obj: return
	
	var is_moving = player_obj.linear_velocity.length() > 0.1
	var has_ammo = inventory.get_total_count() > 0
	
	if not is_moving and not has_ammo:
		_stuck_timer += delta
		var hud = get_tree().get_root().find_child("HUD", true, false)
		if hud:
			hud.set_stuck_warning(STUCK_THRESHOLD - _stuck_timer, true)
			
		if _stuck_timer >= STUCK_THRESHOLD:
			reset_object()
			_stuck_timer = 0.0
	else:
		if _stuck_timer > 0:
			_stuck_timer = 0.0
			var hud = get_tree().get_root().find_child("HUD", true, false)
			if hud:
				hud.set_stuck_warning(0, false)

func reset_object():
	player_obj.linear_velocity = Vector3.ZERO
	player_obj.angular_velocity = Vector3.ZERO
	player_obj.global_position = player_spawn_pos
