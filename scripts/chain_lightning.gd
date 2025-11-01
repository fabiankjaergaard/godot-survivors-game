extends Line2D

var damage: float = 25.0
var max_bounces: int = 4
var bounce_range: float = 200.0
var lifetime: float = 0.3
var time_elapsed: float = 0.0

var hit_enemies: Array = []
var current_position: Vector2
var player_damage_boost: float = 0.0

func _ready():
	width = 3.0
	default_color = Color(0.5, 0.8, 1, 1)
	z_index = 10

func start_chain(start_pos: Vector2, first_target: Node2D, player_boost: float = 0.0):
	player_damage_boost = player_boost
	current_position = start_pos
	add_point(start_pos)

	if first_target:
		chain_to_target(first_target)

func chain_to_target(target: Node2D):
	if not is_instance_valid(target) or target in hit_enemies:
		return

	# Add point to line
	add_point(target.position)
	current_position = target.position

	# Deal damage
	if target.has_method("take_damage"):
		# Chain lightning is AoE, so apply area damage bonus if available
		var area_bonus = 0.0
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and "area_damage_mult" in player_node:
			area_bonus = player_node.area_damage_mult
		var total_damage = damage * (1.0 + player_damage_boost + area_bonus)
		target.take_damage(total_damage)

	hit_enemies.append(target)

	# Find next target if we have bounces left
	if hit_enemies.size() < max_bounces:
		var next_target = find_nearest_enemy(target.position)
		if next_target:
			chain_to_target(next_target)

func find_nearest_enemy(from_pos: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_dist = bounce_range + 1

	for enemy in enemies:
		if enemy in hit_enemies:
			continue

		var dist = from_pos.distance_to(enemy.position)
		if dist <= bounce_range and dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest

func _process(delta):
	time_elapsed += delta

	# Fade out
	modulate.a = 1.0 - (time_elapsed / lifetime)

	if time_elapsed >= lifetime:
		queue_free()
