extends Node

# Simplified skill tree with clear path choices

var total_skill_points: int = 0
var spent_skill_points: int = 0
var unlocked_skills: Array = []
var all_skills: Dictionary = {}

# Track which paths player has chosen
var chosen_paths: Dictionary = {
	"attack": "",  # "crit" or "firerate"
	"defense": "",  # "health" or "armor"
	"utility": ""   # "xp" or "speed"
}

class SkillData:
	var skill_id: String
	var skill_name: String
	var description: String
	var branch: String  # "attack", "defense", "utility"
	var path: String  # "crit", "firerate", "health", "armor", "xp", "speed", "shared"
	var tier: int
	var cost: int
	var max_level: int = 1
	var current_level: int = 0
	var requirements: Array = []
	var icon: String = "⭐"
	var effect: Dictionary = {}
	var is_choice_node: bool = false  # Special node that locks you into a path

func _ready():
	setup_skills()
	load_skill_tree()

func setup_skills():
	# === ATTACK BRANCH ===

	# Shared starter
	create_skill("atk_starter", "Power", "+5% Damage", "attack", "shared", 1, 1, 1, "⚔️",
		{"damage_mult": 0.05})

	# CHOICE POINT - Pick Critical OR Fire Rate path
	create_choice_skill("atk_choice_crit", "Critical Path", "Focus on critical strikes", "attack", "crit", 2, 1, 1, "🎯",
		["atk_starter"], {})

	create_choice_skill("atk_choice_fire", "Fire Rate Path", "Focus on attack speed", "attack", "firerate", 2, 1, 1, "⚡",
		["atk_starter"], {})

	# CRITICAL PATH
	create_skill("atk_crit_1", "Sharp Eye", "+5% Crit Chance", "attack", "crit", 3, 2, 1, "👁️",
		{"crit_chance": 0.05}, ["atk_choice_crit"])

	create_skill("atk_crit_2", "Deadly Strike", "+0.5x Crit Damage", "attack", "crit", 4, 3, 1, "💥",
		{"crit_mult": 0.5}, ["atk_crit_1"])

	create_skill("atk_crit_3", "Assassin", "+10% Crit Chance, +0.5x Crit Damage", "attack", "crit", 5, 5, 1, "🗡️",
		{"crit_chance": 0.10, "crit_mult": 0.5}, ["atk_crit_2"])

	# FIRE RATE PATH
	create_skill("atk_fire_1", "Rapid Fire", "+15% Fire Rate", "attack", "firerate", 3, 2, 1, "⚡",
		{"fire_rate": 0.15}, ["atk_choice_fire"])

	create_skill("atk_fire_2", "Machine Gun", "+20% Fire Rate", "attack", "firerate", 4, 3, 1, "⚡⚡",
		{"fire_rate": 0.20}, ["atk_fire_1"])

	create_skill("atk_fire_3", "Berserker", "+25% Fire Rate, +10% Damage", "attack", "firerate", 5, 5, 1, "🔥",
		{"fire_rate": 0.25, "damage_mult": 0.10}, ["atk_fire_2"])

	# === DEFENSE BRANCH ===

	# Shared starter
	create_skill("def_starter", "Vitality", "+25 HP", "defense", "shared", 1, 1, 1, "❤️",
		{"max_health": 25})

	# CHOICE POINT - Pick Health OR Armor path
	create_choice_skill("def_choice_health", "Health Path", "Focus on maximum HP", "defense", "health", 2, 1, 1, "❤️",
		["def_starter"], {})

	create_choice_skill("def_choice_armor", "Armor Path", "Focus on damage reduction", "defense", "armor", 2, 1, 1, "🛡️",
		["def_starter"], {})

	# HEALTH PATH
	create_skill("def_health_1", "Toughness", "+40 HP", "defense", "health", 3, 2, 1, "💪",
		{"max_health": 40}, ["def_choice_health"])

	create_skill("def_health_2", "Iron Body", "+60 HP", "defense", "health", 4, 3, 1, "💪💪",
		{"max_health": 60}, ["def_health_1"])

	create_skill("def_health_3", "Titan", "+100 HP, +2 HP/sec Regen", "defense", "health", 5, 5, 1, "👑",
		{"max_health": 100, "health_regen": 2.0}, ["def_health_2"])

	# ARMOR PATH
	create_skill("def_armor_1", "Plated", "+8% Damage Reduction", "defense", "armor", 3, 2, 1, "🛡️",
		{"damage_reduction": 0.08}, ["def_choice_armor"])

	create_skill("def_armor_2", "Fortified", "+12% Damage Reduction", "defense", "armor", 4, 3, 1, "🛡️🛡️",
		{"damage_reduction": 0.12}, ["def_armor_2"])

	create_skill("def_armor_3", "Immortal", "+20% Damage Reduction, +3 HP/sec Regen", "defense", "armor", 5, 5, 1, "✨",
		{"damage_reduction": 0.20, "health_regen": 3.0}, ["def_armor_2"])

	# === UTILITY BRANCH ===

	# Shared starter
	create_skill("util_starter", "Fleet Footed", "+8% Speed", "utility", "shared", 1, 1, 1, "👟",
		{"move_speed_mult": 0.08})

	# CHOICE POINT - Pick XP/Coins OR Speed/Dash path
	create_choice_skill("util_choice_xp", "Greed Path", "Focus on rewards", "utility", "xp", 2, 1, 1, "💰",
		["util_starter"], {})

	create_choice_skill("util_choice_speed", "Mobility Path", "Focus on movement", "utility", "speed", 2, 1, 1, "🏃",
		["util_starter"], {})

	# XP/COINS PATH
	create_skill("util_xp_1", "Scholar", "+20% XP Gain", "utility", "xp", 3, 2, 1, "📚",
		{"xp_mult": 0.20}, ["util_choice_xp"])

	create_skill("util_xp_2", "Treasure Hunter", "+30% Coin Drops", "utility", "xp", 4, 3, 1, "💎",
		{"coin_mult": 0.30}, ["util_xp_1"])

	create_skill("util_xp_3", "Ascension", "+30% XP, +40% Coins, +50 Pickup Range", "utility", "xp", 5, 5, 1, "🌟",
		{"xp_mult": 0.30, "coin_mult": 0.40, "pickup_radius": 50}, ["util_xp_2"])

	# SPEED/DASH PATH
	create_skill("util_speed_1", "Swift", "+15% Movement Speed", "utility", "speed", 3, 2, 1, "💨",
		{"move_speed_mult": 0.15}, ["util_choice_speed"])

	create_skill("util_speed_2", "Dash Master", "-40% Dash Cooldown", "utility", "speed", 4, 3, 1, "⚡",
		{"dash_cooldown_mult": 0.40}, ["util_speed_1"])

	create_skill("util_speed_3", "Lightning", "+20% Speed, -50% Dash Cooldown", "utility", "speed", 5, 5, 1, "⚡⚡",
		{"move_speed_mult": 0.20, "dash_cooldown_mult": 0.50}, ["util_speed_2"])

