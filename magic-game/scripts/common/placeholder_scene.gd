class_name PlaceholderScene
extends Control

const TOP_STATUS_BAR_SCENE := preload("res://scenes/ui/top_status_bar.tscn")

func build_placeholder_scene(title: String, description: String, actions: Array[Dictionary]) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.16, 0.12, 0.10)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var status_bar := TOP_STATUS_BAR_SCENE.instantiate()
	layout.add_child(status_bar)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 34)
	layout.add_child(title_label)

	var description_label := Label.new()
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(description_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	layout.add_child(button_row)

	for action in actions:
		var button := Button.new()
		button.text = action.get("label", "Action")
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(_on_action_pressed.bind(action))
		button_row.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	var footer := Label.new()
	footer.text = "Architecture scaffold only. Gameplay systems are intentionally stubbed."
	footer.modulate = Color(0.80, 0.73, 0.62)
	layout.add_child(footer)

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func _on_action_pressed(action: Dictionary) -> void:
	var scene_id := String(action.get("scene_id", ""))
	if not scene_id.is_empty():
		SceneManager.change_scene(scene_id)
		return

	var popup_path := String(action.get("popup_path", ""))
	if not popup_path.is_empty():
		var packed_scene := load(popup_path) as PackedScene
		if packed_scene != null:
			add_child(packed_scene.instantiate())
