extends Node
class_name RunManager

var current_run_id: String = ""
var is_active: bool = false

func _ready():
	start_new_run()

func start_new_run():
	current_run_id = "run_" + str(Time.get_unix_time_from_system())
	is_active = true
	print("Started new run: ", current_run_id)

func end_run():
	is_active = false
	print("Run ended.")
