extends Label

@export var float_distance := 42.0
@export var float_duration := 0.9

func play_feedback(feedback_text: String, feedback_color: Color) -> void:
	text = feedback_text
	modulate = feedback_color
	reset_size()
	pivot_offset = size * 0.5
	var tween := create_tween()
	var start_position := position
	tween.tween_property(self, "position:y", start_position.y - float_distance, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, float_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), float_duration * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
