extends Node
class_name RunManager

var current_run_id: String = ""
var is_active: bool = false
var _player_health: HealthComponent
var roguelike_state: RoguelikeState
var _run_summary: RunSummary
var _reward_selection: RewardSelection
var _shop_menu: ShopMenu
var _meta_menu: MetaMenu
var _game_over_screen: GameOverScreen
var _level_complete_screen: LevelCompleteScreen
var _upgrade_db: UpgradeDatabase
@onready var game_flow = get_node("/root/GameFlow")

@export var run_summary_scene: PackedScene = preload("res://scenes/ui/run_summary.tscn")
@export var reward_selection_scene: PackedScene = preload("res://scenes/ui/reward_selection.tscn")
@export var shop_menu_scene: PackedScene = preload("res://scenes/ui/shop_menu.tscn")
@export var meta_menu_scene: PackedScene = preload("res://scenes/ui/meta_menu.tscn")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/game_over_screen.tscn")
@export var level_complete_scene: PackedScene = preload("res://scenes/ui/level_complete_screen.tscn")
@export var main_menu_scene: String = "res://scenes/ui/main_menu.tscn"
@export var default_objective: String = "Reach the exit."

func _ready():
	_ensure_roguelike_state()
	_upgrade_db = UpgradeDatabase.new()
	_upgrade_db.name = "UpgradeDatabase"
	add_child(_upgrade_db)
	start_new_run()
	call_deferred("_update_hud_objective")
	_connect_player_health()
	get_tree().node_added.connect(_on_node_added)

func start_new_run():
	current_run_id = "run_" + str(Time.get_unix_time_from_system())
	is_active = true
	_cleanup_ui_screens()
	if roguelike_state:
		roguelike_state.start_run()
	if game_flow:
		game_flow.set_state(game_flow.State.RUNNING)
	print("Started new run: ", current_run_id)

func _cleanup_ui_screens() -> void:
	if _run_summary:
		_run_summary.queue_free()
		_run_summary = null
	if _reward_selection:
		_reward_selection.queue_free()
		_reward_selection = null
	if _shop_menu:
		_shop_menu.queue_free()
		_shop_menu = null
	if _meta_menu:
		_meta_menu.queue_free()
		_meta_menu = null
	if _game_over_screen:
		_game_over_screen.queue_free()
		_game_over_screen = null
	if _level_complete_screen:
		_level_complete_screen.queue_free()
		_level_complete_screen = null

func end_run():
	is_active = false
	if roguelike_state:
		roguelike_state.end_run()
	print("Run ended.")
	if game_flow:
		game_flow.set_state(game_flow.State.SUMMARY)

func end_run_death() -> void:
	end_run()
	_show_game_over()

func end_run_level_complete() -> void:
	# Don't fully end run - just show level complete for continuation
	if game_flow:
		game_flow.set_state(game_flow.State.META)
	_show_level_complete()

func register_upgrade(upgrade_data: Dictionary) -> void:
	if roguelike_state:
		roguelike_state.add_upgrade(upgrade_data)
	var player = get_tree().get_root().find_child("PlayerObject", true, false) as CharacterObject
	if player and roguelike_state:
		player.apply_ability_cooldown_multiplier(roguelike_state.ability_cooldown_mult)

func complete_extraction() -> void:
	if not is_active:
		return
	end_run_level_complete()

func _ensure_roguelike_state() -> void:
	if roguelike_state:
		return
	roguelike_state = RoguelikeState.new()
	roguelike_state.name = "RoguelikeState"
	add_child(roguelike_state)
	roguelike_state.depth_changed.connect(_on_depth_changed)

func _show_game_over() -> void:
	if _game_over_screen or game_over_scene == null:
		return
	_game_over_screen = game_over_scene.instantiate() as GameOverScreen
	var root = get_tree().current_scene
	if root and _game_over_screen:
		root.add_child(_game_over_screen)
		_game_over_screen.show_game_over(roguelike_state)

