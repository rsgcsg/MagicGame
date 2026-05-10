extends Label

func _ready() -> void:
	_refresh()
	if has_node("/root/CardManager"):
		CardManager.cards_changed.connect(_refresh)

func _refresh() -> void:
	text = "Generated Cards %s" % (CardManager.get_card_count() if has_node("/root/CardManager") else 0)
