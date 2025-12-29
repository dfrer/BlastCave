extends Node

signal state_changed(new_state: int, previous_state: int)

enum State {
	MENU,
	RUNNING,
	SUMMARY,
}

var current_state: int = State.MENU

func set_state(new_state: int) -> void:
	if new_state == current_state:
		return
	var previous_state = current_state
	current_state = new_state
	state_changed.emit(current_state, previous_state)

func is_running() -> bool:
	return current_state == State.RUNNING
