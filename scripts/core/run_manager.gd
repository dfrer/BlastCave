extends Node
class_name RunManager

var current_run_id: String = ""
var is_active: bool = false
var _player_health: HealthComponent
var roguelike_state: RoguelikeState
var _run_summary: RunSummary

@export var run_summary_scene: PackedScene = preload("res://scenes/ui/run_summary.tscn")

func _ready():
	_ensure_roguelike_state()
	start_new_run()
	_connect_player_health()
	get_tree().node_added.connect(_on_node_added)

func start_new_run():
	current_run_id = "run_" + str(Time.get_unix_time_from_system())
	is_active = true
	if roguelike_state:
		roguelike_state.start_run()
	print("Started new run: ", current_run_id)

func end_run():
	is_active = false
	if roguelike_state:
		roguelike_state.end_run()
	print("Run ended.")

func register_upgrade(upgrade_data: Dictionary) -> void:
	if roguelike_state:
		roguelike_state.add_upgrade(upgrade_data)

func complete_extraction() -> void:
	if not is_active:
		return
	end_run()
	_show_run_summary()

func _ensure_roguelike_state() -> void:
	if roguelike_state:
		return
	roguelike_state = RoguelikeState.new()
	roguelike_state.name = "RoguelikeState"
	add_child(roguelike_state)

func _show_run_summary() -> void:
	if _run_summary or run_summary_scene == null:
		return
	_run_summary = run_summary_scene.instantiate() as RunSummary
	var root = get_tree().current_scene
	if root:
		root.add_child(_run_summary)
		_run_summary.set_summary(roguelike_state)

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
	if node is BossController:
		if not node.is_connected("encounter_completed", Callable(self, "_on_boss_completed")):
			node.connect("encounter_completed", Callable(self, "_on_boss_completed"))

func _on_boss_completed() -> void:
	complete_extraction()
