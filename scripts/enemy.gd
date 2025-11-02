extends CharacterBody2D

# Config
var config: EnemyConfig

# Elite system
var is_elite: bool = false
var elite_multiplier: float = 3.0  # Elite enemies are 3x stronger

# Movement settings
var move_speed: float = 100.0  # Slower than player (200)
var base_move_speed: float = 100.0  # Store base speed for slow effects
var player: CharacterBody2D = null  # Reference to player (set by spawner)

# Slow effect
var is_slowed: bool = false
var slow_multiplier: float = 1.0
var slow_timer: float = 0.0

# Health system
var max_health: float = 20.0
var current_health: float = 20.0

# XP system
var xp_orb_scene = preload("res://scenes/xp_orb.tscn")
var xp_reward: int = 10

# Health pickup system
var health_pickup_scene = preload("res://scenes/health_pickup.tscn")
var health_drop_chance: float = 0.15  # 15% chance to drop health

# Treasure chest system
var treasure_chest_scene = preload("res://scenes/treasure_chest.tscn")

# Particle effects
var damage_particles = preload("res://scenes/damage_particles.tscn")
var death_particles = preload("res://scenes/death_particles.tscn")

# Damage numbers
var damage_number_scene = preload("res://scenes/damage_number.tscn")

# Damage system
var damage_amount: float = 10.0
var attack_interval: float = 1.0  # Deal damage every 1 second
var attack_timer: float = 0.0
var player_touching: bool = false

func _ready():
	# Add to enemies group so weapons can find us
	add_to_group("enemies")
	current_health = max_health

	# Set collision layers - enemies CAN physically collide with player
	collision_layer = 2  # Enemies are on layer 2
	collision_mask = 1   # Collide with player (layer 1) so they don't overlap

	# Set healthbar
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health

	# DON'T connect signals - using distance-based collision instead

func _physics_process(delta):
	# Update slow effect
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0.0:
			is_slowed = false
			slow_multiplier = 1.0
			move_speed = base_move_speed
			# Remove blue tint
			if has_node("Sprite2D"):
				$Sprite2D.modulate = Color(1, 1, 1, 1)

	if player:
		# Calculate direction from enemy to player
		var direction = (player.position - position).normalized()

		# Set velocity toward player
		velocity = direction * move_speed

		# Move with slide (smooth movement, ready for future collisions)
		move_and_slide()

	# Deal damage based on distance instead of area signals
	if not player or not config:
		return

	var distance_to_player = position.distance_to(player.position)
	var touch_distance = (config.size.x / 2.0) + 16.0 + 10.0  # Enemy radius + player radius + 10px buffer for collision
	var reset_distance = touch_distance + 20.0  # Give 20 pixel grace zone

	if distance_to_player < touch_distance:
		# First touch = immediate damage!
		if attack_timer == 0.0:
			if player.has_method("take_damage"):
				player.take_damage(damage_amount, self)  # Pass self for thorns
			attack_timer = 0.01  # Start cooldown
		else:
			attack_timer += delta
			if attack_timer >= attack_interval:
				if player.has_method("take_damage"):
					player.take_damage(damage_amount, self)  # Pass self for thorns
				attack_timer = 0.01  # Reset but not to 0 so we don't trigger instant damage again
	elif distance_to_player > reset_distance:
		# Reset to 0 when far away so next touch triggers instant damage
		attack_timer = 0.0

func take_damage(damage: float, is_critical: bool = false):
	current_health -= damage
	$HealthBar.value = current_health
	print("Enemy hit! Health: %d/%d" % [current_health, max_health])

	# Register damage to player stats
	if player and player.has_method("register_damage"):
		player.register_damage(damage)

	# Hit flash effect
	hit_flash()

	# Spawn damage number
	spawn_damage_number(damage, is_critical)

	# Spawn damage particles
	var particles = damage_particles.instantiate()
	particles.position = position
	particles.emitting = true
	get_parent().add_child(particles)

	# Auto-cleanup particles
	await get_tree().create_timer(particles.lifetime).timeout
	if is_instance_valid(particles):
		particles.queue_free()

	if current_health <= 0:
		die()

func hit_flash():
	# Flash white when hit
	if not is_instance_valid($ColorRect):
		return

	var original_modulate = $ColorRect.modulate
	$ColorRect.modulate = Color(2.0, 2.0, 2.0, 1.0)  # Bright white flash

	# Animate back to normal
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate", original_modulate, 0.1)

func spawn_damage_number(damage: float, is_critical: bool = false):
	var dmg_number = damage_number_scene.instantiate()
	dmg_number.position = position + Vector2(0, -20)  # Slightly above enemy

	# Use critical flag directly (critical takes priority over overkill display)
	dmg_number.set_damage(damage, is_critical)
	get_parent().add_child(dmg_number)

