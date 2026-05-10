extends SceneTree

const SCENE_PATHS := [
	"res://scenes/root/game_root.tscn",
	"res://scenes/shop/alchemy_shop_scene.tscn",
	"res://scenes/shop/shop_shelf_popup.tscn",
	"res://scenes/raw_material_shop/raw_material_shop_scene.tscn",
	"res://scenes/raw_material_shop/raw_material_trade_window.tscn",
	"res://scenes/town/town_scene.tscn",
	"res://scenes/lab/laboratory_scene.tscn",
	"res://scenes/lab/alchemy_table_popup.tscn",
	"res://scenes/lab/alchemy_template_button.tscn",
	"res://scenes/lab/alchemy_material_button.tscn",
	"res://scenes/lab/generated_card_result_popup.tscn",
	"res://scenes/ui/generated_card_detail_popup.tscn",
	"res://scenes/realm_guild/realm_guild_scene.tscn",
	"res://scenes/exploration/realm_map_scene.tscn",
	"res://scenes/exploration/rest_site_scene.tscn",
	"res://scenes/battle/battle_scene.tscn",
	"res://scenes/battle/battle_floating_text.tscn",
	"res://scenes/ui/top_status_bar.tscn",
	"res://scenes/ui/material_bag_panel.tscn",
	"res://scenes/ui/card_backpack_panel.tscn",
	"res://scenes/ui/generated_card_bag_popup.tscn",
	"res://scenes/ui/backpack_popup.tscn",
	"res://scenes/ui/expedition_summary_popup.tscn",
	"res://scenes/ui/generated_card_view.tscn",
	"res://scenes/ui/magic_circle_art_preview.tscn",
	"res://scenes/realm_guild/realm_selection_window.tscn",
]

const RESOURCE_PATHS := [
	"res://data/materials/fire_crystal.tres",
	"res://data/materials/water_dew.tres",
	"res://data/materials/earth_stone.tres",
	"res://data/materials/wind_feather.tres",
	"res://data/materials/fire_earth_ore.tres",
	"res://data/materials/water_wind_mist.tres",
	"res://data/materials/unstable_mixture.tres",
	"res://data/materials/ashvine_fiber.tres",
	"res://data/materials/cinder_petal.tres",
	"res://data/materials/moonwell_pearl.tres",
	"res://data/materials/emberglass_shard.tres",
	"res://data/materials/moss_amber.tres",
	"res://data/materials/stormglass_prism.tres",
	"res://data/materials/gravebloom_pollen.tres",
	"res://data/cards/placeholder_spark.tres",
	"res://data/cards/starter_strike.tres",
	"res://data/circles/line_circle.tres",
	"res://data/circles/triangle_circle.tres",
	"res://data/circles/square_circle.tres",
	"res://data/circles/ring_circle.tres",
	"res://data/circles/star_circle.tres",
	"res://data/circles/fork_circle.tres",
	"res://data/circles/hexagon_circle.tres",
	"res://data/circles/wheel_circle.tres",
	"res://data/enemies/cinder_sprite.tres",
	"res://data/enemies/blue_wisp.tres",
	"res://data/enemies/hollow_bloom.tres",
	"res://data/enemies/slime.tres",
	"res://data/realms/training_realm_stage.tres",
]

func _initialize() -> void:
	var failures: Array[String] = []

	for scene_path in SCENE_PATHS:
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			failures.append("Failed to load scene: %s" % scene_path)
			continue

		var instance := packed_scene.instantiate()
		if instance == null:
			failures.append("Failed to instantiate scene: %s" % scene_path)
		else:
			instance.free()

	for resource_path in RESOURCE_PATHS:
		var resource := load(resource_path)
		if resource == null:
			failures.append("Failed to load resource: %s" % resource_path)

	if failures.is_empty():
		print("Project validation passed: scenes and placeholder resources loaded successfully.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
