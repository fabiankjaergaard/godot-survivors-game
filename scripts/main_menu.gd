extends Control

@onready var start_button = $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var characters_button = $CenterContainer/VBoxContainer/ButtonContainer/CharactersButton
@onready var upgrades_button = $CenterContainer/VBoxContainer/ButtonContainer/UpgradesButton
@onready var skill_tree_button = $CenterContainer/VBoxContainer/ButtonContainer/SkillTreeButton
@onready var achievements_button = $CenterContainer/VBoxContainer/ButtonContainer/AchievementsButton
@onready var quit_button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label = $CenterContainer/VBoxContainer/SubtitleLabel

# Animation variables
var time_passed: float = 0.0
var achievements_screen_scene = preload("res://scenes/achievements_screen.tscn")
var character_selection_scene = preload("res://scenes/character_selection_screen.tscn")
var character_screen_scene = preload("res://scenes/character_screen.tscn")
var skill_tree_scene = preload("res://scenes/skill_tree_screen.tscn")

func _ready():
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Connect hover effects
	setup_button_hover_effects(start_button)
	setup_button_hover_effects(characters_button)
	setup_button_hover_effects(upgrades_button)
	setup_button_hover_effects(skill_tree_button)
	setup_button_hover_effects(achievements_button)
	setup_button_hover_effects(quit_button)

	# Update upgrades button with coin count
	update_coins_display()

	# Make sure game isn't paused when menu loads
	get_tree().paused = false

	print("Main Menu loaded")
	print("Total coins: %d" % SaveSystem.total_coins)

func setup_button_hover_effects(button: Button):
	# Store original scale
	var original_scale = button.scale

	# Mouse enter - scale up slightly
	button.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", original_scale * 1.08, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

	# Mouse exit - scale back to normal
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", original_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func _process(delta):
	# Handle fullscreen toggle
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()

	# Animate title with subtle pulse
	time_passed += delta
	var scale_factor = 1.0 + sin(time_passed * 2.0) * 0.05
	title_label.scale = Vector2(scale_factor, scale_factor)

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Switched to windowed mode")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Switched to fullscreen mode")

func update_coins_display():
	if SaveSystem.total_coins > 0:
		upgrades_button.text = "[ UPGRADES ] (%d coins)" % SaveSystem.total_coins
	else:
		upgrades_button.text = "[ UPGRADES ]"

