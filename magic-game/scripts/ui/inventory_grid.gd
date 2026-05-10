extends GridContainer

@export var columns_count := 4

func _ready() -> void:
	columns = columns_count
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
