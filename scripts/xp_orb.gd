extends Area2D

var xp_value: int = 10  # XP amount this orb gives
var initial_y: float = 0.0  # Store initial position for bobbing
var bob_time: float = 0.0
var being_attracted: bool = false  # Is orb moving toward player?

func _ready():
	add_to_group("xp_orbs")
	body_entered.connect(_on_body_entered)
	initial_y = position.y

func _physics_process(delta):
	# Check for player with magnet upgrade and passive pickup boost
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Base pickup radius is 30, magnet adds 50 per level, passive items add directly
		var base_radius = 30.0
		var magnet_level = player.active_upgrades.get("magnet", 0)
		var passive_radius = player.passive_pickup_boost
		var pickup_radius = base_radius + (magnet_level * 50.0) + passive_radius

		var distance_to_player = position.distance_to(player.position)
		if distance_to_player < pickup_radius:
			being_attracted = true

	if being_attracted and player:
		# Move toward player
		var direction = (player.position - position).normalized()
		position += direction * 300.0 * delta
	else:
		# Gentle bobbing animation
		bob_time += delta * 3.0  # Bob speed
		position.y = initial_y + sin(bob_time) * 3.0  # Bob height (3 pixels)

func _on_body_entered(body):
	# Check if player picked up the orb
	if body.name == "Player":
		body.collect_xp(xp_value)
		queue_free()  # Remove orb from scene
