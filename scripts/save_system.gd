extends Node

# Save file path
const SAVE_FILE = "user://game_save.json"

# Currency
var total_coins: int = 0
var coins_this_run: int = 0

# Unlocked content
var unlocked_items: Array = []

# Achievement tracking
var achievement_data: Dictionary = {}

# Generic data storage for other game data
var game_data: Dictionary = {}

# Unlock definitions
var available_unlocks = {
	# Passive upgrades
	"health_boost_1": {
		"name": "Health Boost I",
		"description": "+20 Max HP",
		"category": "passive",
		"cost": 100,
		"icon": "❤",
		"effect": {"max_health": 20}
	},
	"health_boost_2": {
		"name": "Health Boost II",
		"description": "+40 Max HP",
		"category": "passive",
		"cost": 250,
		"icon": "❤❤",
		"effect": {"max_health": 40},
		"requires": ["health_boost_1"]
	},
	"speed_boost_1": {
		"name": "Speed Boost I",
		"description": "+10% Move Speed",
		"category": "passive",
		"cost": 150,
		"icon": "⚡",
		"effect": {"move_speed_mult": 0.1}
	},
	"speed_boost_2": {
		"name": "Speed Boost II",
		"description": "+20% Move Speed",
		"category": "passive",
		"cost": 300,
		"icon": "⚡⚡",
		"effect": {"move_speed_mult": 0.2},
		"requires": ["speed_boost_1"]
	},
	"damage_boost_1": {
		"name": "Damage Boost I",
		"description": "+15% Damage",
		"category": "passive",
		"cost": 200,
		"icon": "⚔",
		"effect": {"damage_mult": 0.15}
	},
	"damage_boost_2": {
		"name": "Damage Boost II",
		"description": "+30% Damage",
		"category": "passive",
		"cost": 400,
		"icon": "⚔⚔",
		"effect": {"damage_mult": 0.3},
		"requires": ["damage_boost_1"]
	},
	"xp_boost": {
		"name": "Lucky Learner",
		"description": "+25% XP Gain",
		"category": "passive",
		"cost": 300,
		"icon": "📚",
		"effect": {"xp_mult": 0.25}
	},
	"pickup_range": {
		"name": "Magnetic Field",
		"description": "+50 Pickup Radius",
		"category": "passive",
		"cost": 250,
		"icon": "🧲",
		"effect": {"pickup_radius": 50}
	},

	# Meta upgrades
	"double_xp": {
		"name": "Double XP",
		"description": "2x XP gain permanently",
		"category": "meta",
		"cost": 1000,
		"icon": "✨",
		"effect": {"xp_mult": 1.0}
	},
	"lucky_drops": {
		"name": "Lucky Drops",
		"description": "2x item drop chance",
		"category": "meta",
		"cost": 800,
		"icon": "🍀",
		"effect": {"drop_rate_mult": 1.0}
	}
}

func _ready():
	load_game()

func add_coins(amount: int):
	total_coins += amount
	coins_this_run += amount

	# Update coin achievements
	AchievementSystem.update_progress("coin_collector", total_coins)
	AchievementSystem.update_progress("rich", total_coins)

	save_game()

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		save_game()
		return true
	return false

func unlock_item(item_id: String) -> bool:
	if item_id in available_unlocks:
		var unlock = available_unlocks[item_id]

		# Check if already unlocked
		if is_unlocked(item_id):
			print("Already unlocked: %s" % item_id)
			return false

		# Check requirements
		if "requires" in unlock:
			for req in unlock.requires:
				if not is_unlocked(req):
					print("Missing requirement: %s" % req)
					return false

		# Check cost
		if not spend_coins(unlock.cost):
			print("Not enough coins!")
			return false

		# Unlock it!
		unlocked_items.append(item_id)
		save_game()
		print("Unlocked: %s" % unlock.name)
		return true

	return false

func is_unlocked(item_id: String) -> bool:
	return item_id in unlocked_items

func get_total_stat_bonuses() -> Dictionary:
	var bonuses = {
		"max_health": 0,
		"move_speed_mult": 0.0,
		"damage_mult": 0.0,
		"xp_mult": 0.0,
		"pickup_radius": 0,
		"drop_rate_mult": 0.0
	}

	for item_id in unlocked_items:
		if item_id in available_unlocks:
			var unlock = available_unlocks[item_id]
			if "effect" in unlock:
				for key in unlock.effect:
					if key in bonuses:
						bonuses[key] += unlock.effect[key]

	return bonuses

func reset_run_coins():
	coins_this_run = 0

# Generic data storage functions
func has(key: String) -> bool:
	return game_data.has(key)

func get_value(key: String, default = null):
	return game_data.get(key, default)

func set_value(key: String, value):
	game_data[key] = value

func save_game():
	var save_data = {
		"total_coins": total_coins,
		"unlocked_items": unlocked_items,
		"achievement_data": achievement_data,
		"game_data": game_data
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved! Coins: %d" % total_coins)
	else:
		print("Failed to save game")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found, starting fresh")
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var save_data = json.data
			total_coins = save_data.get("total_coins", 0)
			unlocked_items = save_data.get("unlocked_items", [])
			achievement_data = save_data.get("achievement_data", {})
			game_data = save_data.get("game_data", {})
			print("Game loaded! Coins: %d, Unlocks: %d, Achievements: %d" % [total_coins, unlocked_items.size(), achievement_data.size()])
		else:
			print("Failed to parse save file")
	else:
		print("Failed to open save file")
