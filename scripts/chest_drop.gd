extends Area2D

# Item config - the passive item reward inside the chest
var config: PassiveItemConfig
var pickup_radius: float = 80.0

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("chest_drops")

	# Set chest sprite
	var chest_texture = load("res://RewardChestGodot.png")
	if chest_texture:
		sprite.texture = chest_texture
		sprite.scale = Vector2(0.5, 0.5)  # Adjust size as needed

func _physics_process(delta):
	# Add a subtle float animation
	sprite.position.y = sin(Time.get_ticks_msec() / 500.0) * 3.0

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Show chest opening UI
		open_chest_ui(body)

func open_chest_ui(player: Node):
	print("Player touched chest! Opening UI...")

	# Get the chest opening UI from main scene
	var main = get_tree().root.get_node("Main")
	if main and main.has_node("UILayer/ChestOpeningUI"):
		var chest_ui = main.get_node("UILayer/ChestOpeningUI")

		# Pass the item config and player reference to the UI
		chest_ui.show_chest_with_item(config, player)

		# Remove the chest from world after opening UI
		queue_free()
	else:
		print("ERROR: Could not find ChestOpeningUI!")
		# Fallback: apply item directly
		apply_item_effect(player)
		queue_free()

func apply_item_effect(player: Node):
	if not config:
		return

	match config.stat_type:
		"damage":
			player.passive_damage_boost += config.stat_value
			print("%s: +%.0f%% permanent damage!" % [config.item_name, config.stat_value * 100])

		"speed":
			player.passive_speed_boost += config.stat_value
			player.move_speed *= (1.0 + config.stat_value)
			print("%s: +%.0f%% permanent speed!" % [config.item_name, config.stat_value * 100])

		"health":
			player.max_health += config.stat_value
			player.current_health += config.stat_value
			print("%s: +%.0f permanent max HP!" % [config.item_name, config.stat_value])

			# Update health bar
			var main = player.get_parent()
			if main.has_node("UILayer/HealthProgressBar"):
				main.get_node("UILayer/HealthProgressBar").max_value = player.max_health
				main.get_node("UILayer/HealthProgressBar").value = player.current_health
			if main.has_node("UILayer/HealthLabel"):
				main.get_node("UILayer/HealthLabel").text = "%.0f / %.0f HP" % [player.current_health, player.max_health]

		"xp_gain":
			player.passive_xp_boost += config.stat_value
			print("%s: +%.0f%% permanent XP gain!" % [config.item_name, config.stat_value * 100])

		"pickup_radius":
			player.passive_pickup_boost += int(config.stat_value)
			print("%s: +%.0f pickup radius!" % [config.item_name, config.stat_value])

func apply_config(new_config: PassiveItemConfig):
	config = new_config
	print("Chest created with item: %s" % config.item_name)
