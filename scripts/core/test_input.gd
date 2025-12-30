extends Node3D

@export var player_spawn_pos: Vector3 = Vector3(0, 2, 0)

var trajectory_node: TrajectoryPreview
var player_obj: RigidBody3D
var inventory: PlayerInventory

var explosive_types = ["ImpulseCharge", "ShapedCharge", "DelayedCharge"]
var current_type_index = 0

var explosive_scenes = {
	"ImpulseCharge": preload("res://scenes/explosives/impulse_charge.tscn"),
	"ShapedCharge": preload("res://scenes/explosives/shaped_charge.tscn"),
	"DelayedCharge": preload("res://scenes/explosives/delayed_charge.tscn")
}

func _ready():
	player_obj = get_node_or_null("PlayerObject")
	if player_obj:
		player_spawn_pos = player_obj.global_position
		
	trajectory_node = TrajectoryPreview.new()
	add_child(trajectory_node)
	
	inventory = PlayerInventory.new()
	inventory.name = "PlayerInventory"
	add_child(inventory)

func _process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_hit = _get_ray_hit(mouse_pos)
	
	if ray_hit != Vector3.ZERO and player_obj:
		_update_trajectory_preview(ray_hit)
		# Pass look target to character
		if player_obj.has_method("set_look_target"):
			player_obj.set_look_target(ray_hit)
	else:
		trajectory_node.hide_preview()
		if player_obj and player_obj.has_method("clear_look_target"):
			player_obj.clear_look_target()
		
	_check_stuck_condition(_delta)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			spawn_blast_at_mouse()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cycle_inventory(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cycle_inventory(-1)
	
	if event is InputEventKey and event.pressed:
		# Use Q and E to cycle inventory to avoid conflict with character selection (1-5)
		if event.keycode == KEY_E: _cycle_inventory(1)
		if event.keycode == KEY_Q: _cycle_inventory(-1)

func _cycle_inventory(dir: int):
	current_type_index = (current_type_index + dir + explosive_types.size()) % explosive_types.size()
	var type = explosive_types[current_type_index]
	print("Selected Explosive: ", type)
	# Update character eye color
	if player_obj and player_obj.has_method("set_explosive_type"):
		player_obj.set_explosive_type(type)

func spawn_blast_at_mouse():
	var type = explosive_types[current_type_index]
	if not inventory.has_explosive(type):
		print("Out of ", type)
		return
		
	var ray_hit = _get_ray_hit(get_viewport().get_mouse_position())
	if ray_hit != Vector3.ZERO:
		inventory.use_explosive(type)
		var scene = explosive_scenes[type]
		var blast = scene.instantiate() as ExplosiveBase
		add_child(blast)
		blast.global_position = ray_hit
		
		if blast is ShapedCharge:
			if ray_hit.distance_to(player_obj.global_position) > 0.001:
				blast.look_at(player_obj.global_position)
			
		blast.trigger()

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
