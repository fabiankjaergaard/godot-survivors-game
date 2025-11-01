extends Area2D

# Orbiting bullet settings
var player: Node = null
var orbit_radius: float = 80.0
var orbit_speed: float = 2.0  # Radians per second
var current_angle: float = 0.0
var damage: float = 15.0
var damage_interval: float = 0.3  # Damage cooldown per enemy

# Track damage cooldowns for each enemy
var enemy_damage_timers: Dictionary = {}

func _ready():
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if not player:
		queue_free()
		return

	# Update angle
	current_angle += orbit_speed * delta

	# Calculate position around player
	var offset = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	position = player.position + offset

	# Update damage timers
	for enemy in enemy_damage_timers.keys():
		if is_instance_valid(enemy):
			enemy_damage_timers[enemy] += delta
		else:
			enemy_damage_timers.erase(enemy)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Deal damage if cooldown has passed
		if not enemy_damage_timers.has(body) or enemy_damage_timers[body] >= damage_interval:
			body.take_damage(damage)
			enemy_damage_timers[body] = 0.0

func _on_body_exited(body):
	# Remove from tracking when they leave
	if enemy_damage_timers.has(body):
		enemy_damage_timers.erase(body)