func _show_level_complete() -> void:
	if _level_complete_screen or level_complete_scene == null:
		return
	_level_complete_screen = level_complete_scene.instantiate() as LevelCompleteScreen
	var root = get_tree().current_scene
	if root and _level_complete_screen:
		root.add_child(_level_complete_screen)
		_level_complete_screen.show_level_complete(roguelike_state)

func _show_run_summary() -> void:
	if _run_summary or run_summary_scene == null:
		return
	_run_summary = run_summary_scene.instantiate() as RunSummary
	var root = get_tree().current_scene
	if root:
		root.add_child(_run_summary)
		_run_summary.set_summary(roguelike_state)

func _update_hud_objective() -> void:
	var hud = _get_hud()
	if hud and default_objective != "":
		hud.set_objective(default_objective)

func _on_depth_changed(depth: int) -> void:
	var hud = _get_hud()
	if hud and roguelike_state:
		var narrative = roguelike_state.get_narrative_line(depth)
		hud.set_objective("%s %s" % [default_objective, narrative])

func _get_hud() -> HUD:
	var root = get_tree().current_scene
	if not root:
		return null
	return root.find_child("HUD", true, false) as HUD

func _return_to_main_menu() -> void:
	if main_menu_scene == "":
		return
	var tree = get_tree()
	if tree:
		tree.call_deferred("change_scene_to_file", main_menu_scene)

func return_to_menu() -> void:
	if game_flow:
		game_flow.set_state(game_flow.State.MENU)
	_return_to_main_menu()

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
		end_run_death()

func _on_node_added(node: Node) -> void:
	if node.name == "PlayerObject":
		_connect_player_health()
	if node is BossController:
		if not node.is_connected("encounter_completed", Callable(self, "_on_boss_completed")):
			node.connect("encounter_completed", Callable(self, "_on_boss_completed"))

func _on_boss_completed() -> void:
	_show_reward_selection()
	complete_extraction()

func _show_reward_selection() -> void:
	if _reward_selection or reward_selection_scene == null or not _upgrade_db:
		return
	_reward_selection = reward_selection_scene.instantiate() as RewardSelection
	var root = get_tree().current_scene
	if root:
		root.add_child(_reward_selection)
		var exclude_ids = roguelike_state.upgrades.map(func(upgrade): return upgrade.get("id", "")) if roguelike_state else []
		var rewards = _upgrade_db.get_random_upgrades(3, exclude_ids)
		_reward_selection.set_rewards(rewards)
		_reward_selection.reward_selected.connect(_on_reward_selected)

func _on_reward_selected(upgrade_data: Dictionary) -> void:
	register_upgrade(upgrade_data)
	_reward_selection = null

func show_shop_menu() -> void:
	if _shop_menu or shop_menu_scene == null or not _upgrade_db:
		return
	_shop_menu = shop_menu_scene.instantiate() as ShopMenu
	var root = get_tree().current_scene
	if root:
		root.add_child(_shop_menu)
		var items = _upgrade_db.get_random_upgrades(3, [])
		var scrap_amount = roguelike_state.run_scrap if roguelike_state else 0
		_shop_menu.set_shop_items(items, scrap_amount)
		_shop_menu.purchase_requested.connect(_on_shop_purchase)

func _on_shop_purchase(upgrade_data: Dictionary) -> void:
	if not roguelike_state:
		return
	var cost = int(upgrade_data.get("cost", 0))
	if roguelike_state.run_scrap < cost:
		return
	roguelike_state.run_scrap -= cost
	register_upgrade(upgrade_data)
	roguelike_state.scrap_changed.emit(roguelike_state.run_scrap, roguelike_state.meta_scrap)
	if _shop_menu:
		_shop_menu.queue_free()
		_shop_menu = null

func show_meta_menu() -> void:
	if _meta_menu or meta_menu_scene == null:
		return
	_meta_menu = meta_menu_scene.instantiate() as MetaMenu
	var root = get_tree().current_scene
	if root:
		root.add_child(_meta_menu)
		_meta_menu.set_state(roguelike_state)
	if game_flow:
		game_flow.set_state(game_flow.State.META)
