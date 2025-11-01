extends Node2D

# UI scenes
var character_screen_scene = preload("res://scenes/character_screen.tscn")

# Enemy spawning
var enemy_scene = preload("res://scenes/enemy.tscn")
var boss_scene = preload("res://scenes/boss.tscn")
var base_spawn_interval: float = 2.0  # Base spawn interval
var spawn_timer: float = 0.0
var base_elite_spawn_chance: float = 0.05  # Base 5% chance for elite enemies

# Boss spawning
var boss_spawn_interval: float = 120.0  # Boss every 2 minutes
var boss_spawn_timer: float = 0.0
var boss_active: bool = false

# Chest item spawning (passive items in chests)
var chest_drop_scene = preload("res://scenes/chest_drop.tscn")
var chest_spawn_interval: float = 45.0  # Spawn chest every 45 seconds
var chest_spawn_timer: float = 0.0
var item_configs = [
	preload("res://resources/item_crown.tres"),
	preload("res://resources/item_wings.tres"),
	preload("res://resources/item_shield.tres"),
	preload("res://resources/item_sword.tres"),
	preload("res://resources/item_magnet.tres")
]

# Difficulty scaling over time
var game_time: float = 0.0  # Total time elapsed
var difficulty_multiplier: float = 1.0

# Enemy type configs
var goblin_config = preload("res://resources/enemy_goblin.tres")
var sprite_config = preload("res://resources/enemy_sprite.tres")
var ogre_config = preload("res://resources/enemy_ogre.tres")
var wraith_config = preload("res://resources/enemy_wraith.tres")
var spore_config = preload("res://resources/enemy_spore.tres")

func _ready():
	# Create CanvasLayer for UI elements to stay on screen
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	# Move all UI elements to the CanvasLayer
	var ui_elements = [
		"XPLabel", "LevelLabel", "XPBarLabel", "XPProgressBar", "HealthLabel", "HealthProgressBar", "TimeLabel",
		"DifficultyLabel", "CoinsLabel", "BossNameLabel", "BossHealthLabel",
		"ActiveWeaponsTitle", "BasicWeaponIcon", "LaserWeaponIcon", "ShotgunWeaponIcon",
		"OrbitingWeaponIcon", "HomingWeaponIcon", "ChainLightningIcon", "BoomerangIcon",
		"FlamethrowerIcon", "ToxicPoolsIcon", "DashLabel", "UltimateLabel",
		"UpgradePanel", "DeathScreen", "PauseMenu", "ChestOpeningUI",
		"DebugLevelUpButton", "DebugDieButton"
	]

	for element_name in ui_elements:
		if has_node(element_name):
			var element = get_node(element_name)
			remove_child(element)
			ui_layer.add_child(element)

	# Main scene is ready
	# Connect upgrade panel to player
	$UILayer/UpgradePanel.player = $Player
	$Player.upgrade_ui = $UILayer/UpgradePanel

	# Connect player damage signal to camera shake
	if has_node("Camera"):
		$Player.connect("took_damage", _on_player_took_damage)

	# Connect debug buttons
	if has_node("UILayer/DebugLevelUpButton"):
		$UILayer/DebugLevelUpButton.pressed.connect(_on_debug_level_up)
	if has_node("UILayer/DebugDieButton"):
		$UILayer/DebugDieButton.pressed.connect(_on_debug_die)

func _on_player_took_damage():
	if has_node("Camera"):
		$Camera.shake(0.2, 5.0)  # 0.2 seconds, 5 pixels

func _physics_process(delta):
	# Handle fullscreen toggle
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()

	# Handle character screen toggle (C key)
	if Input.is_key_pressed(KEY_C) and not get_tree().paused:
		_toggle_character_screen()

	# Update game time
	game_time += delta

	# Update survival achievements
	AchievementSystem.update_progress("survivor_5", int(game_time))
	AchievementSystem.update_progress("survivor_10", int(game_time))
	AchievementSystem.update_progress("survivor_15", int(game_time))

	# Calculate difficulty based on time (increases every 30 seconds)
	# Every 30 seconds: +15% difficulty
	difficulty_multiplier = 1.0 + (floor(game_time / 30.0) * 0.15)

	# Update UI
	update_ui()

	# Enemy spawning - gets faster over time
	spawn_timer += delta
	var current_spawn_interval = base_spawn_interval / sqrt(difficulty_multiplier)

	if spawn_timer >= current_spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0

	# Boss spawning
	boss_spawn_timer += delta
	if boss_spawn_timer >= boss_spawn_interval and not boss_active:
		spawn_boss()
		boss_spawn_timer = 0.0

	# Update chest spawn timer
	chest_spawn_timer += delta
	if chest_spawn_timer >= chest_spawn_interval:
		spawn_chest()
		chest_spawn_timer = 0.0