func die():
	print("Enemy defeated!")

	# Register kill to player stats (pass position for explosion on kill)
	if player and player.has_method("register_enemy_kill"):
		player.register_enemy_kill(global_position)

	# Spawn death particles
	var particles = death_particles.instantiate()
	particles.position = position
	particles.color = config.color  # Use enemy's color
	particles.emitting = true
	get_parent().add_child(particles)

	# Spawn XP orb at death position
	var xp_orb = xp_orb_scene.instantiate()
	xp_orb.position = position
	xp_orb.xp_value = xp_reward  # Set XP amount from config
	get_parent().add_child(xp_orb)

	# Chance to spawn health pickup
	if randf() < health_drop_chance:
		var health_pickup = health_pickup_scene.instantiate()
		health_pickup.position = position
		get_parent().add_child(health_pickup)
		print("Health pickup dropped!")

	# Elite enemies always drop treasure chests
	if is_elite:
		var chest = treasure_chest_scene.instantiate()
		chest.position = position
		chest.set_coin_range(10, 50)  # 10-50 coins from regular elites
		get_parent().add_child(chest)
		print("Treasure chest dropped from elite!")

	# REMOVED: Gear items should ONLY drop from reward chests, not from enemies directly
	# This ensures players get gear through the chest opening system

	queue_free()  # Remove enemy from scene

func apply_slow(slow_percent: float, duration: float):
	# Apply slow effect to enemy
	is_slowed = true
	slow_multiplier = 1.0 - slow_percent  # 0.5 = 50% slow
	slow_timer = duration
	move_speed = base_move_speed * slow_multiplier

	# Visual feedback - blue tint
	if has_node("ColorRect"):
		$ColorRect.modulate = Color(0.5, 0.8, 1, 1)

	print("Enemy slowed by %.0f%% for %.1fs" % [slow_percent * 100, duration])

func apply_config(new_config: EnemyConfig):
	config = new_config

	# Apply stats from config
	max_health = config.max_health
	current_health = config.max_health
	move_speed = config.move_speed
	base_move_speed = config.move_speed  # Store base speed
	damage_amount = config.damage_amount
	attack_interval = config.attack_interval
	xp_reward = config.xp_reward

	# Apply visual changes
	load_enemy_sprite()

	# Update collision shapes to match size
	var new_body_shape = RectangleShape2D.new()
	new_body_shape.size = config.size
	$CollisionShape2D.shape = new_body_shape

	var new_damage_shape = RectangleShape2D.new()
	new_damage_shape.size = config.size
	$DamageArea/CollisionShape2D.shape = new_damage_shape
	$DamageArea/CollisionShape2D.disabled = false

	# Update healthbar
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health

func load_enemy_sprite():
	if not has_node("Sprite2D"):
		return

	var sprite = $Sprite2D
	var enemy_texture = null

	# Base scale multiplier to make sprites bigger (2x larger than before)
	var base_scale_multiplier = 2.0

	# Load sprite based on enemy name
	match config.enemy_name:
		"Goblin", "Sprite":
			# Common enemies - green goblin & yellow sprite
			enemy_texture = load("res://Enemy/CommonEnemyGodot.png")
			if enemy_texture:
				sprite.texture = enemy_texture
				var scale_factor = (config.size / Vector2(1024, 1024)) * base_scale_multiplier
				sprite.scale = scale_factor
				print("Loaded CommonEnemyGodot sprite for %s!" % config.enemy_name)

		"Ogre":
			# Rare enemy - red ogre
			enemy_texture = load("res://Enemy/RareEnemyGodot.png")
			if enemy_texture:
				sprite.texture = enemy_texture
				var scale_factor = (config.size / Vector2(1024, 1024)) * base_scale_multiplier
				sprite.scale = scale_factor
				print("Loaded RareEnemyGodot sprite for Ogre!")

		"Wraith", "Spore":
			# Epic enemies - purple wraith & cyan spore
			enemy_texture = load("res://Enemy/EpicEnemyGodot.png")
			if enemy_texture:
				sprite.texture = enemy_texture
				var scale_factor = (config.size / Vector2(1024, 1024)) * base_scale_multiplier
				sprite.scale = scale_factor
				print("Loaded EpicEnemyGodot sprite for %s!" % config.enemy_name)

		_:
			# Boss or other enemies use colored placeholder
			sprite.texture = create_placeholder_texture(config.color, config.size)
			sprite.scale = Vector2(1, 1)
			print("Using placeholder texture for %s" % config.enemy_name)
			return

	# Fallback to colored square if texture failed to load
	if not enemy_texture:
		sprite.texture = create_placeholder_texture(config.color, config.size)
		sprite.scale = Vector2(1, 1)
		print("Failed to load sprite for %s, using placeholder" % config.enemy_name)

func create_placeholder_texture(color: Color, size: Vector2) -> ImageTexture:
	# Create a simple colored square as placeholder
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func make_elite():
	is_elite = true

	# Boost stats
	max_health *= elite_multiplier
	current_health = max_health
	move_speed *= 1.2  # 20% faster
	damage_amount *= 1.5  # 50% more damage
	xp_reward = int(xp_reward * elite_multiplier)
	health_drop_chance = 0.5  # 50% chance for elites

	# Visual changes - golden glow
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.5, 1.5, 0.5, 1)  # Golden tint

	# Add golden border (outline effect with modulate)
	$HealthBar.modulate = Color(1.5, 1.5, 0, 1)  # Golden health bar

	# Scale up slightly
	scale *= 1.3

	# Update healthbar
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health

	print("ELITE ENEMY spawned! HP: %.0f, XP: %d" % [max_health, xp_reward])

# Signal handlers removed - using distance-based collision now
