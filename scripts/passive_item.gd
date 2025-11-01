extends Area2D

# Item config
var config: PassiveItemConfig
var pickup_radius: float = 80.0
var move_to_player: bool = false
var move_speed: float = 200.0

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("passive_items")

func _physics_process(delta):
	# Check distance to player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var distance = position.distance_to(player.position)

	# Start moving toward player if close enough
	if distance <= pickup_radius:
		move_to_player = true

	# Move toward player
	if move_to_player:
		var direction = (player.position - position).normalized()
		position += direction * move_speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Apply item effect to player
		apply_item_effect(body)

		# Visual feedback
		print("Passive Item picked up: %s" % config.item_name)

		# Remove pickup
		queue_free()

func apply_item_effect(player: Node):
	if not config:
		return

	match config.stat_type:
		"damage":
			# Add permanent damage boost (stacks with upgrades)
			player.passive_damage_boost += config.stat_value
			print("%s: +%.0f%% permanent damage!" % [config.item_name, config.stat_value * 100])

		"speed":
			# Add permanent speed boost
			player.passive_speed_boost += config.stat_value
			player.move_speed *= (1.0 + config.stat_value)
			print("%s: +%.0f%% permanent speed!" % [config.item_name, config.stat_value * 100])

		"health":
			# Add permanent max health
			player.max_health += config.stat_value
			player.current_health += config.stat_value  # Also heal
			print("%s: +%.0f permanent max HP!" % [config.item_name, config.stat_value])

			# Update health bar
			var main = player.get_parent()
			if main.has_node("HealthProgressBar"):
				main.get_node("HealthProgressBar").max_value = player.max_health
				main.get_node("HealthProgressBar").value = player.current_health
			if main.has_node("HealthLabel"):
				main.get_node("HealthLabel").text = "%.0f / %.0f HP" % [player.current_health, player.max_health]

		"xp_gain":
			# Add permanent XP multiplier
			player.passive_xp_boost += config.stat_value
			print("%s: +%.0f%% permanent XP gain!" % [config.item_name, config.stat_value * 100])

		"pickup_radius":
			# Increase XP pickup radius
			player.passive_pickup_boost += int(config.stat_value)
			print("%s: +%.0f pickup radius!" % [config.item_name, config.stat_value])

func apply_config(new_config: PassiveItemConfig):
	config = new_config

	# Apply visual
	$ColorRect.color = config.color

	# Add sparkle effect for passive items
	$ColorRect.modulate = Color(1.5, 1.5, 1.5, 1)