func update_ui():
	# Update time display
	if has_node("UILayer/TimeLabel"):
		var total_seconds = int(game_time)
		var minutes = total_seconds / 60
		var seconds = total_seconds % 60
		get_node("UILayer/TimeLabel").text = "Time: %02d:%02d" % [minutes, seconds]

	# Update difficulty display
	if has_node("UILayer/DifficultyLabel"):
		get_node("UILayer/DifficultyLabel").text = "Difficulty: x%.1f" % difficulty_multiplier

	# Update coins display
	if has_node("UILayer/CoinsLabel"):
		get_node("UILayer/CoinsLabel").text = "💰 Coins: %d (+%d)" % [SaveSystem.total_coins, SaveSystem.coins_this_run]

func get_random_enemy_config() -> EnemyConfig:
	# Weighted random: Goblin 43.5%, Sprite 21.7%, Ogre 13%, Wraith 13%, Spore 8.7%
	var rand = randf()
	if rand < 0.435:
		return goblin_config
	elif rand < 0.652:  # 0.435 + 0.217 = 0.652
		return sprite_config
	elif rand < 0.782:  # 0.652 + 0.130 = 0.782
		return ogre_config
	elif rand < 0.913:  # 0.782 + 0.131 = 0.913
		return wraith_config
	else:
		return spore_config

func spawn_enemy():
	var enemy = enemy_scene.instantiate()

	# Apply random enemy type config
	var config = get_random_enemy_config()
	enemy.apply_config(config)

	# Apply difficulty scaling based on game time
	enemy.max_health *= difficulty_multiplier
	enemy.current_health = enemy.max_health
	enemy.move_speed *= sqrt(difficulty_multiplier)  # Scale speed slower than health
	enemy.damage_amount *= difficulty_multiplier

	# Give enemy reference to player
	enemy.player = $Player

	# Elite chance increases over time (base 5% + 1% per minute)
	var time_minutes = game_time / 60.0
	var elite_chance = base_elite_spawn_chance + (time_minutes * 0.01)
	if randf() < elite_chance:
		enemy.make_elite()

	# Spawn enemies around player (off-screen)
	var player_pos = $Player.global_position
	var spawn_distance = 700.0  # Distance from player
	var angle = randf() * TAU  # Random angle

	enemy.position = player_pos + Vector2(cos(angle), sin(angle)) * spawn_distance

	# Add enemy to scene
	add_child(enemy)

func spawn_boss():
	var boss = boss_scene.instantiate()
	var boss_config = preload("res://resources/enemy_boss.tres")
	boss.apply_config(boss_config)
	boss.player = $Player

	# Apply difficulty scaling
	boss.max_health *= difficulty_multiplier
	boss.current_health = boss.max_health
	boss.damage_amount *= difficulty_multiplier

	# Spawn boss around player (off-screen)
	var player_pos = $Player.global_position
	var spawn_distance = 800.0  # Farther away than regular enemies
	var angle = randf() * TAU

	boss.position = player_pos + Vector2(cos(angle), sin(angle)) * spawn_distance

	add_child(boss)
	boss_active = true

	# Connect to boss death to reset boss_active
	boss.tree_exited.connect(_on_boss_died)

	print("BOSS SPAWNED! Time: %.1f seconds" % game_time)

func _on_boss_died():
	boss_active = false
	print("Boss defeated! Next boss in %.0f seconds" % boss_spawn_interval)

func spawn_chest():
	var chest = chest_drop_scene.instantiate()

	# Random config
	var config = item_configs[randi() % item_configs.size()]
	chest.apply_config(config)

	# Random position near player (visible on screen)
	var player_pos = $Player.global_position
	var offset_x = randf_range(-400, 400)
	var offset_y = randf_range(-300, 300)
	chest.position = player_pos + Vector2(offset_x, offset_y)

	add_child(chest)
	print("Chest spawned with item: %s" % config.item_name)

func _on_debug_level_up():
	# Debug function to trigger level up manually
	print("DEBUG: Forcing level up!")
	if has_node("Player"):
		$Player.level_up()

func _on_debug_die():
	# Debug function to show death screen with mock data
	print("DEBUG: Showing death screen with mock data!")

	# Create mock stats
	var mock_stats = {
		"time_survived": 342.5,  # 5 minutes 42 seconds
		"level": 15,
		"total_kills": 456,
		"total_damage": 125430.0,  # Will show as "125.4k"
		"total_xp": 3250
	}

	# Show death screen
	if has_node("UILayer/DeathScreen"):
		$UILayer/DeathScreen.show_death_screen(mock_stats)

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Switched to windowed mode")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Switched to fullscreen mode")

func _toggle_character_screen():
	# Check if character screen is already open
	if has_node("UILayer/CharacterScreen"):
		print("Character screen already open")
		return

	# Create and show character screen
	var char_screen = character_screen_scene.instantiate()

	# Set player reference BEFORE adding to tree
	if has_node("Player"):
		char_screen.set_player($Player)
		print("Player reference passed to character screen")
	else:
		print("WARNING: Could not find Player node!")

	$UILayer.add_child(char_screen)

	# Pause the game when character screen is open
	get_tree().paused = true

	# Resume when closed
	char_screen.tree_exited.connect(func():
		get_tree().paused = false
		print("Character screen closed, game resumed")
	)

	print("Character screen opened (Press ESC or close button to exit)")