func _on_start_pressed():
	print("Starting game as Wizard...")
	# Set Wizard as default character
	SaveSystem.set_value("selected_character", "mage")
	# Start the game directly
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_characters_pressed():
	print("Opening character screen...")

	# Create a temporary equipment manager with Epic Gloves for menu preview
	var temp_equipment_manager = EquipmentManager.new()

	# Create Epic Gloves Godot
	var epic_gloves = Item.new()
	epic_gloves.item_name = "Epic Gloves Godot"
	epic_gloves.description = "Legendary gloves forged in the fires of Godot."
	epic_gloves.icon_path = "res://Items/Gloves/EpicGlovesGodot.png"
	epic_gloves.item_type = Item.ItemType.GLOVES
	epic_gloves.rarity = Item.Rarity.EPIC
	# Gloves = Attack Speed and Damage
	epic_gloves.damage_bonus = 0.12  # 12% damage
	epic_gloves.fire_rate_bonus = 0.15  # 15% attack speed
	epic_gloves.crit_chance_bonus = 0.05  # 5% crit
	epic_gloves.sell_value = 200

	# Equip the gloves to temporary equipment manager
	temp_equipment_manager.equipped_gloves = epic_gloves

	# Add all 7 staffs to inventory
	# Staff 1 - Staff of Embers (Common)
	var staff1 = Item.new()
	staff1.item_name = "Staff of Embers"
	staff1.description = "A simple wooden staff with a faint glow."
	staff1.icon_path = "res://Staffs/Staff1Godot.png"
	staff1.item_type = Item.ItemType.WEAPON
	staff1.rarity = Item.Rarity.COMMON
	staff1.damage_bonus = 0.05
	staff1.fire_rate_bonus = 0.03
	staff1.sell_value = 10
	temp_equipment_manager.add_to_inventory(staff1)

	# Staff 2 - Staff of Nature (Common)
	var staff2 = Item.new()
	staff2.item_name = "Staff of Nature"
	staff2.description = "A staff carved from ancient oak."
	staff2.icon_path = "res://Staffs/Staff2Godot.png"
	staff2.item_type = Item.ItemType.WEAPON
	staff2.rarity = Item.Rarity.COMMON
	staff2.damage_bonus = 0.08
	staff2.fire_rate_bonus = 0.05
	staff2.sell_value = 12
	temp_equipment_manager.add_to_inventory(staff2)

	# Staff 3 - Staff of Frost (Uncommon)
	var staff3 = Item.new()
	staff3.item_name = "Staff of Frost"
	staff3.description = "An icy staff that chills enemies."
	staff3.icon_path = "res://Staffs/Staff3Godot.png"
	staff3.item_type = Item.ItemType.WEAPON
	staff3.rarity = Item.Rarity.UNCOMMON
	staff3.damage_bonus = 0.10
	staff3.fire_rate_bonus = 0.08
	staff3.crit_chance_bonus = 0.03
	staff3.sell_value = 25
	temp_equipment_manager.add_to_inventory(staff3)

	# Staff 4 - Staff of Lightning (Uncommon)
	var staff4 = Item.new()
	staff4.item_name = "Staff of Lightning"
	staff4.description = "Crackling with electrical energy."
	staff4.icon_path = "res://Staffs/Staff4Godot.png"
	staff4.item_type = Item.ItemType.WEAPON
	staff4.rarity = Item.Rarity.UNCOMMON
	staff4.damage_bonus = 0.12
	staff4.fire_rate_bonus = 0.10
	staff4.crit_chance_bonus = 0.05
	staff4.sell_value = 30
	temp_equipment_manager.add_to_inventory(staff4)

	# Staff 5 - Staff of Shadows (Rare)
	var staff5 = Item.new()
	staff5.item_name = "Staff of Shadows"
	staff5.description = "A dark staff imbued with shadow magic."
	staff5.icon_path = "res://Staffs/Staff5Godot.png"
	staff5.item_type = Item.ItemType.WEAPON
	staff5.rarity = Item.Rarity.RARE
	staff5.damage_bonus = 0.15
	staff5.fire_rate_bonus = 0.12
	staff5.crit_chance_bonus = 0.08
	staff5.sell_value = 60
	temp_equipment_manager.add_to_inventory(staff5)

	# Staff 6 - Staff of the Archmage (Rare)
	var staff6 = Item.new()
	staff6.item_name = "Staff of the Archmage"
	staff6.description = "Once wielded by a legendary wizard."
	staff6.icon_path = "res://Staffs/Staff6Godot.png"
	staff6.item_type = Item.ItemType.WEAPON
	staff6.rarity = Item.Rarity.RARE
	staff6.damage_bonus = 0.18
	staff6.fire_rate_bonus = 0.15
	staff6.crit_chance_bonus = 0.10
	staff6.sell_value = 80
	temp_equipment_manager.add_to_inventory(staff6)

	# Staff 7 - Staff of Cosmic Power (Epic)
	var staff7 = Item.new()
	staff7.item_name = "Staff of Cosmic Power"
	staff7.description = "Forged from stardust and chaos energy."
	staff7.icon_path = "res://Staffs/Staff7Godot.png"
	staff7.item_type = Item.ItemType.WEAPON
	staff7.rarity = Item.Rarity.EPIC
	staff7.damage_bonus = 0.25
	staff7.fire_rate_bonus = 0.18
	staff7.crit_chance_bonus = 0.12
	staff7.sell_value = 150
	temp_equipment_manager.add_to_inventory(staff7)

	# Rare Helmet
	var rare_helmet = Item.new()
	rare_helmet.item_name = "Rare Helmet"
	rare_helmet.description = "A sturdy helmet forged from rare metals."
	rare_helmet.icon_path = "res://Items/Helmet/RareHelmetGodot.png"
	rare_helmet.item_type = Item.ItemType.HELMET
	rare_helmet.rarity = Item.Rarity.RARE
	# Helmet = Protection (HP and Armor)
	rare_helmet.health_bonus = 25.0
	rare_helmet.armor_bonus = 0.10
	rare_helmet.sell_value = 50
	temp_equipment_manager.add_to_inventory(rare_helmet)

	# Legendary Ring
	var legendary_ring = Item.new()
	legendary_ring.item_name = "Legendary Ring"
	legendary_ring.description = "A mystical ring of incredible power."
	legendary_ring.icon_path = "res://Items/Rings/LegendaryRingGodot.png"
	legendary_ring.item_type = Item.ItemType.RING
	legendary_ring.rarity = Item.Rarity.LEGENDARY
	# Ring = Magical bonuses (Crit, Luck, Damage)
	legendary_ring.damage_bonus = 0.15
	legendary_ring.crit_chance_bonus = 0.12
	legendary_ring.luck_bonus = 0.15
	legendary_ring.sell_value = 150
	temp_equipment_manager.add_to_inventory(legendary_ring)

	# Legendary Ring 2 - Ring of Swiftness
	var legendary_ring2 = Item.new()
	legendary_ring2.item_name = "Ring of Swiftness"
	legendary_ring2.description = "An ancient ring that enhances speed and precision."
	legendary_ring2.icon_path = "res://Items/Rings/LegendaryRing2Godot.png"
	legendary_ring2.item_type = Item.ItemType.RING
	legendary_ring2.rarity = Item.Rarity.LEGENDARY
	# Ring 2 = Speed-focused (Crit Damage, Fire Rate, Cooldown)
	legendary_ring2.crit_damage_bonus = 0.30  # 30% crit damage
	legendary_ring2.fire_rate_bonus = 0.15  # 15% fire rate
	legendary_ring2.cooldown_reduction_bonus = 0.20  # 20% cooldown reduction
	legendary_ring2.sell_value = 150
	temp_equipment_manager.add_to_inventory(legendary_ring2)

	# Show character screen as overlay
	var char_screen = character_screen_scene.instantiate()

	# Set the temporary equipment manager BEFORE adding to tree
	# (so it's available when _ready() is called)
	char_screen.equipment_manager = temp_equipment_manager

	add_child(char_screen)

	# Force update display after adding to tree (just to be safe)
	await get_tree().process_frame
	char_screen.update_display()
	char_screen.update_inventory_display()

	print("✅ Epic Gloves, 7 staffs, Rare Helmet, and 2 Legendary Rings loaded in character screen!")

func _on_upgrades_pressed():
	print("Opening shop...")
	# Transition to shop scene
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_skill_tree_pressed():
	print("Opening skill tree...")
	# Show skill tree screen as overlay
	var skill_tree = skill_tree_scene.instantiate()
	add_child(skill_tree)

func _on_achievements_pressed():
	print("Opening achievements...")
	# Show achievements screen as overlay
	var achievements_screen = achievements_screen_scene.instantiate()
	add_child(achievements_screen)

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
