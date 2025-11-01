extends Node2D

var damage_per_second: float = 30.0
var range: float = 150.0
var cone_angle: float = 60.0  # degrees
var tick_rate: float = 0.1  # Damage every 0.1 seconds
var tick_timer: float = 0.0

var player: Node2D = null
var player_damage_boost: float = 0.0

# Particle effect
var particles: Array = []
var particle_spawn_timer: float = 0.0
var particle_spawn_rate: float = 0.05

func _ready():
	z_index = 5

func setup(p: Node2D, damage_boost: float = 0.0):
	player = p
	player_damage_boost = damage_boost

func _process(delta):
	if not is_instance_valid(player):
		queue_free()
		return

	# Stay at player position
	global_position = player.global_position

	# Tick damage
	tick_timer += delta
	if tick_timer >= tick_rate:
		apply_damage()
		tick_timer = 0.0

	# Spawn flame particles
	particle_spawn_timer += delta
	if particle_spawn_timer >= particle_spawn_rate:
		spawn_flame_particle()
		particle_spawn_timer = 0.0

	# Update existing particles
	for i in range(particles.size() - 1, -1, -1):
		var particle = particles[i]
		if not is_instance_valid(particle):
			particles.remove_at(i)

func apply_damage():
	if not is_inside_tree():
		return

	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var to_enemy = enemy.global_position - global_position
		var distance = to_enemy.length()

		# Check if within range
		if distance > range:
			continue

		# Check if within cone angle
		var forward = Vector2(1, 0)  # Right direction (player faces right)
		var angle_to_enemy = rad_to_deg(forward.angle_to(to_enemy.normalized()))

		if abs(angle_to_enemy) <= cone_angle / 2.0:
			# Apply damage
			if enemy.has_method("take_damage"):
				# Apply damage boost + area damage bonus
				var area_bonus = 0.0
				if player and "area_damage_mult" in player:
					area_bonus = player.area_damage_mult
				var total_damage = (damage_per_second * tick_rate) * (1.0 + player_damage_boost + area_bonus)
				enemy.take_damage(total_damage)

func spawn_flame_particle():
	if not is_inside_tree():
		return

	# Create simple flame visual
	var particle = ColorRect.new()
	var size = randf_range(8, 16)
	particle.custom_minimum_size = Vector2(size, size)
	particle.color = Color(1, randf_range(0.3, 0.8), 0, randf_range(0.6, 0.9))

	# Random position in cone
	var angle = randf_range(-cone_angle / 2.0, cone_angle / 2.0)
	var dist = randf_range(20, range)
	var offset = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * dist

	particle.position = offset - Vector2(size/2, size/2)

	add_child(particle)
	particles.append(particle)

	# Animate particle
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(particle.queue_free)
