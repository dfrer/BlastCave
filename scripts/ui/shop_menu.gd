extends CanvasLayer
class_name ShopMenu

signal purchase_requested(upgrade_data: Dictionary)

@onready var buttons: Array = [$Panel/MarginContainer/VBox/OptionA, $Panel/MarginContainer/VBox/OptionB, $Panel/MarginContainer/VBox/OptionC]
@onready var scrap_label: Label = $Panel/MarginContainer/VBox/ScrapLabel
@onready var close_button: Button = $Panel/MarginContainer/VBox/CloseButton

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close)

func set_shop_items(items: Array, scrap_amount: int) -> void:
	if scrap_label:
		scrap_label.text = "Scrap: %d" % scrap_amount
	for i in range(buttons.size()):
		var button = buttons[i]
		if not button:
			continue
		if i >= items.size():
			button.visible = false
			continue
		var upgrade = items[i]
		button.visible = true
		var cost = upgrade.get("cost", 0)
		button.text = "%s (%d)\n%s" % [upgrade.get("name", "Upgrade"), cost, upgrade.get("description", "")]
		button.pressed.connect(func(): _request_purchase(upgrade))

func _request_purchase(upgrade: Dictionary) -> void:
	purchase_requested.emit(upgrade)

func _on_close() -> void:
	queue_free()
