extends Node3D
class_name Gate

@export var is_open: bool = false
@export var switch_path: NodePath

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	set_open(is_open, false)
	if switch_path != NodePath():
		var switch_node = get_node_or_null(switch_path)
		if switch_node and switch_node.has_signal("toggled"):
			switch_node.connect("toggled", Callable(self, "_on_switch_toggled"))

func set_open(open: bool, play_anim: bool = true) -> void:
	is_open = open
	if not animation_player:
		return
	var animation_name = "open" if open else "close"
	if not animation_player.has_animation(animation_name):
		return
	if play_anim:
		animation_player.play(animation_name)
		return
	animation_player.play(animation_name)
	animation_player.seek(animation_player.current_animation_length, true)
	animation_player.stop()

func _on_switch_toggled(active: bool) -> void:
	set_open(active, true)
