class_name GeneratedCardBalanceProfile
extends RefCounted

# Balance-only profile for the current first-order card algorithm.
# The evaluator should keep the same structural algorithm and read its
# thresholds / base values from here.

const EFFECT_MAPPING := {
	"Q01": {"pairs": ["FF", "FF"], "dimension": "Fire,Fire,Fire,Fire", "type": "direct", "threshold": 44.0, "positive": "Deal {value} damage", "negative": "Heal enemy for {value} HP", "base_value": 8, "priority_tier": 1},
	"Q02": {"pairs": ["WW", "WW"], "dimension": "Water,Water,Water,Water", "type": "resource", "threshold": 54.0, "positive": "Gain {value} action points", "negative": "Lose {value} action points", "base_value": 1, "priority_tier": 3},
	"Q03": {"pairs": ["EE", "EE"], "dimension": "Earth,Earth,Earth,Earth", "type": "defense", "threshold": 45.0, "positive": "Gain {value} block", "negative": "Lose {value} block", "base_value": 8, "priority_tier": 2},
	"Q04": {"pairs": ["AA", "AA"], "dimension": "Wind,Wind,Wind,Wind", "type": "draw", "threshold": 56.0, "positive": "Draw {value} cards", "negative": "Discard {value} cards", "base_value": 1, "priority_tier": 3},
	"Q05": {"pairs": ["FF", "FE"], "dimension": "Fire,Fire,Fire,Earth", "type": "self_status", "threshold": 42.0, "positive": "Apply {value} Strength to self", "negative": "Apply {value} Strength Down to self", "base_value": 1, "priority_tier": 2},
	"Q06": {"pairs": ["FF", "FA"], "dimension": "Fire,Fire,Fire,Wind", "type": "enemy_status", "threshold": 34.0, "positive": "Apply {value} Vulnerable to enemy", "negative": "Apply {value} Fortitude to enemy", "base_value": 1, "priority_tier": 2},
	"Q07": {"pairs": ["WW", "WE"], "dimension": "Water,Water,Water,Earth", "type": "resource", "threshold": 16.0, "positive": "Gain {value} mana", "negative": "Lose {value} mana", "base_value": 1, "priority_tier": 3},
	"Q08": {"pairs": ["WW", "WA"], "dimension": "Water,Water,Water,Wind", "type": "modifier_multiply", "threshold": 80.0, "positive": "Increase value multiplier", "negative": "Decrease value multiplier", "priority_tier": 4},
	"Q09": {"pairs": ["AA", "WA"], "dimension": "Wind,Wind,Wind,Water", "type": "modifier_add", "threshold": 72.0, "positive": "Increase fixed value", "negative": "Decrease fixed value", "priority_tier": 4},
	"Q10": {"pairs": ["AA", "FA"], "dimension": "Wind,Wind,Wind,Fire", "type": "hidden", "threshold": 50.0, "positive": "Card-generation tendency", "negative": "Polluted card-generation tendency", "latent_id": "generate_card", "priority_tier": 5},
	"Q11": {"pairs": ["EE", "WE"], "dimension": "Earth,Earth,Earth,Water", "type": "self_status", "threshold": 40.0, "positive": "Apply {value} Dexterity to self", "negative": "Apply {value} Dexterity Down to self", "base_value": 1, "priority_tier": 2},
	"Q12": {"pairs": ["EE", "FE"], "dimension": "Earth,Earth,Earth,Fire", "type": "enemy_status", "threshold": 43.0, "positive": "Apply {value} Weak to enemy", "negative": "Apply {value} Strong to enemy", "base_value": 1, "priority_tier": 2},
	"Q13": {"pairs": ["EE", "FF"], "dimension": "Earth,Earth,Fire,Fire", "type": "waste"},
	"Q14": {"pairs": ["EE", "WW"], "dimension": "Earth,Earth,Water,Water", "type": "waste"},
	"Q15": {"pairs": ["AA", "FF"], "dimension": "Wind,Wind,Fire,Fire", "type": "waste"},
	"Q16": {"pairs": ["AA", "WW"], "dimension": "Wind,Wind,Water,Water", "type": "waste"},
	"Q17": {"pairs": ["FE", "FE"], "dimension": "Earth,Fire,Earth,Fire", "type": "waste"},
	"Q18": {"pairs": ["WE", "WE"], "dimension": "Earth,Water,Earth,Water", "type": "waste"},
	"Q19": {"pairs": ["FA", "FA"], "dimension": "Wind,Fire,Wind,Fire", "type": "waste"},
	"Q20": {"pairs": ["WA", "WA"], "dimension": "Wind,Water,Wind,Water", "type": "waste"},
	"Q21": {"pairs": ["WE", "FE"], "dimension": "Earth,Water,Earth,Fire", "type": "waste"},
	"Q22": {"pairs": ["WA", "FA"], "dimension": "Wind,Water,Wind,Fire", "type": "waste"},
	"Q23": {"pairs": ["FE", "FA"], "dimension": "Fire,Earth,Fire,Wind", "type": "waste"},
	"Q24": {"pairs": ["WA", "WE"], "dimension": "Water,Wind,Water,Earth", "type": "waste"},
	"Q25": {"pairs": ["EE", "FA"], "dimension": "Earth,Earth,Fire,Wind", "type": "enemy_status", "threshold": 28.0, "positive": "Apply {value} Strength Down to enemy", "negative": "Apply {value} Strength to enemy", "base_value": 1, "priority_tier": 2},
	"Q26": {"pairs": ["EE", "WA"], "dimension": "Earth,Earth,Water,Wind", "type": "self_status", "threshold": 40.0, "positive": "Apply {value} Fortitude to self", "negative": "Apply {value} Vulnerable to self", "base_value": 1, "priority_tier": 2},
	"Q27": {"pairs": ["AA", "FE"], "dimension": "Wind,Wind,Fire,Earth", "type": "hidden", "threshold": 82.0, "positive": "Multi-enemy effect tendency", "negative": "Uncontrolled spread tendency", "latent_id": "multi_enemy", "priority_tier": 5},
	"Q28": {"pairs": ["AA", "WE"], "dimension": "Wind,Wind,Water,Earth", "type": "waste"},
	"Q29": {"pairs": ["WW", "FA"], "dimension": "Water,Water,Fire,Wind", "type": "waste"},
	"Q30": {"pairs": ["WW", "FE"], "dimension": "Water,Water,Fire,Earth", "type": "hidden", "threshold": 82.0, "positive": "Multi-card effect tendency", "negative": "Multi-card pollution tendency", "latent_id": "multi_card", "priority_tier": 5},
	"Q31": {"pairs": ["FF", "WA"], "dimension": "Fire,Fire,Water,Wind", "type": "enemy_status", "threshold": 20.0, "positive": "Apply {value} Dexterity Down to enemy", "negative": "Apply {value} Dexterity to enemy", "base_value": 1, "priority_tier": 2},
	"Q32": {"pairs": ["FF", "WE"], "dimension": "Fire,Fire,Water,Earth", "type": "self_status", "threshold": 40.0, "positive": "Apply {value} Strong to self", "negative": "Apply {value} Weak to self", "base_value": 1, "priority_tier": 2},
}

const DEFAULT_FIRST_PROPAGATION_RATE := 0.5
const DEFAULT_SECOND_PROPAGATION_RATE := 0.5
const DEFAULT_MAX_VISIBLE_EFFECTS := 3
const DEFAULT_LATENT_ACTIVATION_MIN_ORDER := 2
