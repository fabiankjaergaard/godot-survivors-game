extends Node

# Skill tree system for permanent progression

# Skill points currency
var total_skill_points: int = 0
var spent_skill_points: int = 0

# Unlocked skills
var unlocked_skills: Array = []

# Skill definitions
var all_skills: Dictionary = {}

class SkillData:
	var skill_id: String
	var skill_name: String
	var description: String
	var branch: String  # "attack", "defense", "utility"
	var tier: int  # 1, 2, 3 (higher tier = more powerful)
	var cost: int  # Skill points required
	var max_level: int = 1  # How many times can be upgraded
	var current_level: int = 0
	var requirements: Array = []  # Other skill IDs required
	var connections: Array = []  # Connected node IDs (for visual lines)
	var icon: String = "⭐"
	var effect: Dictionary = {}  # The actual bonuses
	var position: Vector2 = Vector2.ZERO  # Position in skill tree grid

func _ready():
	setup_skills()
	load_skill_tree()

func setup_skills():
	# Grid-based skill tree with branching paths
	# Position format: Vector2(x, y) where each cell is 120x120 pixels

	# === STARTING NODE (CENTER) ===
	var start = SkillData.new()
	start.skill_id = "start"
	start.skill_name = "Origin"
	start.description = "Starting point"
	start.branch = "core"
	start.tier = 1
	start.cost = 0
	start.max_level = 1
	start.current_level = 1  # Auto-unlocked
	start.icon = "⭐"
	start.position = Vector2(400, 350)
	start.connections = ["health_1", "damage_1", "speed_1"]
	all_skills["start"] = start

	# === FIRST TIER - Three main paths ===

	# Path 1: HEALTH/DEFENSE (Left)
	var health_1 = SkillData.new()
	health_1.skill_id = "health_1"
	health_1.skill_name = "Vitality"
	health_1.description = "+20 Max HP"
	health_1.branch = "defense"
	health_1.tier = 1
	health_1.cost = 1
	health_1.max_level = 1
	health_1.icon = "❤️"
	health_1.effect = {"max_health": 20}
	health_1.position = Vector2(250, 350)
	health_1.requirements = ["start"]
	health_1.connections = ["start", "armor_1", "regen_1"]
	all_skills["health_1"] = health_1

	var crit_chance_1 = SkillData.new()
	crit_chance_1.skill_id = "crit_chance_1"
	crit_chance_1.skill_name = "Critical Eye I"
	crit_chance_1.description = "+5% Crit Chance"
	crit_chance_1.branch = "attack"
	crit_chance_1.tier = 1
	crit_chance_1.cost = 1
	crit_chance_1.max_level = 2
	crit_chance_1.icon = "🎯"
	crit_chance_1.effect = {"crit_chance": 0.05}
	all_skills["crit_chance_1"] = crit_chance_1

	var fire_rate_1 = SkillData.new()
	fire_rate_1.skill_id = "fire_rate_1"
	fire_rate_1.skill_name = "Rapid Fire I"
	fire_rate_1.description = "+10% Fire Rate"
	fire_rate_1.branch = "attack"
	fire_rate_1.tier = 1
	fire_rate_1.cost = 1
	fire_rate_1.max_level = 2
	fire_rate_1.icon = "⚡"
	fire_rate_1.effect = {"fire_rate": 0.10}
	all_skills["fire_rate_1"] = fire_rate_1

	# Tier 2
	var power_2 = SkillData.new()
	power_2.skill_id = "power_2"
	power_2.skill_name = "Power II"
	power_2.description = "+10% Damage"
	power_2.branch = "attack"
	power_2.tier = 2
	power_2.cost = 2
	power_2.max_level = 2
	power_2.icon = "⚔️⚔️"
	power_2.requirements = ["power_1"]
	power_2.effect = {"damage_mult": 0.10}
	all_skills["power_2"] = power_2

	var crit_damage = SkillData.new()
	crit_damage.skill_id = "crit_damage"
	crit_damage.skill_name = "Deadly Crits"
	crit_damage.description = "+25% Crit Damage"
	crit_damage.branch = "attack"
	crit_damage.tier = 2
	crit_damage.cost = 2
	crit_damage.max_level = 2
	crit_damage.icon = "💥"
	crit_damage.requirements = ["crit_chance_1"]
	crit_damage.effect = {"crit_mult": 0.25}
	all_skills["crit_damage"] = crit_damage

	# Tier 3
	var berserker = SkillData.new()
	berserker.skill_id = "berserker"
	berserker.skill_name = "Berserker"
	berserker.description = "+20% Damage, +15% Fire Rate"
	berserker.branch = "attack"
	berserker.tier = 3
	berserker.cost = 5
	berserker.max_level = 1
	berserker.icon = "🔥"
	berserker.requirements = ["power_2", "fire_rate_1"]
	berserker.effect = {"damage_mult": 0.20, "fire_rate": 0.15}
	all_skills["berserker"] = berserker

	# === DEFENSE BRANCH ===

	# Tier 1
	var vitality_1 = SkillData.new()
	vitality_1.skill_id = "vitality_1"
	vitality_1.skill_name = "Vitality I"
	vitality_1.description = "+20 Max HP"
	vitality_1.branch = "defense"
	vitality_1.tier = 1
	vitality_1.cost = 1
	vitality_1.max_level = 3
	vitality_1.icon = "❤️"
	vitality_1.effect = {"max_health": 20}
	all_skills["vitality_1"] = vitality_1

	var armor_1 = SkillData.new()
	armor_1.skill_id = "armor_1"
	armor_1.skill_name = "Armor I"
	armor_1.description = "+5% Damage Reduction"
	armor_1.branch = "defense"
	armor_1.tier = 1
	armor_1.cost = 1
	armor_1.max_level = 2
	armor_1.icon = "🛡️"
	armor_1.effect = {"damage_reduction": 0.05}
	all_skills["armor_1"] = armor_1

	var regen_1 = SkillData.new()
	regen_1.skill_id = "regen_1"
	regen_1.skill_name = "Regeneration I"
	regen_1.description = "+1 HP per second"
	regen_1.branch = "defense"
	regen_1.tier = 1
	regen_1.cost = 1
	regen_1.max_level = 2
	regen_1.icon = "💚"
	regen_1.effect = {"health_regen": 1.0}
	all_skills["regen_1"] = regen_1

	# Tier 2
	var vitality_2 = SkillData.new()
	vitality_2.skill_id = "vitality_2"
	vitality_2.skill_name = "Vitality II"
	vitality_2.description = "+40 Max HP"
	vitality_2.branch = "defense"
	vitality_2.tier = 2
	vitality_2.cost = 2
	vitality_2.max_level = 2
	vitality_2.icon = "❤️❤️"
	vitality_2.requirements = ["vitality_1"]
	vitality_2.effect = {"max_health": 40}
	all_skills["vitality_2"] = vitality_2

	var fortify = SkillData.new()
	fortify.skill_id = "fortify"
	fortify.skill_name = "Fortify"
	fortify.description = "+10% Damage Reduction"
	fortify.branch = "defense"
	fortify.tier = 2
	fortify.cost = 2
	fortify.max_level = 1
	fortify.icon = "🛡️🛡️"
	fortify.requirements = ["armor_1"]
	fortify.effect = {"damage_reduction": 0.10}
	all_skills["fortify"] = fortify

	# Tier 3
	var immortal = SkillData.new()
	immortal.skill_id = "immortal"
	immortal.skill_name = "Immortal"
	immortal.description = "+100 Max HP, +15% Reduction"
	immortal.branch = "defense"
	immortal.tier = 3
	immortal.cost = 5
	immortal.max_level = 1
	immortal.icon = "👑"
	immortal.requirements = ["vitality_2", "fortify"]
	immortal.effect = {"max_health": 100, "damage_reduction": 0.15}
	all_skills["immortal"] = immortal

	# === UTILITY BRANCH ===

	# Tier 1
	var speed_1 = SkillData.new()
	speed_1.skill_id = "speed_1"
	speed_1.skill_name = "Swift I"
	speed_1.description = "+10% Move Speed"
	speed_1.branch = "utility"
	speed_1.tier = 1
	speed_1.cost = 1
	speed_1.max_level = 3
	speed_1.icon = "👟"
	speed_1.effect = {"move_speed_mult": 0.10}
	all_skills["speed_1"] = speed_1

	var xp_gain_1 = SkillData.new()
	xp_gain_1.skill_id = "xp_gain_1"
	xp_gain_1.skill_name = "Scholar I"
	xp_gain_1.description = "+15% XP Gain"
	xp_gain_1.branch = "utility"
	xp_gain_1.tier = 1
	xp_gain_1.cost = 1
	xp_gain_1.max_level = 2
	xp_gain_1.icon = "📚"
	xp_gain_1.effect = {"xp_mult": 0.15}
	all_skills["xp_gain_1"] = xp_gain_1

	var pickup_range_1 = SkillData.new()
	pickup_range_1.skill_id = "pickup_range_1"
	pickup_range_1.skill_name = "Magnetism I"
	pickup_range_1.description = "+30 Pickup Range"
	pickup_range_1.branch = "utility"
	pickup_range_1.tier = 1
	pickup_range_1.cost = 1
	pickup_range_1.max_level = 2
	pickup_range_1.icon = "🧲"
	pickup_range_1.effect = {"pickup_radius": 30}
	all_skills["pickup_range_1"] = pickup_range_1

	# Tier 2
	var greed = SkillData.new()
	greed.skill_id = "greed"
	greed.skill_name = "Greed"
	greed.description = "+25% Coin Drops"
	greed.branch = "utility"
	greed.tier = 2
	greed.cost = 2
	greed.max_level = 2
	greed.icon = "💰"
	greed.requirements = ["pickup_range_1"]
	greed.effect = {"coin_mult": 0.25}
	all_skills["greed"] = greed

	var dash_mastery = SkillData.new()
	dash_mastery.skill_id = "dash_mastery"
	dash_mastery.skill_name = "Dash Mastery"
	dash_mastery.description = "-30% Dash Cooldown"
	dash_mastery.branch = "utility"
	dash_mastery.tier = 2
	dash_mastery.cost = 2
	dash_mastery.max_level = 1
	dash_mastery.icon = "💨"
	dash_mastery.requirements = ["speed_1"]
	dash_mastery.effect = {"dash_cooldown_mult": -0.30}
	all_skills["dash_mastery"] = dash_mastery

	# Tier 3
	var god_mode = SkillData.new()
	god_mode.skill_id = "god_mode"
	god_mode.skill_name = "Ascension"
	god_mode.description = "+20% XP, +20% Speed, +20% Coins"
	god_mode.branch = "utility"
	god_mode.tier = 3
	god_mode.cost = 5
	god_mode.max_level = 1
	god_mode.icon = "✨"
	god_mode.requirements = ["xp_gain_1", "speed_1", "greed"]
	god_mode.effect = {"xp_mult": 0.20, "move_speed_mult": 0.20, "coin_mult": 0.20}
	all_skills["god_mode"] = god_mode

