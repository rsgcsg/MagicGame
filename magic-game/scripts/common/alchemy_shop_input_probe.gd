extends SceneTree

const ROOT_SCENE := preload("res://scenes/root/game_root.tscn")
const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")

func _initialize() -> void:
	call_deferred("_run_probe")

func _run_probe() -> void:
	var root_scene := ROOT_SCENE.instantiate()
	get_root().add_child(root_scene)
	await process_frame
	await process_frame

	var scene_container := root_scene.get_node("SceneContainer") as Control
	if scene_container == null or scene_container.get_child_count() == 0:
		push_error("Probe failed: no current scene in SceneContainer.")
		quit(1)
		return

	var shop_scene := scene_container.get_child(0)
	if shop_scene == null:
		push_error("Probe failed: shop scene is null.")
		quit(1)
		return

	if not shop_scene.has_method("_on_open_shelf_pressed") or not shop_scene.has_method("_on_navigation_button_pressed"):
		push_error("Probe failed: required AlchemyShop callbacks are missing.")
		quit(1)
		return

	shop_scene.call("_on_open_shelf_pressed")
	var overlay := shop_scene.get_node("OverlayLayer") as Control
	if overlay == null or overlay.get_child_count() == 0:
		push_error("Probe failed: Open Shelf did not add popup.")
		quit(1)
		return

	shop_scene.call("_on_navigation_button_pressed", "To Laboratory", SCENE_PATHS.LABORATORY)
	await process_frame
	if SceneManager.get_current_scene_id() != SCENE_PATHS.LABORATORY:
		push_error("Probe failed: To Laboratory did not change scene.")
		quit(1)
		return

	SceneManager.change_scene(SCENE_PATHS.ALCHEMY_SHOP)
	await process_frame
	var shop_again := scene_container.get_child(0)
	shop_again.call("_on_navigation_button_pressed", "To Town", SCENE_PATHS.TOWN)
	await process_frame
	if SceneManager.get_current_scene_id() != SCENE_PATHS.TOWN:
		push_error("Probe failed: To Town did not change scene.")
		quit(1)
		return

	print("AlchemyShop input probe passed.")
	quit(0)
