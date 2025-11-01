extends CharacterBody2D

# Boss configuration
var config: EnemyConfig
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 100.0
var damage_amount: float = 10.0
var attack_interval: float = 1.0
var xp_reward: int = 10

# Reference to player
var player: Node = null

# Attack cooldown
var attack_timer: float = 0.0

# Boss special attacks
var projectile_scene = preload("res://scenes/projectile.tscn")
var special_attack_timer: float = 0.0
var special_attack_interval: float = 3.0  # Special attack every 3 seconds
var phase: int = 1  # Boss phase (1, 2, or 3)

# Damage numbers
var damage_number_scene = preload("res://scenes/damage_number.tscn")

# Contact damage
var player_touching: bool = false
var melee_attack_timer: float = 0.0

func _ready():
	# Add to enemies group
	add_to_group("enemies")

	# Set collision - CAN physically collide with player
	collision_layer = 2  # Bosses are on layer 2
	collision_mask = 1   # Collide with player (layer 1) so they don't overlap

	# Using distance-based damage, no signals needed

	# Update boss health bar in UI
	update_boss_health_bar()

func apply_config(new_config: EnemyConfig):
	config = new_config
	max_health = config.max_health
	current_health = config.max_health
	move_speed = config.move_speed
	damage_amount = config.damage_amount
	attack_interval = config.attack_interval
	xp_reward = config.xp_reward

	# Apply visual settings
	$ColorRect.color = config.color
	var scale_factor = config.size / Vector2(32, 32)
	$ColorRect.scale = scale_factor
	$CollisionShape2D.shape.size = config.size
	$DamageArea/CollisionShape2D.shape.radius = max(config.size.x, config.size.y) / 2.0

