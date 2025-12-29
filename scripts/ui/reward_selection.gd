extends CanvasLayer
class_name RewardSelection

signal reward_selected(upgrade_data: Dictionary)

@onready var buttons: Array = [$Panel/MarginContainer/VBox/OptionA, $Panel/MarginContainer/VBox/OptionB, $Panel/MarginContainer/VBox/OptionC]

func set_rewards(rewards: Array) -> void:
	for i in range(buttons.size()):
		var button = buttons[i]
		if not button:
			continue
		if i >= rewards.size():
			button.visible = false
			continue
		button.visible = true
		var upgrade = rewards[i]
		var name_text = upgrade.get("name", "Upgrade")
		var description = upgrade.get("description", "")
		button.text = "%s\n%s" % [name_text, description]
		button.pressed.connect(func(): _select_reward(upgrade))

func _select_reward(upgrade: Dictionary) -> void:
	reward_selected.emit(upgrade)
	queue_free()
