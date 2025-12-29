extends ExplosiveBase
class_name ImpulseCharge

func trigger():
	explode()
	queue_free()

func _ready() -> void:
	explosive_type = "ImpulseCharge"
