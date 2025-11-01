extends Area2D

# Sniper projectile - high damage, very fast, pierces one enemy
var target_position: Vector2 = Vector2.ZERO
var speed: float = 800.0  # Much faster than normal
var distance_traveled: float = 0.0
var max_distance: float = 1500.0  # Longer range
var damage: float = 50.0  # High base damage
var is_critical: bool = false

# Piercing
var max_hits: int = 2  # Can pierce one enemy by default
var hits_remaining: int = 2

# Trail effect - longer for sniper
var trail: Line2D = null
var trail_points: Array = []
var max_trail_points: int = 12
var trail_lifetime: float = 0.2

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Create trail effect - orange for sniper
	trail = Line2D.new()
	trail.width = 3.0
	if is_critical:
		trail.default_color = Color(1, 0.2, 0.2, 0.8)  # Red for crits
		trail.width = 4.0
		if has_node("ColorRect"):
			$ColorRect.modulate = Color(1.5, 0.3, 0.3, 1.0)
	else:
		trail.default_color = Color(1, 0.4, 0, 0.7)  # Orange for sniper
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.z_index = -1
	add_child(trail)

func _physics_process(delta):
	# Move in straight line toward target
	var direction = (target_position - position).normalized()
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()

	# Rotate to face direction
	rotation = direction.angle()

	# Update trail
	update_trail(delta)

	# Despawn after max distance
	if distance_traveled >= max_distance:
		queue_free()

func update_trail(delta):
	# Add current position to trail
	trail_points.append({"pos": Vector2.ZERO, "age": 0.0})

	# Age all points
	for point in trail_points:
		point.age += delta

	# Remove old points
	trail_points = trail_points.filter(func(p): return p.age < trail_lifetime)

	# Limit trail points
	if trail_points.size() > max_trail_points:
		trail_points = trail_points.slice(trail_points.size() - max_trail_points, trail_points.size())

	# Update Line2D
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
			queue_free()
