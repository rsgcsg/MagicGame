extends PanelContainer

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _close_button: Button = $Margin/PopupPanel/InnerMargin/Layout/Header/CloseButton

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	_close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()
