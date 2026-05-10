extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")

@onready var scene_container: Control = %SceneContainer
@onready var _ui_feedback_layer: CanvasLayer = $UiFeedbackLayer

@onready var bgm_player: AudioStreamPlayer = $BackgroundMusicPlayer

func _ready() -> void:
	SceneManager.register_scene_container(scene_container)
	SceneManager.register_ui_feedback_layer(_ui_feedback_layer)
	
	if bgm_player.stream is AudioStreamMP3:
		bgm_player.stream.loop = true
	
	SceneManager.change_scene(SCENE_PATHS.START)
