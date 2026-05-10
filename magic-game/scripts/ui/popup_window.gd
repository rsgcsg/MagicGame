extends PanelContainer

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var title := "Popup"
@export_multiline var body_text := "Placeholder popup. Future agents should replace this body with feature-specific UI."

@onready var _title_label: Label = $Margin/Layout/Header/TitleLabel
@onready var _close_button: Button = $Margin/Layout/Header/CloseButton
@onready var _body_label: Label = $Margin/Layout/BodyScroll/BodyLabel

func _ready() -> void:
	_title_label.text = title
	_body_label.text = body_text
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	_close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()
