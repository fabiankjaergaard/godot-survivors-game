extends Area2D

# Projectile settings
var target_position: Vector2 = Vector2.ZERO
var speed: float = 400.0  # Fast projectile
var distance_traveled: float = 0.0
var max_distance: float = 600.0  # Despawn after traveling this far (reduced for faster cleanup)
var damage: float = 10.0  # Damage dealt to enemies

# Critical hit
var is_critical: bool = false

# Piercing
var max_hits: int = 1  # How many enemies can be hit (1 = no pierce)
var hits_remaining: int = 1

# Custom sprite
var custom_sprite_path: String = ""

# Trail effect
var trail: Line2D = null
var trail_points: Array = []
var max_trail_points: int = 8
var trail_lifetime: float = 0.05  # Shorter trail that disappears faster

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Load custom sprite if provided
	if custom_sprite_path != "" and has_node("Sprite2D"):
		var sprite_texture = load(custom_sprite_path)
		if sprite_texture:
			$Sprite2D.texture = sprite_texture
			# Scale to bigger size (assuming 1024x1024 sprite -> ~50px arrow)
			$Sprite2D.scale = Vector2(0.05, 0.05)  # Bigger for better visibility
			# Hide ColorRect when using sprite
			if has_node("ColorRect"):
				$ColorRect.visible = false
			print("Loaded custom projectile sprite: " + custom_sprite_path)

	# Trail disabled for instant cleanup
	# trail = Line2D.new()
	# trail.width = 2.0
	# # Critical hits have red trail, normal hits have yellow trail
	# if is_critical:
	# 	trail.default_color = Color(1, 0.2, 0.2, 0.7)  # Red for crits
	# 	trail.width = 3.0  # Thicker trail
	# 	# Make crit projectiles slightly bigger
	# 	if has_node("ColorRect"):
	# 		$ColorRect.modulate = Color(1.5, 0.5, 0.5, 1.0)  # Red tint
	# else:
	# 	trail.default_color = Color(1, 1, 0.5, 0.5)  # Yellow for normal
	# trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	# trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	# trail.z_index = -1
	# add_child(trail)

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

	# Update trail (disabled)
	# update_trail(delta)

	# Despawn if traveled too far
	if distance_traveled > max_distance:
		# Instant cleanup - stop all processing and destroy
		set_physics_process(false)
		set_process(false)
		visible = false
		queue_free()

func update_trail(delta):
	# Add current position to trail
	trail_points.append({"pos": Vector2.ZERO, "age": 0.0})  # Local position

	# Age all trail points
	for point in trail_points:
		point.age += delta

	# Remove old points
	trail_points = trail_points.filter(func(p): return p.age < trail_lifetime)

	# Update Line2D points
	trail.clear_points()
	for point in trail_points:
		trail.add_point(point.pos)

func _on_body_entered(body):
	# Check if we hit an enemy
	if body.is_in_group("enemies"):
		body.take_damage(damage, is_critical)
		hits_remaining -= 1

		# Only despawn if we've hit max number of enemies
		if hits_remaining <= 0:
			# Instant cleanup - stop all processing and destroy
			set_physics_process(false)
			set_process(false)
			visible = false
			queue_free()
