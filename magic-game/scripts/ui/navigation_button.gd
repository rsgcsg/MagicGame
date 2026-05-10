extends Button

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var target_scene_id := ""

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(self)
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if target_scene_id.is_empty():
		push_warning("NavigationButton has no target_scene_id.")
		return
	SceneManager.play_ui_button_click()
	SceneManager.change_scene(target_scene_id)