func create_skill(id: String, name: String, desc: String, branch: String, path: String,
	tier: int, cost: int, max_lvl: int, icon: String, effects: Dictionary, reqs: Array = []):
	var skill = SkillData.new()
	skill.skill_id = id
	skill.skill_name = name
	skill.description = desc
	skill.branch = branch
	skill.path = path
	skill.tier = tier
	skill.cost = cost
	skill.max_level = max_lvl
	skill.icon = icon
	skill.effect = effects
	skill.requirements = reqs
	all_skills[id] = skill

func create_choice_skill(id: String, name: String, desc: String, branch: String, path: String,
	tier: int, cost: int, max_lvl: int, icon: String, reqs: Array, effects: Dictionary):
	var skill = SkillData.new()
	skill.skill_id = id
	skill.skill_name = name
	skill.description = desc
	skill.branch = branch
	skill.path = path
	skill.tier = tier
	skill.cost = cost
	skill.max_level = max_lvl
	skill.icon = icon
	skill.effect = effects
	skill.requirements = reqs
	skill.is_choice_node = true
	all_skills[id] = skill

func can_unlock_skill(skill_id: String) -> bool:
	if not all_skills.has(skill_id):
		return false

	var skill = all_skills[skill_id]

	# Already maxed?
	if skill.current_level >= skill.max_level:
		return false

	# Enough points?
	var available = total_skill_points - spent_skill_points
	if available < skill.cost:
		return false

	# Check if locked out by path choice
	if skill.path != "shared":
		var chosen = chosen_paths.get(skill.branch, "")
		if chosen != "" and chosen != skill.path:
			return false  # Locked out - chose different path

	# Check requirements
	if skill.current_level == 0 and skill.requirements.size() > 0:
		for req_id in skill.requirements:
			if not all_skills.has(req_id):
				return false
			if all_skills[req_id].current_level == 0:
				return false

	return true

