extends ExplosiveBase
class_name DelayedCharge

@export var delay_seconds: float = 2.0

func _ready():
	if is_preview: return
	get_tree().create_timer(delay_seconds).timeout.connect(_on_timeout)

func _on_timeout():
	explode()
	queue_free()

func trigger():
	# For delayed charge, manual trigger might be ignored or used to speed up
	pass
