extends Node

const GAME_CONSTANTS := preload("res://scripts/common/game_constants.gd")
const DEBUG_FLAGS := preload("res://scripts/common/debug_flags.gd")

signal profile_changed

var current_mana: int = GAME_CONSTANTS.DEFAULT_CURRENT_MANA
var max_mana: int = GAME_CONSTANTS.DEFAULT_MAX_MANA
var gold: int = GAME_CONSTANTS.DEFAULT_GOLD
var reputation: int = GAME_CONSTANTS.DEFAULT_REPUTATION
var active_expedition: Dictionary = {}
var latest_expedition_summary: Dictionary = {}

func _ready() -> void:
	if DEBUG_FLAGS.PRINT_MANAGER_BOOT:
		print("GameManager ready: profile placeholder initialized.")

func get_status_snapshot() -> Dictionary:
	var generated_card_count := CardManager.get_card_count() if has_node("/root/CardManager") else 0
	var material_total_count := InventoryManager.get_total_material_count() if has_node("/root/InventoryManager") else 0
	return {
		"current_mana": current_mana,
		"max_mana": max_mana,
		"gold": gold,
		"reputation": reputation,
		"card_count": generated_card_count,
		"generated_card_count": generated_card_count,
		"material_total_count": material_total_count,
	}

func set_mana(value: int) -> void:
	current_mana = clampi(value, 0, max_mana)
	profile_changed.emit()

func can_afford_gold(amount: int) -> bool:
	return gold >= maxi(amount, 0)

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	profile_changed.emit()

func spend_gold(amount: int) -> bool:
	var sanitized_amount := maxi(amount, 0)
	if gold < sanitized_amount:
		return false
	gold -= sanitized_amount
	profile_changed.emit()
	return true

func restore_full_mana() -> void:
	set_mana(max_mana)

func set_latest_expedition_summary(summary: Dictionary) -> void:
	latest_expedition_summary = summary.duplicate(true)

func consume_latest_expedition_summary() -> Dictionary:
	var summary := latest_expedition_summary.duplicate(true)
	latest_expedition_summary = {}
	return summary