func _physics_process(delta):
	if not player:
		return

	# Move toward player
	var direction = (player.position - position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Attack cooldown
	attack_timer += delta

	# Special attack timer
	special_attack_timer += delta
	if special_attack_timer >= special_attack_interval:
		perform_special_attack()
		special_attack_timer = 0.0

	# Deal melee damage based on distance
	if player and config:
		var distance_to_player = position.distance_to(player.position)
		var touch_distance = (config.size.x / 2.0) + 16.0 + 10.0  # Boss radius + player radius + 10px buffer for collision
		var reset_distance = touch_distance + 20.0  # Grace zone

		if distance_to_player < touch_distance:
			# First touch = immediate damage!
			if melee_attack_timer == 0.0:
				if player.has_method("take_damage"):
					player.take_damage(damage_amount, self)  # Pass self for thorns
				melee_attack_timer = 0.01
			else:
				melee_attack_timer += delta
				if melee_attack_timer >= attack_interval:
					if player.has_method("take_damage"):
						player.take_damage(damage_amount, self)  # Pass self for thorns
					melee_attack_timer = 0.01
		elif distance_to_player > reset_distance:
			melee_attack_timer = 0.0

	# Check phase transitions
	var health_percent = current_health / max_health
	if health_percent <= 0.33 and phase < 3:
		phase = 3
		enter_phase_3()
	elif health_percent <= 0.66 and phase < 2:
		phase = 2
		enter_phase_2()

func perform_special_attack():
	if phase == 1:
		# Phase 1: Shoot 3 projectiles in a spread
		shoot_spread_attack(3, 30.0)
	elif phase == 2:
		# Phase 2: Shoot 5 projectiles in a spread, faster
		shoot_spread_attack(5, 45.0)
		move_speed = config.move_speed * 1.2
	else:  # phase == 3
		# Phase 3: Shoot 8 projectiles in all directions
		shoot_radial_attack(8)
		move_speed = config.move_speed * 1.5

func shoot_spread_attack(count: int, spread_angle: float):
	if not player:
		return

	var direction_to_player = (player.position - position).normalized()
	var base_angle = direction_to_player.angle()

	for i in range(count):
		var angle_offset = (i - (count - 1) / 2.0) * deg_to_rad(spread_angle) / (count - 1)
		var angle = base_angle + angle_offset
		var direction = Vector2(cos(angle), sin(angle))

		spawn_boss_projectile(direction)

func shoot_radial_attack(count: int):
	for i in range(count):
		var angle = (i / float(count)) * TAU
		var direction = Vector2(cos(angle), sin(angle))
		spawn_boss_projectile(direction)

func spawn_boss_projectile(direction: Vector2):
	var projectile = projectile_scene.instantiate()
	projectile.position = position
	projectile.target_position = position + direction * 1000  # Far away target
	projectile.damage = damage_amount * 0.5  # Boss projectiles do 50% of melee damage
	projectile.modulate = Color(1, 0.3, 0.3, 1)  # Red tint for boss projectiles
	get_parent().add_child(projectile)

func enter_phase_2():
	print("Boss entered Phase 2!")
	$ColorRect.color = Color(1, 0.2, 0.2, 1)  # Brighter red
	special_attack_interval = 2.5  # Attack more frequently

func enter_phase_3():
	print("Boss entered Phase 3! ENRAGE!")
	$ColorRect.color = Color(1, 0, 0, 1)  # Pure red
	special_attack_interval = 2.0  # Attack even more frequently

func take_damage(damage: float):
	current_health -= damage

	# Register damage to player stats
	if player and player.has_method("register_damage"):
		player.register_damage(damage)

	# Spawn damage number
	spawn_damage_number(damage)

	# Update health bar
	if $HealthBar:
		$HealthBar.value = (current_health / max_health) * 100.0

	# Update boss health bar in UI
	update_boss_health_bar()

	if current_health <= 0:
		die()

func spawn_damage_number(damage: float):
	var dmg_number = damage_number_scene.instantiate()
	dmg_number.position = position + Vector2(0, -40)  # Higher up for bigger boss

	# Bosses always show big damage numbers
	var is_big_hit = damage >= 50.0
	dmg_number.set_damage(damage, is_big_hit)
	get_parent().add_child(dmg_number)

func update_boss_health_bar():
	var main = get_parent()
	if main.has_node("BossHealthBar"):
		main.get_node("BossHealthBar").max_value = max_health
		main.get_node("BossHealthBar").value = current_health
		main.get_node("BossHealthBar").visible = true
	if main.has_node("BossNameLabel"):
		main.get_node("BossNameLabel").text = "BOSS: %s" % config.enemy_name
		main.get_node("BossNameLabel").visible = true
	if main.has_node("BossHealthLabel"):
		main.get_node("BossHealthLabel").text = "%.0f / %.0f HP" % [current_health, max_health]
		main.get_node("BossHealthLabel").visible = true

func die():
	# Register kill to player stats (pass position for explosion on kill)
	if player and player.has_method("register_enemy_kill"):
		player.register_enemy_kill(global_position)

	# Register boss kill for achievements
	if player and player.has_method("register_boss_kill"):
		player.register_boss_kill()

	# Hide boss health bar
	var main = get_parent()
	if main.has_node("BossHealthBar"):
		main.get_node("BossHealthBar").visible = false
	if main.has_node("BossNameLabel"):
		main.get_node("BossNameLabel").visible = false
	if main.has_node("BossHealthLabel"):
		main.get_node("BossHealthLabel").visible = false

	# Big camera shake for boss death
	if main.has_node("Camera"):
		main.get_node("Camera").shake(0.5, 15.0)

	# Spawn death particles
	var death_particles = preload("res://scenes/death_particles.tscn")
	var particles = death_particles.instantiate()
	particles.position = position
	particles.amount = 50  # More particles for boss
	particles.color = Color(1, 0.2, 0.2, 1)
	particles.emitting = true
	main.add_child(particles)

	# Spawn lots of XP orbs
	var xp_orb_scene = preload("res://scenes/xp_orb.tscn")
	var num_orbs = 15  # Bosses drop many orbs
	for i in range(num_orbs):
		var orb = xp_orb_scene.instantiate()
		orb.position = position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		orb.xp_value = xp_reward / num_orbs
		get_parent().add_child(orb)

	# Bosses always drop treasure chests with lots of coins
	var treasure_chest_scene = preload("res://scenes/treasure_chest.tscn")
	var chest = treasure_chest_scene.instantiate()
	chest.position = position
	chest.set_coin_range(50, 150)  # 50-150 coins from bosses
	get_parent().add_child(chest)
	print("Boss treasure chest dropped!")

	print("Boss defeated! %d XP dropped" % xp_reward)
	queue_free()

# Signal handlers removed - using distance-based collision now
