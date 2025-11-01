extends Node

# Achievement System - Tracks player achievements and rewards

signal achievement_unlocked(achievement_id: String)

# Achievement data structure
class Achievement:
	var id: String
	var name: String
	var description: String
	var icon: String  # Emoji or icon
	var goal: int  # Target value to unlock
	var reward_coins: int
	var is_unlocked: bool = false
	var progress: int = 0

	func _init(p_id: String, p_name: String, p_desc: String, p_icon: String, p_goal: int, p_reward: int):
		id = p_id
		name = p_name
		description = p_desc
		icon = p_icon
		goal = p_goal
		reward_coins = p_reward

# All achievements
var achievements: Dictionary = {}

# Achievement progress tracking
var achievement_progress: Dictionary = {}

func _ready():
	create_achievements()
	load_achievements()

func create_achievements():
	# Kill achievements
	achievements["first_blood"] = Achievement.new(
		"first_blood",
		"First Blood",
		"Kill your first enemy",
		"🩸",
		1,
		10
	)

	achievements["killer"] = Achievement.new(
		"killer",
		"Killer",
		"Kill 100 enemies",
		"💀",
		100,
		50
	)

	achievements["executioner"] = Achievement.new(
		"executioner",
		"Executioner",
		"Kill 500 enemies",
		"⚔️",
		500,
		150
	)

	achievements["slayer"] = Achievement.new(
		"slayer",
		"Legendary Slayer",
		"Kill 1000 enemies",
		"👑",
		1000,
		300
	)

	# Survival achievements
	achievements["survivor_5"] = Achievement.new(
		"survivor_5",
		"Survivor",
		"Survive for 5 minutes",
		"⏱️",
		300,  # 5 minutes in seconds
		25
	)

	achievements["survivor_10"] = Achievement.new(
		"survivor_10",
		"Veteran",
		"Survive for 10 minutes",
		"🛡️",
		600,
		75
	)

	achievements["survivor_15"] = Achievement.new(
		"survivor_15",
		"Immortal",
		"Survive for 15 minutes",
		"⭐",
		900,
		150
	)

	# Level achievements
	achievements["level_10"] = Achievement.new(
		"level_10",
		"Rising Star",
		"Reach level 10",
		"📈",
		10,
		30
	)

	achievements["level_20"] = Achievement.new(
		"level_20",
		"Powerhouse",
		"Reach level 20",
		"💪",
		20,
		100
	)

	# Boss achievements
	achievements["boss_killer"] = Achievement.new(
		"boss_killer",
		"Boss Slayer",
		"Defeat a boss",
		"👹",
		1,
		50
	)

	achievements["boss_hunter"] = Achievement.new(
		"boss_hunter",
		"Boss Hunter",
		"Defeat 5 bosses",
		"🏆",
		5,
		200
	)

	# Weapon achievements
	achievements["arsenal"] = Achievement.new(
		"arsenal",
		"Arsenal",
		"Unlock 4 different weapons",
		"🔫",
		4,
		75
	)

	achievements["fully_loaded"] = Achievement.new(
		"fully_loaded",
		"Fully Loaded",
		"Unlock all 8 weapons in one run",
		"💥",
		8,
		250
	)

	# Damage achievements
	achievements["damage_10k"] = Achievement.new(
		"damage_10k",
		"Destroyer",
		"Deal 10,000 damage",
		"💣",
		10000,
		40
	)

	achievements["damage_50k"] = Achievement.new(
		"damage_50k",
		"Annihilator",
		"Deal 50,000 damage",
		"🔥",
		50000,
		150
	)

	# Collection achievements
	achievements["coin_collector"] = Achievement.new(
		"coin_collector",
		"Coin Collector",
		"Collect 1000 coins (total)",
		"💰",
		1000,
		100
	)

	achievements["rich"] = Achievement.new(
		"rich",
		"Filthy Rich",
		"Collect 5000 coins (total)",
		"💎",
		5000,
		300
	)

func update_progress(achievement_id: String, value: int):
	if not achievements.has(achievement_id):
		return

	var achievement = achievements[achievement_id]

	# Skip if already unlocked
	if achievement.is_unlocked:
		return

	# Update progress
	achievement.progress = value

	# Check if unlocked
	if achievement.progress >= achievement.goal and not achievement.is_unlocked:
		unlock_achievement(achievement_id)

func unlock_achievement(achievement_id: String):
	if not achievements.has(achievement_id):
		return

	var achievement = achievements[achievement_id]

	# Skip if already unlocked
	if achievement.is_unlocked:
		return

	achievement.is_unlocked = true
	achievement.progress = achievement.goal

	# Award coins
	SaveSystem.add_coins(achievement.reward_coins)

	print("🏆 ACHIEVEMENT UNLOCKED: %s - %s (+%d coins)" % [achievement.name, achievement.description, achievement.reward_coins])

	# Show popup notification
	show_achievement_popup(achievement)

	# Emit signal
	achievement_unlocked.emit(achievement_id)

	# Save progress
	save_achievements()

func show_achievement_popup(achievement):
	# Find the main scene to add popup to
	var main_scene = get_tree().current_scene

	if not main_scene:
		return

	# Check if UILayer exists (for in-game popups)
	var parent_node = main_scene
	if main_scene.has_node("UILayer"):
		parent_node = main_scene.get_node("UILayer")

	# Load and instantiate popup
	var popup_scene = preload("res://scenes/achievement_popup.tscn")
	var popup = popup_scene.instantiate()

	parent_node.add_child(popup)
	popup.show_achievement(achievement)

func get_achievement(achievement_id: String) -> Achievement:
	if achievements.has(achievement_id):
		return achievements[achievement_id]
	return null

func get_all_achievements() -> Array:
	return achievements.values()

func get_unlocked_count() -> int:
	var count = 0
	for achievement in achievements.values():
		if achievement.is_unlocked:
			count += 1
	return count

func get_total_count() -> int:
	return achievements.size()

func save_achievements():
	var save_data = {}
	for achievement in achievements.values():
		save_data[achievement.id] = {
			"is_unlocked": achievement.is_unlocked,
			"progress": achievement.progress
		}

	SaveSystem.achievement_data = save_data
	SaveSystem.save_game()

func load_achievements():
	if SaveSystem.achievement_data.is_empty():
		return

	for achievement_id in SaveSystem.achievement_data.keys():
		if achievements.has(achievement_id):
			var data = SaveSystem.achievement_data[achievement_id]
			achievements[achievement_id].is_unlocked = data.get("is_unlocked", false)
			achievements[achievement_id].progress = data.get("progress", 0)