func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false

	var skill = all_skills[skill_id]
	skill.current_level += 1
	spent_skill_points += skill.cost

	if skill.current_level == 1:
		unlocked_skills.append(skill_id)

		# If this is a choice node, lock in the path
		if skill.is_choice_node:
			chosen_paths[skill.branch] = skill.path
			print("Chose %s path for %s branch!" % [skill.path, skill.branch])

	save_skill_tree()
	return true

func get_total_skill_bonuses() -> Dictionary:
	var bonuses = {
		"max_health": 0,
		"damage_mult": 0.0,
		"move_speed_mult": 0.0,
		"fire_rate": 0.0,
		"crit_chance": 0.0,
		"crit_mult": 0.0,
		"damage_reduction": 0.0,
		"health_regen": 0.0,
		"xp_mult": 0.0,
		"pickup_radius": 0,
		"coin_mult": 0.0,
		"dash_cooldown_mult": 0.0
	}

	for skill_id in unlocked_skills:
		if all_skills.has(skill_id):
			var skill = all_skills[skill_id]
			for effect_key in skill.effect.keys():
				if bonuses.has(effect_key):
					bonuses[effect_key] += skill.effect[effect_key] * skill.current_level

	return bonuses

func award_skill_points(amount: int):
	total_skill_points += amount
	save_skill_tree()
	print("Awarded %d skill points! Total: %d" % [amount, total_skill_points])

func add_skill_points(amount: int):
	award_skill_points(amount)

func get_available_points() -> int:
	return total_skill_points - spent_skill_points

func save_skill_tree():
	SaveSystem.set_value("skill_points_total", total_skill_points)
	SaveSystem.set_value("skill_points_spent", spent_skill_points)
	SaveSystem.set_value("chosen_paths", chosen_paths)

	var skill_levels = {}
	for skill_id in all_skills.keys():
		var skill = all_skills[skill_id]
		if skill.current_level > 0:
			skill_levels[skill_id] = skill.current_level

	SaveSystem.set_value("skill_tree_unlocked", skill_levels)
	SaveSystem.save_data()

func load_skill_tree():
	if SaveSystem.has("skill_points_total"):
		total_skill_points = SaveSystem.get_value("skill_points_total")
	if SaveSystem.has("skill_points_spent"):
		spent_skill_points = SaveSystem.get_value("skill_points_spent")
	if SaveSystem.has("chosen_paths"):
		chosen_paths = SaveSystem.get_value("chosen_paths")

	if SaveSystem.has("skill_tree_unlocked"):
		var skill_levels = SaveSystem.get_value("skill_tree_unlocked")
		unlocked_skills.clear()

		for skill_id in skill_levels.keys():
			if all_skills.has(skill_id):
				all_skills[skill_id].current_level = skill_levels[skill_id]
				if not unlocked_skills.has(skill_id):
					unlocked_skills.append(skill_id)

	print("Loaded skill tree - Points: %d/%d" % [get_available_points(), total_skill_points])
