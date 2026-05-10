extends CanvasLayer

@export var fade_duration := 0.08
@export var fade_color := Color(0.03, 0.02, 0.04, 1.0)
@export var click_volume_db := 8.0
@export var card_play_volume_db := 6.0

@onready var _fade_overlay: ColorRect = $FadeOverlay
@onready var _button_click_player: AudioStreamPlayer = $ButtonClickPlayer
@onready var _card_play_player: AudioStreamPlayer = $CardPlayPlayer

func _ready() -> void:
	_fade_overlay.color = fade_color
	_fade_overlay.modulate = Color(1, 1, 1, 1)
	_button_click_player.volume_db = click_volume_db
	_card_play_player.volume_db = card_play_volume_db

func play_button_click() -> void:
	if _button_click_player.stream == null:
		return
	_button_click_player.stop()
	_button_click_player.play()

func play_card_play_sound() -> void:
	if _card_play_player.stream == null:
		return
	_card_play_player.stop()
	_card_play_player.play()

func fade_out() -> void:
	await _tween_overlay_alpha(1.0)

func fade_in() -> void:
	await _tween_overlay_alpha(0.0)

func _tween_overlay_alpha(target_alpha: float) -> void:
	if is_equal_approx(_fade_overlay.modulate.a, target_alpha):
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_overlay, "modulate:a", target_alpha, fade_duration)
	await tween.finished
