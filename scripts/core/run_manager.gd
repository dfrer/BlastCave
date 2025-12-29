extends Node
class_name RunManager

var current_run_id: String = ""
var is_active: bool = false
var _player_health: HealthComponent

func _ready():
	start_new_run()
	_connect_player_health()
	get_tree().node_added.connect(_on_node_added)

func start_new_run():
	current_run_id = "run_" + str(Time.get_unix_time_from_system())
	is_active = true
	print("Started new run: ", current_run_id)

func end_run():
	is_active = false
	print("Run ended.")

func _connect_player_health() -> void:
	var player = get_tree().get_root().find_child("PlayerObject", true, false)
	if not player:
		return
	var health = player.get_node_or_null("HealthComponent") as HealthComponent
	if not health or health == _player_health:
		return
	_player_health = health
	_player_health.died.connect(_on_player_died)

func _on_player_died() -> void:
	if is_active:
		end_run()

func _on_node_added(node: Node) -> void:
	if node.name == "PlayerObject":
		_connect_player_health()
