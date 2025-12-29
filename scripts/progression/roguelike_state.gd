extends Node
class_name RoguelikeState

var current_depth: int = 0
var upgrades: Array = []

func advance_depth():
	current_depth += 1
