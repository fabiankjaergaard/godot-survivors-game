extends Area2D

# Laser projectile settings
var target_position: Vector2 = Vector2.ZERO
var speed: float = 600.0  # Faster than normal projectile
var distance_traveled: float = 0.0
var max_distance: float = 800.0  # Travels farther (reduced for faster cleanup)
var damage: float = 20.0  # More damage than normal
var pierce_count: int = 10  # Pierces through many enemies

# Track hit enemies to avoid hitting same enemy multiple times
var hit_enemies: Array = []

# Custom sprite
var custom_sprite_path: String = ""

func _ready():
	# Connect collision signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Load custom sprite if provided
	if custom_sprite_path != "" and has_node("Sprite2D"):
		var sprite_texture = load(custom_sprite_path)
		if sprite_texture:
			$Sprite2D.texture = sprite_texture
			# Scale to bigger size (assuming 1024x1024 sprite -> ~50px laser)
			$Sprite2D.scale = Vector2(0.05, 0.05)  # Bigger for better visibility
			# Hide ColorRect when using sprite
			if has_node("ColorRect"):
				$ColorRect.visible = false
			print("Loaded custom laser sprite: " + custom_sprite_path)

func _physics_process(delta):
	# Move in straight line toward target
	var direction = (target_position - position).normalized()
	var movement = direction * speed * delta
	position += movement
	distance_traveled += speed * delta

	# Rotate sprite to point toward target (if using custom sprite)
	if custom_sprite_path != "" and has_node("Sprite2D"):
		var angle = direction.angle()
		$Sprite2D.rotation = angle

	# Despawn if traveled too far
	if distance_traveled > max_distance:
		# Instant cleanup - stop all processing and destroy
		set_physics_process(false)
		set_process(false)
		visible = false
		queue_free()

func _on_body_entered(body):
	# Check if we hit an enemy we haven't hit before
	if body.is_in_group("enemies") and not body in hit_enemies:
		body.take_damage(damage)
		hit_enemies.append(body)

		# Despawn after hitting max enemies
		if hit_enemies.size() >= pierce_count:
			# Instant cleanup - stop all processing and destroy
			set_physics_process(false)
			set_process(false)
			visible = false
			queue_free()

func _on_area_entered(area):
	pass  # Laser doesn't interact with other areas
