extends CanvasLayer
class_name DebugOverlay

@onready var run_id_label: Label = $Panel/VBox/RunIdLabel
@onready var explosive_label: Label = $Panel/VBox/ExplosiveLabel
@onready var room_label: Label = $Panel/VBox/RoomLabel
@onready var scrap_label: Label = $Panel/VBox/ScrapLabel
@onready var state_label: Label = $Panel/VBox/StateLabel
@onready var fps_label: Label = $Panel/VBox/FpsLabel

var _run_manager: RunManager
var _run_controller: RunController
var _roguelike_state: RoguelikeState

func _ready() -> void:
	_attach_sources()

func _process(_delta: float) -> void:
	if not _run_manager or not _roguelike_state or not _run_controller:
		_attach_sources()
	_update_labels()

func _attach_sources() -> void:
	var root = get_tree().get_root()
	if root:
		_run_manager = root.find_child("RunManager", true, false) as RunManager
		_roguelike_state = root.find_child("RoguelikeState", true, false) as RoguelikeState

	var scene = get_tree().current_scene
	if scene:
		if scene is RunController:
			_run_controller = scene
		else:
			_run_controller = scene.find_child("Main", true, false) as RunController

func _update_labels() -> void:
	if run_id_label:
		var run_id = "N/A"
		if _run_manager:
			run_id = _run_manager.current_run_id
		run_id_label.text = "Run ID: %s" % run_id

	if explosive_label:
		var explosive_type = "N/A"
		if _run_controller:
			explosive_type = _run_controller.get_current_explosive_type()
		explosive_label.text = "Explosive: %s" % explosive_type

	if room_label:
		var room_index_text = "?"
		if _roguelike_state:
			room_index_text = str(_roguelike_state.current_depth)
		room_label.text = "Room: %s" % room_index_text

	if scrap_label and _roguelike_state:
		scrap_label.text = "Scrap: %d" % _roguelike_state.run_scrap

	if state_label and _run_manager and _run_manager.game_flow:
		state_label.text = "State: %s" % str(_run_manager.game_flow.current_state)

	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