func can_unlock_skill(skill_id: String) -> bool:
	if not all_skills.has(skill_id):
		return false

	var skill = all_skills[skill_id]

	# Check if already maxed
	if skill.current_level >= skill.max_level:
		return false

	# Check if have enough points
	var available_points = total_skill_points - spent_skill_points
	if available_points < skill.cost:
		return false

	# Check requirements (for first level)
	if skill.current_level == 0:
		for req_id in skill.requirements:
			if not all_skills.has(req_id):
				return false
			var req_skill = all_skills[req_id]
			if req_skill.current_level == 0:
				return false

	return true

func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false

	var skill = all_skills[skill_id]
	skill.current_level += 1
	spent_skill_points += skill.cost

	# Add to unlocked list if first time
	if skill.current_level == 1 and not unlocked_skills.has(skill_id):
		unlocked_skills.append(skill_id)

	save_skill_tree()
	print("Unlocked %s (Level %d/%d)" % [skill.skill_name, skill.current_level, skill.max_level])
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
			# Multiply by current level
			for effect_key in skill.effect.keys():
				if bonuses.has(effect_key):
					bonuses[effect_key] += skill.effect[effect_key] * skill.current_level

	return bonuses

func award_skill_points(amount: int):
	total_skill_points += amount
	save_skill_tree()
	print("Awarded %d skill points! Total: %d" % [amount, total_skill_points])

