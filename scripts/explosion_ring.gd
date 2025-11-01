extends Node2D

var damage: float = 40.0
var explosion_radius: float = 150.0
var explosion_interval: float = 3.0
var explosion_timer: float = 0.0
var double_explosion: bool = false  # Level 5 feature

var player: Node2D = null
var player_damage_boost: float = 0.0

# Visual effect
var ring_visual: Node2D = null

func _ready():
	z_index = 5
	print("Explosion Ring _ready() called!")

	# Create a small persistent visual indicator (subtle orange circle around player)
	var indicator = ColorRect.new()
	indicator.custom_minimum_size = Vector2(10, 10)
	indicator.position = Vector2(-5, -5)
	indicator.color = Color(1, 0.5, 0, 0.3)  # Transparent orange
	add_child(indicator)

func setup(p: Node2D, damage_boost: float = 0.0):
	player = p
	player_damage_boost = damage_boost
	explosion_timer = explosion_interval - 0.1  # Explode almost immediately (0.1s)
	print("Explosion Ring spawned! Will explode in 0.1s")

func _process(delta):
	if not is_instance_valid(player):
		queue_free()
		return

	# Stay at player position
	global_position = player.global_position

	# Explosion timer
	explosion_timer += delta
	if explosion_timer >= explosion_interval:
		print("Explosion Ring timer triggered! Exploding now!")
		explode()
		explosion_timer = 0.0

func explode():
	if not is_inside_tree():
		return

	print("EXPLOSION RING!")

	# Deal damage to all enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			if enemy.has_method("take_damage"):
				# Apply damage boost + area damage bonus
				var area_bonus = 0.0
				if player and "area_damage_mult" in player:
					area_bonus = player.area_damage_mult
				var total_damage = damage * (1.0 + player_damage_boost + area_bonus)
				enemy.take_damage(total_damage)
				hit_count += 1

	# Spawn visual effect
	spawn_explosion_visual()

	print("Hit %d enemies with explosion!" % hit_count)

	# Double explosion at level 5
	if double_explosion:
		# Wait a tiny bit then explode again
		await get_tree().create_timer(0.15).timeout
		# Second explosion
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy):
				continue
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= explosion_radius:
				if enemy.has_method("take_damage"):
					# Apply damage boost + area damage bonus
					var area_bonus = 0.0
					if player and "area_damage_mult" in player:
						area_bonus = player.area_damage_mult
					var total_damage = damage * (1.0 + player_damage_boost + area_bonus)
					enemy.take_damage(total_damage)
		spawn_explosion_visual()
		print("DOUBLE EXPLOSION!")

func spawn_explosion_visual():
	if not is_inside_tree():
		return

	print("Spawning explosion visual at position: ", global_position)

	# Create GIANT center flash first
	var flash = ColorRect.new()
	flash.custom_minimum_size = Vector2(100, 100)
	flash.position = Vector2(-50, -50)
	flash.color = Color(1, 1, 0, 1.0)  # Bright yellow
	add_child(flash)

	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "scale", Vector2(3, 3), 0.3)
	flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)

	# Create expanding ring visual
	var ring = Node2D.new()
	add_child(ring)

	# Create multiple ring segments (MUCH MORE visible)
	for i in range(32):
		var segment = ColorRect.new()
		segment.custom_minimum_size = Vector2(40, 20)  # Even bigger
		segment.color = Color(1, 0.4, 0, 1.0)  # Bright orange

		var angle = (TAU / 32) * i
		var start_radius = 40.0  # Start even bigger

		segment.position = Vector2(cos(angle), sin(angle)) * start_radius
		segment.rotation = angle

		ring.add_child(segment)

	# Animate ring expanding and fading
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(explosion_radius / 40.0, explosion_radius / 40.0), 0.8)
	tween.tween_property(ring, "modulate:a", 0.0, 0.8)
	tween.tween_callback(ring.queue_free)
