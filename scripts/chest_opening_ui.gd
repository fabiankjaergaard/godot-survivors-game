extends CanvasLayer

signal chest_opened

@onready var chest_sprite = $CenterContainer/PanelContainer/VBoxContainer/ChestSprite
@onready var open_button = $CenterContainer/PanelContainer/VBoxContainer/OpenButton
@onready var coins_label = $CenterContainer/PanelContainer/VBoxContainer/CoinsLabel
@onready var continue_button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton

var coin_amount: int = 0
var is_opened: bool = false

# For item rewards
var item_config: PassiveItemConfig = null
var player_ref: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Stay active when paused
	hide()

	# Connect buttons
	open_button.pressed.connect(_on_open_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	# Update chest sprite to use RewardChestGodot
	if has_node("CenterContainer/PanelContainer/VBoxContainer/ChestSprite"):
		var chest_texture = load("res://RewardChestGodot.png")
		if chest_texture and chest_sprite is Sprite2D:
			chest_sprite.texture = chest_texture
			chest_sprite.scale = Vector2(2.0, 2.0)  # Make it visible in UI

func show_chest(min_coins: int, max_coins: int):
	# Determine coin amount
	coin_amount = randi_range(min_coins, max_coins)

	# Reset state
	is_opened = false
	coins_label.visible = false
	continue_button.visible = false
	open_button.visible = true
	item_config = null
	player_ref = null

	# Update chest sprite to closed state
	if has_node("CenterContainer/PanelContainer/VBoxContainer/ChestSprite"):
		if chest_sprite is ColorRect:
			chest_sprite.color = Color(0.6, 0.4, 0.2, 1)  # Closed = brown

	# Pause game and show UI
	get_tree().paused = true
	show()

	print("Chest ready to open: %d coins inside!" % coin_amount)

func show_chest_with_item(config: PassiveItemConfig, player: Node):
	# Store item config and player reference
	item_config = config
	player_ref = player

	# Reset state
	is_opened = false
	coins_label.visible = false
	continue_button.visible = false
	open_button.visible = true

	# Pause game and show UI
	get_tree().paused = true
	show()

	print("Chest ready to open with item: %s" % config.item_name)

func _on_open_pressed():
	if is_opened:
		return

	is_opened = true

	# Check if this is an item chest or coin chest
	if item_config and player_ref:
		# ITEM CHEST
		print("Opening chest! Got item: %s" % item_config.item_name)

		# Apply item effect to player
		apply_item_effect_to_player()

		# Hide open button
		open_button.visible = false

		# Show item received label with animation
		var item_desc = get_item_description()
		coins_label.text = "✨ %s ✨\n%s" % [item_config.item_name, item_desc]
		coins_label.visible = true
		coins_label.modulate = Color(1, 1, 1, 0)  # Start invisible

		# Animate label
		var tween = create_tween()
		tween.tween_property(coins_label, "modulate", Color(1, 1, 1, 1), 0.5)
		tween.tween_property(coins_label, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(coins_label, "scale", Vector2(1.0, 1.0), 0.2)

		# Show continue button after animation
		await tween.finished
		continue_button.visible = true

		# Emit signal
		chest_opened.emit()

	else:
		# COIN CHEST (original behavior)
		print("Opening chest! Got %d coins!" % coin_amount)

		# Add coins to SaveSystem
		SaveSystem.add_coins(coin_amount)

		# Hide open button
		open_button.visible = false

		# Change chest sprite to opened state
		if chest_sprite is ColorRect:
			chest_sprite.color = Color(0.5, 0.3, 0.1, 1)  # Opened = darker brown

		# Show coins label with animation
		coins_label.text = "💰 +%d COINS! 💰" % coin_amount
		coins_label.visible = true
		coins_label.modulate = Color(1, 1, 1, 0)  # Start invisible

		# Animate coins label
		var tween = create_tween()
		tween.tween_property(coins_label, "modulate", Color(1, 1, 1, 1), 0.5)
		tween.tween_property(coins_label, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(coins_label, "scale", Vector2(1.0, 1.0), 0.2)

		# Show continue button after animation
		await tween.finished
		continue_button.visible = true

		# Emit signal
		chest_opened.emit()

func apply_item_effect_to_player():
	if not item_config or not player_ref:
		return

	match item_config.stat_type:
		"damage":
			player_ref.passive_damage_boost += item_config.stat_value
			print("%s: +%.0f%% permanent damage!" % [item_config.item_name, item_config.stat_value * 100])

		"speed":
			player_ref.passive_speed_boost += item_config.stat_value
			player_ref.move_speed *= (1.0 + item_config.stat_value)
			print("%s: +%.0f%% permanent speed!" % [item_config.item_name, item_config.stat_value * 100])

		"health":
			player_ref.max_health += item_config.stat_value
			player_ref.current_health += item_config.stat_value
			print("%s: +%.0f permanent max HP!" % [item_config.item_name, item_config.stat_value])

			# Update health bar
			var main = player_ref.get_parent()
			if main.has_node("UILayer/HealthProgressBar"):
				main.get_node("UILayer/HealthProgressBar").max_value = player_ref.max_health
				main.get_node("UILayer/HealthProgressBar").value = player_ref.current_health
			if main.has_node("UILayer/HealthLabel"):
				main.get_node("UILayer/HealthLabel").text = "%.0f / %.0f HP" % [player_ref.current_health, player_ref.max_health]

		"xp_gain":
			player_ref.passive_xp_boost += item_config.stat_value
			print("%s: +%.0f%% permanent XP gain!" % [item_config.item_name, item_config.stat_value * 100])

		"pickup_radius":
			player_ref.passive_pickup_boost += int(item_config.stat_value)
			print("%s: +%.0f pickup radius!" % [item_config.item_name, item_config.stat_value])

func get_item_description() -> String:
	if not item_config:
		return ""

	match item_config.stat_type:
		"damage":
			return "+%.0f%% Damage Boost!" % (item_config.stat_value * 100)
		"speed":
			return "+%.0f%% Speed Boost!" % (item_config.stat_value * 100)
		"health":
			return "+%.0f Max HP!" % item_config.stat_value
		"xp_gain":
			return "+%.0f%% XP Gain!" % (item_config.stat_value * 100)
		"pickup_radius":
			return "+%.0f Pickup Radius!" % item_config.stat_value
		_:
			return "Bonus!"

func _on_continue_pressed():
	# Hide UI and unpause game
	hide()
	get_tree().paused = false
	print("Chest closed, game resumed")
