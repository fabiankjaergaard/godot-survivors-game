extends Area2D

# Ice beam projectile - slows enemies
var target_position: Vector2 = Vector2.ZERO
var speed: float = 300.0  # Slower than normal
var distance_traveled: float = 0.0
var max_distance: float = 800.0
var damage: float = 8.0  # Lower damage but slows
var is_critical: bool = false

# Slow effect
var slow_amount: float = 0.5  # 50% slow
var slow_duration: float = 2.0  # 2 seconds

# Piercing
var max_hits: int = 3  # Can hit multiple enemies
var hits_remaining: int = 3

# Particles
var particle_timer: float = 0.0

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Make it glow blue
	if has_node("ColorRect"):
		if is_critical:
			$ColorRect.color = Color(0.5, 1, 1, 1)  # Brighter blue for crits
		else:
			$ColorRect.color = Color(0.3, 0.7, 1, 1)

func _physics_process(delta):
	# Move toward target
	var direction = (target_position - position).normalized()
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()

	# Spawn ice particles
	particle_timer += delta
	if particle_timer >= 0.05:
		particle_timer = 0.0
		spawn_ice_particle()

	# Despawn after max distance
	if distance_traveled >= max_distance:
		queue_free()

func spawn_ice_particle():
	var particle = ColorRect.new()
	particle.size = Vector2(3, 3)
	particle.color = Color(0.7, 0.9, 1, 0.8)
	particle.position = position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
	get_parent().add_child(particle)

	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(particle.queue_free)

func _on_body_entered(body):
	# Check if we hit an enemy
	if body.is_in_group("enemies"):
		body.take_damage(damage, is_critical)

		# Apply slow effect
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, slow_duration)

		hits_remaining -= 1

		# Only despawn if we've hit max number of enemies
		if hits_remaining <= 0:
			queue_free()
