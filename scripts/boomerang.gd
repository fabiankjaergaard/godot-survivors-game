extends Area2D

var damage: float = 20.0
var speed: float = 400.0
var max_distance: float = 300.0
var rotation_speed: float = 15.0
var return_speed_mult: float = 1.0  # Multiplier for return speed

var start_position: Vector2
var direction: Vector2
var distance_traveled: float = 0.0
var returning: bool = false

var player: Node2D = null
var player_damage_boost: float = 0.0
var hit_enemies: Array = []

func _ready():
	# Connect area signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Set collision
	collision_layer = 0
	collision_mask = 2  # Hit enemies

	# Load boomerang sprite
	load_boomerang_sprite()

func setup(start_pos: Vector2, dir: Vector2, p: Node2D, damage_boost: float = 0.0):
	start_position = start_pos
	position = start_pos
	direction = dir.normalized()
	player = p
	player_damage_boost = damage_boost

func _physics_process(delta):
	# Rotate visual
	rotation += rotation_speed * delta

	if not returning:
		# Move outward
		var movement = direction * speed * delta
		position += movement
		distance_traveled += movement.length()

		# Start returning when max distance reached
		if distance_traveled >= max_distance:
			returning = true
			hit_enemies.clear()  # Can hit enemies again on return
	else:
		# Move back to player
		if is_instance_valid(player):
			direction = (player.global_position - global_position).normalized()
			position += direction * speed * return_speed_mult * delta

			# Check if reached player
			if global_position.distance_to(player.global_position) < 20:
				queue_free()
		else:
			queue_free()

func _on_area_entered(area):
	# Handle collisions with enemies
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		hit_enemy(parent)

func _on_body_entered(body):
	# Handle collisions with enemies
	if body.is_in_group("enemies"):
		hit_enemy(body)

func hit_enemy(enemy: Node):
	if enemy in hit_enemies:
		return

	if enemy.has_method("take_damage"):
		var total_damage = damage * (1.0 + player_damage_boost)
		enemy.take_damage(total_damage)
		hit_enemies.append(enemy)

func load_boomerang_sprite():
	if not has_node("Sprite2D"):
		return

	var sprite = $Sprite2D

	# Load BomerangGodot sprite
	var boomerang_texture = load("res://BomerangGodot.png")
	if boomerang_texture:
		sprite.texture = boomerang_texture
		# Scale from 1024px to ~20px (original size)
		sprite.scale = Vector2(0.0195, 0.0195)  # 1024 * 0.0195 ≈ 20
		print("Loaded BomerangGodot sprite!")
	else:
		print("Failed to load BomerangGodot.png")
