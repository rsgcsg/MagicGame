extends Node

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")

signal scene_changed(scene_id: String)

var _scene_container: Node
var _current_scene: Node
var _current_scene_id := ""
var _ui_feedback_layer: CanvasLayer
var _scene_change_in_flight := false

func register_scene_container(container: Node) -> void:
	_scene_container = container

func register_ui_feedback_layer(layer: CanvasLayer) -> void:
	_ui_feedback_layer = layer

func play_ui_button_click() -> void:
	if _ui_feedback_layer != null and _ui_feedback_layer.has_method("play_button_click"):
		_ui_feedback_layer.call("play_button_click")

func play_ui_card_play_sound() -> void:
	if _ui_feedback_layer != null and _ui_feedback_layer.has_method("play_card_play_sound"):
		_ui_feedback_layer.call("play_card_play_sound")

func change_scene(scene_id: String) -> void:
	if _scene_container == null:
		push_warning("SceneManager has no scene container yet.")
		return
	if _scene_change_in_flight:
		return

	var scene_path: String = SCENE_PATHS.PATHS.get(scene_id, "")
	if scene_path.is_empty():
		push_warning("Unknown scene id: %s" % scene_id)
		return

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("Could not load scene: %s" % scene_path)
		return

	_scene_change_in_flight = true
	_current_scene_id = scene_id
	if _current_scene != null and _ui_feedback_layer != null and _ui_feedback_layer.has_method("fade_out"):
		await _ui_feedback_layer.fade_out()

	if _current_scene != null:
		_current_scene.queue_free()

	_current_scene = packed_scene.instantiate()
	_scene_container.add_child(_current_scene)
	if _ui_feedback_layer != null and _ui_feedback_layer.has_method("fade_in"):
		await _ui_feedback_layer.fade_in()
	_scene_change_in_flight = false
	scene_changed.emit(scene_id)

func get_current_scene_id() -> String:
	return _current_scene_id
