extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _return_to_alchemy_shop_button: Button = $Content/ReturnToAlchemyShop/Button
@onready var _go_to_raw_material_shop_button: Button = $Content/GoToRawMaterialShop/Button
@onready var _go_to_realm_guild_button: Button = $Content/GoToRealmGuild/Button
@onready var _return_to_alchemy_shop_card: Control = $Content/ReturnToAlchemyShop
@onready var _go_to_raw_material_shop_card: Control = $Content/GoToRawMaterialShop
@onready var _go_to_realm_guild_card: Control = $Content/GoToRealmGuild
@onready var _scene_manager: Node = get_node("/root/SceneManager")

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_return_to_alchemy_shop_button, _return_to_alchemy_shop_card)
	UI_BUTTON_FEEDBACK.wire_button(_go_to_raw_material_shop_button, _go_to_raw_material_shop_card)
	UI_BUTTON_FEEDBACK.wire_button(_go_to_realm_guild_button, _go_to_realm_guild_card)
	_return_to_alchemy_shop_button.pressed.connect(_on_return_to_alchemy_shop_pressed)
	_go_to_raw_material_shop_button.pressed.connect(_on_go_to_raw_material_shop_pressed)
	_go_to_realm_guild_button.pressed.connect(_on_go_to_realm_guild_pressed)

func _on_return_to_alchemy_shop_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.ALCHEMY_SHOP)

func _on_go_to_raw_material_shop_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.RAW_MATERIAL_SHOP)

func _on_go_to_realm_guild_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.REALM_GUILD)
