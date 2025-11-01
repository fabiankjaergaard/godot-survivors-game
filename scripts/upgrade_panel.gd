extends CanvasLayer

@onready var button1 = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button1
@onready var button2 = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button2
@onready var button3 = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Button3

var player: Node = null
var current_upgrades: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Stay active when paused
	hide()

	# Connect button signals
	button1.pressed.connect(_on_upgrade_selected.bind(0))
	button2.pressed.connect(_on_upgrade_selected.bind(1))
	button3.pressed.connect(_on_upgrade_selected.bind(2))

func show_upgrades(upgrade_ids: Array):
	current_upgrades = upgrade_ids

	# Get player reference
	var main = get_tree().root.get_node("Main")
	if main and main.has_node("Player"):
		player = main.get_node("Player")

	# Weapon IDs for checking if upgrade is a weapon
	var weapon_ids = ["laser_weapon", "shotgun", "orbiting_bullets", "homing_missiles",
	                  "chain_lightning", "boomerang", "flamethrower", "explosion_ring"]

	# Update button 1
	var upgrade1 = UpgradeSystem.all_upgrades[upgrade_ids[0]]
	button1.get_node("VBox/NameLabel").text = upgrade1.upgrade_name
	# Use dynamic description for weapons
	if player and upgrade_ids[0] in weapon_ids:
		var weapon_level = UpgradeSystem.get_weapon_level(player, upgrade_ids[0])
		button1.get_node("VBox/DescLabel").text = UpgradeSystem.get_weapon_upgrade_description(upgrade_ids[0], weapon_level)
	else:
		button1.get_node("VBox/DescLabel").text = upgrade1.upgrade_description
	button1.get_node("VBox/CategoryLabel").text = get_upgrade_category(upgrade_ids[0])
	button1.get_node("VBox/CategoryLabel").modulate = get_category_color(upgrade_ids[0])

	# Update button 2
	var upgrade2 = UpgradeSystem.all_upgrades[upgrade_ids[1]]
	button2.get_node("VBox/NameLabel").text = upgrade2.upgrade_name
	if player and upgrade_ids[1] in weapon_ids:
		var weapon_level = UpgradeSystem.get_weapon_level(player, upgrade_ids[1])
		button2.get_node("VBox/DescLabel").text = UpgradeSystem.get_weapon_upgrade_description(upgrade_ids[1], weapon_level)
	else:
		button2.get_node("VBox/DescLabel").text = upgrade2.upgrade_description
	button2.get_node("VBox/CategoryLabel").text = get_upgrade_category(upgrade_ids[1])
	button2.get_node("VBox/CategoryLabel").modulate = get_category_color(upgrade_ids[1])

	# Update button 3
	var upgrade3 = UpgradeSystem.all_upgrades[upgrade_ids[2]]
	button3.get_node("VBox/NameLabel").text = upgrade3.upgrade_name
	if player and upgrade_ids[2] in weapon_ids:
		var weapon_level = UpgradeSystem.get_weapon_level(player, upgrade_ids[2])
		button3.get_node("VBox/DescLabel").text = UpgradeSystem.get_weapon_upgrade_description(upgrade_ids[2], weapon_level)
	else:
		button3.get_node("VBox/DescLabel").text = upgrade3.upgrade_description
	button3.get_node("VBox/CategoryLabel").text = get_upgrade_category(upgrade_ids[2])
	button3.get_node("VBox/CategoryLabel").modulate = get_category_color(upgrade_ids[2])

	show()

func get_upgrade_category(upgrade_id: String) -> String:
	# Weapons
	if upgrade_id in ["laser_weapon", "shotgun", "orbiting_bullets", "homing_missiles",
	                   "chain_lightning", "boomerang", "flamethrower", "explosion_ring"]:
		return "⚔ WEAPON"
	# Stats
	elif upgrade_id in ["damage_boost", "fire_rate_boost", "speed_boost", "health_boost"]:
		return "📊 STAT"
	# Defensive
	elif upgrade_id in ["fortify", "regeneration", "shield", "lifesteal", "thorns"]:
		return "🛡 DEFENSE"
	# Utility
	elif upgrade_id in ["multi_shot", "piercing", "range_boost", "magnet", "knockback",
	                     "explosion_kill", "projectile_size", "crit_damage", "area_damage",
	                     "luck", "dash_cdr", "ultimate_cdr"]:
		return "🛠 UTILITY"
	else:
		return "❓ OTHER"

func get_category_color(upgrade_id: String) -> Color:
	# Weapons = Red/Orange
	if upgrade_id in ["laser_weapon", "shotgun", "orbiting_bullets", "homing_missiles",
	                   "chain_lightning", "boomerang", "flamethrower", "explosion_ring"]:
		return Color(1, 0.3, 0.3, 1)
	# Stats = Green
	elif upgrade_id in ["damage_boost", "fire_rate_boost", "speed_boost", "health_boost"]:
		return Color(0.3, 1, 0.3, 1)
	# Defensive = Purple
	elif upgrade_id in ["fortify", "regeneration", "shield", "lifesteal", "thorns"]:
		return Color(0.8, 0.3, 1, 1)
	# Utility = Blue
	elif upgrade_id in ["multi_shot", "piercing", "range_boost", "magnet", "knockback",
	                     "explosion_kill", "projectile_size", "crit_damage", "area_damage",
	                     "luck", "dash_cdr", "ultimate_cdr"]:
		return Color(0.3, 0.8, 1, 1)
	else:
		return Color(0.5, 0.5, 0.5, 1)

func _on_upgrade_selected(button_index: int):
	var upgrade_id = current_upgrades[button_index]

	# Apply upgrade to player
	UpgradeSystem.apply_upgrade(upgrade_id, player)

	# Resume game
	get_tree().paused = false
	hide()
