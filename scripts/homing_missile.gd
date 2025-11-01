extends Area2D

# Homing missile settings
var target: Node = null
var speed: float = 300.0
var turn_speed: float = 3.0  # How fast it can turn (radians/sec)
var damage: float = 25.0
var lifetime: float = 0.0
var max_lifetime: float = 5.0  # Despawn after 5 seconds

var current_direction: Vector2 = Vector2.RIGHT

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	lifetime += delta

	# Despawn if too old
	if lifetime > max_lifetime:
		queue_free()
		return

	# Update target if current is dead
	if not is_instance_valid(target):
		target = find_nearest_enemy()

	# Move toward target if we have one
	if target:
		var desired_direction = (target.position - position).normalized()

		# Smoothly rotate toward target
		var angle_diff = current_direction.angle_to(desired_direction)
		var max_rotation = turn_speed * delta

		if abs(angle_diff) < max_rotation:
			current_direction = desired_direction
		else:
			var rotation_direction = sign(angle_diff)
			current_direction = current_direction.rotated(rotation_direction * max_rotation)

	# Move in current direction
	position += current_direction * speed * delta

	# Rotate sprite to face direction
	rotation = current_direction.angle()

func find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var nearest = enemies[0]
	var nearest_dist = position.distance_to(nearest.position)

	for enemy in enemies:
		var dist = position.distance_to(enemy.position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()  # Missiles explode on impact
