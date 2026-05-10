extends Control # 注意：UI 场景根节点最好是 Control，如果是 Node2D 引擎也不会立刻报错，但建议改成 Control

# 1. 预加载你们项目统一的场景路径配置
const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")

@onready var start_button: Button = $UI/VBoxContainer/StartButton
@onready var exit_button: Button = $UI/VBoxContainer/ExitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed() -> void:
	# 2. 核心修改：使用全局的 SceneManager 进行平滑替换，保护 game_root 不被销毁
	# 注意：这里的 SCENE_PATHS.ALCHEMY_SHOP 必须是你在 scene_paths.gd 里定义好的常量名
	SceneManager.change_scene(SCENE_PATHS.ALCHEMY_SHOP)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
