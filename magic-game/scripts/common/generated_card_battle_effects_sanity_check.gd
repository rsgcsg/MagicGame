extends SceneTree

const BATTLE_STATE_SCRIPT := preload("res://scripts/battle/battle_state.gd")
const TEMPLATE_CATALOG := preload("res://scripts/magic_circle/magic_circle_template_catalog.gd")
const MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const EVALUATOR := preload("res://scripts/magic_circle/placeholder_card_evaluator.gd")
const GENERATED_CARD_BUILDER := preload("res://scripts/cards/generated_card_builder.gd")

func _initialize() -> void:
	_run_default_enemy_balance_check()
	_run_generated_card_payload_check()
	_run_damage_and_status_check()
	_run_damage_modifier_formula_check()
	_run_block_and_resource_check()
	_run_defensive_formula_check()
	_run_draw_check()
	_run_enemy_turn_report_check()
	print("Generated card battle effects sanity check passed.")
	quit()

func _run_default_enemy_balance_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	assert(int(state.enemy_state.get("max_hp", 0)) == 50)
	assert(int(state.enemy_state.get("current_hp", 0)) == 50)

func _run_generated_card_payload_check() -> void:
	var template_data: Dictionary = TEMPLATE_CATALOG.get_template("triangle")
	var node_assignments: Dictionary = {}
	# Use a recipe that still reliably produces an executable first-order effect
	# after the balance-profile/material rebalance pass.
	var material_ids: Array[String] = ["fire_crystal", "fire_crystal", "fire_crystal"]
	var nodes: Array = template_data.get("nodes", [])
	for index in range(min(nodes.size(), material_ids.size())):
		var node_id := str(nodes[index])
		var material_id: String = material_ids[index]
		var material_data: Dictionary = MATERIAL_CATALOG.get_material(material_id)
		material_data["material_id"] = material_id
		node_assignments[node_id] = material_data

	var evaluation_result: Dictionary = EVALUATOR.evaluate("triangle", template_data, node_assignments)
	var generated_card: GeneratedCardData = GENERATED_CARD_BUILDER.build_from_alchemy_evaluation(evaluation_result)
	assert(not generated_card.combat_payload.is_empty())
	assert(int((generated_card.combat_payload.get("effects", []) as Array).size()) > 0)

	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.hand = [{
		"instance_id": "generated_card_001",
		"card_id": generated_card.card_id,
		"name": generated_card.display_name,
		"cost": generated_card.action_point_cost,
		"consumable": generated_card.single_use,
		"effect_data": generated_card.combat_payload.duplicate(true),
	}]
	state.draw_pile = []
	var starting_enemy_hp := int(state.enemy_state.get("current_hp", 0))
	var played := state.play_card("generated_card_001", state.get_current_enemy_id())
	assert(played)
	assert(int(state.enemy_state.get("current_hp", starting_enemy_hp)) < starting_enemy_hp or not state.get_enemy_status_rows().is_empty() or not state.get_player_status_rows().is_empty() or state.block > 0 or state.action_points != state.max_action_points - generated_card.action_point_cost or state.mana != state.max_mana)

func _run_damage_and_status_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.hand = [{
		"instance_id": "test_hex_001",
		"card_id": "test_hex",
		"name": "Hex",
		"cost": 1,
		"consumable": true,
		"effect_data": {
			"target": "enemy",
			"effects": [
				{"type": "status", "target": "enemy", "status_id": "vulnerable", "value": 1},
				{"type": "damage", "target": "enemy", "value": 6},
			],
		},
	}]
	state.draw_pile = []
	var played := state.play_card("test_hex_001", state.get_current_enemy_id())
	assert(played)
	assert(int(state.enemy_state.get("current_hp", 0)) == 43)
	assert(state.get_enemy_status_rows().has("Vulnerable 1"))

func _run_damage_modifier_formula_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.enemy_state["current_hp"] = 100
	state.player_statuses["strength"] = 2
	state.player_statuses["strong"] = 1
	state.player_statuses["weak"] = 1
	state.hand = [{
		"instance_id": "test_formula_001",
		"card_id": "test_formula",
		"name": "Formula",
		"cost": 0,
		"consumable": true,
		"effect_data": {
			"target": "enemy",
			"effects": [
				{"type": "status", "target": "enemy", "status_id": "fortitude", "value": 1},
				{"type": "damage", "target": "enemy", "value": 8},
			],
		},
	}]
	state.draw_pile = []
	var played := state.play_card("test_formula_001", state.get_current_enemy_id())
	assert(played)
	assert(int(state.enemy_state.get("current_hp", 0)) == 94)
	assert(state.get_enemy_status_rows().has("Fortitude 1"))

func _run_block_and_resource_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.hand = [{
		"instance_id": "test_guard_001",
		"card_id": "test_guard",
		"name": "Guard",
		"cost": 0,
		"consumable": true,
		"effect_data": {
			"target": "self",
			"effects": [
				{"type": "status", "target": "self", "status_id": "dexterity", "value": 2},
				{"type": "block", "target": "self", "value": 5},
				{"type": "action_points", "target": "self", "value": 1},
				{"type": "mana", "target": "self", "value": 1},
			],
		},
	}]
	state.draw_pile = []
	state.action_points = 0
	state.mana = 4
	var played := state.play_card("test_guard_001")
	assert(played)
	assert(state.block == 7)
	assert(state.action_points == 1)
	assert(state.mana == 5)
	assert(state.get_player_status_rows().has("Dexterity 2"))

func _run_defensive_formula_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	var starting_mana := state.mana
	state.player_statuses["fortitude"] = 1
	state.player_statuses["vulnerable"] = 1
	state.block = 3
	state.resolve_placeholder_enemy_action()
	assert(state.block == 0)
	assert(state.mana == starting_mana - 11)

func _run_draw_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.hand = [{
		"instance_id": "test_focus_001",
		"card_id": "test_focus",
		"name": "Focus",
		"cost": 0,
		"consumable": true,
		"effect_data": {
			"target": "self",
			"effects": [
				{"type": "draw", "target": "self", "value": 2},
			],
		},
	}]
	state.draw_pile = [
		{"instance_id": "draw_one", "card_id": "filler"},
		{"instance_id": "draw_two", "card_id": "filler"},
	]
	state.discard_pile = []
	var played := state.play_card("test_focus_001")
	assert(played)
	assert(state.hand.size() == 2)

func _run_enemy_turn_report_check() -> void:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.setup_placeholder_battle([], {})
	state.block = 2
	var began_enemy_turn := state.end_player_turn()
	assert(began_enemy_turn)
	assert(state.phase == "enemy_turn")
	var report := state.resolve_enemy_turn()
	assert(str(report.get("action_type", "")) == "enemy_turn")
	var events: Array = report.get("events", []) if report.get("events", []) is Array else []
	assert(not events.is_empty())
	var saw_enemy_action := false
	var saw_player_hit := false
	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		var event_type := str(event_variant.get("type", ""))
		if event_type == "enemy_action":
			saw_enemy_action = true
		elif event_type == "player_hit":
			saw_player_hit = true
	assert(saw_enemy_action)
	assert(saw_player_hit)
	if state.battle_result == "pending":
		var advanced := state.begin_next_player_turn()
		assert(advanced)
		assert(state.phase == "player_turn")