func add_skill_points(amount: int):
	# Alias for award_skill_points for convenience
	award_skill_points(amount)

func get_available_points() -> int:
	return total_skill_points - spent_skill_points

func save_skill_tree():
	# Save to SaveSystem
	SaveSystem.set_value("skill_points_total", total_skill_points)
	SaveSystem.set_value("skill_points_spent", spent_skill_points)

	# Save skill levels
	var skill_levels = {}
	for skill_id in all_skills.keys():
		var skill = all_skills[skill_id]
		if skill.current_level > 0:
			skill_levels[skill_id] = skill.current_level

	SaveSystem.set_value("skill_levels", skill_levels)
	SaveSystem.set_value("unlocked_skills", unlocked_skills)
	SaveSystem.save_game()

func load_skill_tree():
	# Load from SaveSystem
	if SaveSystem.has("skill_points_total"):
		total_skill_points = SaveSystem.get_value("skill_points_total", 0)

	if SaveSystem.has("skill_points_spent"):
		spent_skill_points = SaveSystem.get_value("skill_points_spent", 0)

	if SaveSystem.has("unlocked_skills"):
		unlocked_skills = SaveSystem.get_value("unlocked_skills", [])

	if SaveSystem.has("skill_levels"):
		var skill_levels = SaveSystem.get_value("skill_levels", {})
		for skill_id in skill_levels.keys():
			if all_skills.has(skill_id):
				all_skills[skill_id].current_level = skill_levels[skill_id]

	print("Skill Tree loaded. Points: %d/%d" % [total_skill_points - spent_skill_points, total_skill_points])
