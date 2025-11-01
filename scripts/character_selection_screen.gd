extends Control

# Debug mode - set to true to unlock all characters for development
const DEBUG_MODE = true

@onready var character_grid = $CenterContainer/PanelContainer/VBoxContainer/CharacterGrid
@onready var character_name_label = $CenterContainer/PanelContainer/VBoxContainer/InfoPanel/VBox/CharacterName
@onready var description_label = $CenterContainer/PanelContainer/VBoxContainer/InfoPanel/VBox/Description
@onready var stats_label = $CenterContainer/PanelContainer/VBoxContainer/InfoPanel/VBox/Stats
@onready var unlock_info_label = $CenterContainer/PanelContainer/VBoxContainer/InfoPanel/VBox/UnlockInfo
@onready var select_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/SelectButton
@onready var coins_label = $CenterContainer/PanelContainer/VBoxContainer/CoinsLabel

var characters: Array[CharacterConfig] = []
var selected_character: CharacterConfig = null
var unlocked_characters: Array = []

func _ready():
	load_characters()
	load_unlocked_characters()

	# Give extra coins in debug mode for testing
	if DEBUG_MODE and SaveSystem.total_coins < 10000:
		SaveSystem.total_coins = 10000
		SaveSystem.save_game()

	update_coins_display()
	populate_character_grid()

func load_characters():
	# Load all character configs
	characters = [
		load("res://resources/character_warrior.tres"),
		load("res://resources/character_assassin.tres"),
		load("res://resources/character_tank.tres"),
		load("res://resources/character_mage.tres"),
		load("res://resources/character_hunter.tres")
	]

func load_unlocked_characters():
	if SaveSystem.has("unlocked_characters"):
		unlocked_characters = SaveSystem.get_value("unlocked_characters")
	else:
		# Warrior is unlocked by default
		unlocked_characters = ["warrior"]
		SaveSystem.set_value("unlocked_characters", unlocked_characters)
		SaveSystem.save_game()

func update_coins_display():
	coins_label.text = "Coins: %d" % SaveSystem.total_coins

func is_character_unlocked(character: CharacterConfig) -> bool:
	if DEBUG_MODE:
		return true  # All characters unlocked in debug mode
	return character.is_unlocked_by_default or unlocked_characters.has(character.character_id)

func populate_character_grid():
	# Clear existing cards
	for child in character_grid.get_children():
		child.queue_free()

	# Create character cards
	for character in characters:
		var card = create_character_card(character)
		character_grid.add_child(card)

func create_character_card(character: CharacterConfig) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 180)

	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 10)
	card.add_child(vbox)

	# Icon
	var icon_label = Label.new()
	icon_label.text = character.icon
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# Name
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Lock/Unlock status
	var is_unlocked = is_character_unlocked(character)

	if not is_unlocked:
		# Lock icon
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 24)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lock_label)

		# Cost
		var cost_label = Label.new()
		cost_label.text = "%d coins" % character.unlock_cost
		cost_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(cost_label)

		# Dim the card
		card.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		# Unlocked checkmark
		var check_label = Label.new()
		check_label.text = "✓ Unlocked"
		check_label.add_theme_color_override("font_color", Color(0, 1, 0, 1))
		check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(check_label)

	# Make card clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = card.custom_minimum_size
	card.add_child(button)
	button.pressed.connect(_on_character_card_pressed.bind(character, button, card))
	button.mouse_entered.connect(_on_character_card_hovered.bind(character))

	return card

func _on_character_card_hovered(character: CharacterConfig):
	display_character_info(character)

func _on_character_card_pressed(character: CharacterConfig, button: Button, card: PanelContainer):
	var is_unlocked = is_character_unlocked(character)

	if not is_unlocked:
		# Try to unlock
		if SaveSystem.total_coins >= character.unlock_cost:
			# Unlock character
			SaveSystem.add_coins(-character.unlock_cost)
			unlocked_characters.append(character.character_id)
			SaveSystem.set_value("unlocked_characters", unlocked_characters)
			SaveSystem.save_game()

			# Refresh UI
			update_coins_display()
			populate_character_grid()
			display_character_info(character)
		else:
			# Not enough coins
			unlock_info_label.text = "Not enough coins!"
			unlock_info_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	else:
		# Select character
		selected_character = character
		select_button.disabled = false

		# Highlight selected card
		for child in character_grid.get_children():
			if child is PanelContainer:
				child.modulate.a = 0.6 if is_character_unlocked(characters[child.get_index()]) else 0.4
		card.modulate.a = 1.0

func display_character_info(character: CharacterConfig):
	character_name_label.text = character.character_name
	description_label.text = character.description

	# Build stats text
	var stats_text = ""
	stats_text += "Health: %.0f | Speed: %.0f | Damage: %.0f%%\n" % [
		character.base_health,
		character.base_speed,
		character.base_damage_mult * 100
	]

	# Special abilities
	var specials = []
	if character.crit_chance_bonus > 0:
		specials.append("+%.0f%% Crit Chance" % (character.crit_chance_bonus * 100))
	if character.crit_damage_mult > 1.5:
		specials.append("%.1fx Crit Damage" % character.crit_damage_mult)
	if character.dash_cooldown_mult < 1.0:
		specials.append("%.0f%% Faster Dash" % ((1.0 - character.dash_cooldown_mult) * 100))
	if character.pickup_radius_bonus > 0:
		specials.append("+%.0f Pickup Radius" % character.pickup_radius_bonus)
	if character.xp_gain_mult > 1.0:
		specials.append("+%.0f%% XP Gain" % ((character.xp_gain_mult - 1.0) * 100))
	if character.start_with_extra_weapon:
		specials.append("Start with 2 weapons")

	if specials.size() > 0:
		stats_text += "\n" + ", ".join(specials)

	stats_label.text = stats_text

	# Unlock info
	var is_unlocked = is_character_unlocked(character)
	if DEBUG_MODE and not character.is_unlocked_by_default and not unlocked_characters.has(character.character_id):
		unlock_info_label.text = "🔓 DEBUG MODE - All Unlocked"
		unlock_info_label.add_theme_color_override("font_color", Color(0, 1, 1, 1))
	elif not is_unlocked:
		unlock_info_label.text = "🔒 %s\nCost: %d coins" % [character.unlock_requirement, character.unlock_cost]
		unlock_info_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	else:
		unlock_info_label.text = ""

func _on_back_pressed():
	queue_free()

func _on_select_pressed():
	if selected_character:
		# Save selected character
		SaveSystem.set_value("selected_character", selected_character.character_id)
		SaveSystem.save_game()

		# Start game
		get_tree().change_scene_to_file("res://scenes/main.tscn")
