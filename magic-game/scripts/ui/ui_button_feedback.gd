class_name UIButtonFeedback
extends RefCounted

const META_WIRED := "_ui_button_feedback_wired"
const META_BASE_MODULATE := "_ui_button_feedback_base_modulate"
const META_BASE_SCALE := "_ui_button_feedback_base_scale"
const META_TWEEN := "_ui_button_feedback_tween"
const PRESSED_MODULATE := Color(0.82, 0.78, 0.72, 1.0)
const PRESSED_SCALE := Vector2(0.95, 0.95)
const RELEASE_HOLD_DURATION := 0.10
const RESTORE_DURATION := 0.12

static func wire_button(button: BaseButton, visual_target: Control = null) -> void:
	if button == null:
		return
	if button.has_meta(META_WIRED):
		return
	var target := visual_target if visual_target != null else button
	button.set_meta(META_WIRED, true)
	_store_base_values(target)
	button.button_down.connect(_apply_pressed_feedback.bind(target))
	button.button_up.connect(_restore_feedback.bind(target))
	button.pressed.connect(_restore_feedback.bind(target))
	button.mouse_exited.connect(_restore_feedback.bind(target))
	button.visibility_changed.connect(_restore_feedback.bind(target))

static func sync_base_values(target: Control) -> void:
	if target == null:
		return
	target.set_meta(META_BASE_MODULATE, target.modulate)
	target.set_meta(META_BASE_SCALE, target.scale)

static func _apply_pressed_feedback(target: Control) -> void:
	if target == null:
		return
	_store_base_values(target)
	_stop_feedback_tween(target)
	target.pivot_offset = target.size * 0.5
	target.scale = PRESSED_SCALE
	target.modulate = PRESSED_MODULATE

static func _restore_feedback(target: Control) -> void:
	if target == null:
		return
	_store_base_values(target)
	_stop_feedback_tween(target)
	var tween := target.create_tween()
	target.set_meta(META_TWEEN, tween)
	tween.tween_interval(RELEASE_HOLD_DURATION)
	tween.tween_property(target, "scale", target.get_meta(META_BASE_SCALE, Vector2.ONE), RESTORE_DURATION)
	tween.parallel().tween_property(target, "modulate", target.get_meta(META_BASE_MODULATE, Color.WHITE), RESTORE_DURATION)

static func _store_base_values(target: Control) -> void:
	if target == null:
		return
	if not target.has_meta(META_BASE_MODULATE):
		target.set_meta(META_BASE_MODULATE, target.modulate)
	if not target.has_meta(META_BASE_SCALE):
		target.set_meta(META_BASE_SCALE, target.scale)

static func _stop_feedback_tween(target: Control) -> void:
	if target == null or not target.has_meta(META_TWEEN):
		return
	var tween = target.get_meta(META_TWEEN)
	if tween is Tween:
		(tween as Tween).kill()
	target.remove_meta(META_TWEEN)
