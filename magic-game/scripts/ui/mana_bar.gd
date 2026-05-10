extends ProgressBar

func _ready() -> void:
	min_value = 0
	max_value = GameManager.max_mana if has_node("/root/GameManager") else 60
	value = GameManager.current_mana if has_node("/root/GameManager") else 28
	show_percentage = false
