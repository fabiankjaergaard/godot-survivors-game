extends Area2D

# Health pickup settings
var heal_amount: float = 20.0
var pickup_radius: float = 50.0  # Distance at which player can pick up
var move_to_player: bool = false
var move_speed: float = 300.0

func _ready():
	# Connect to player detection
	body_entered.connect(_on_body_entered)

	# Add to pickups group
	add_to_group("pickups")

func _physics_process(delta):
	# Check distance to player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var distance = position.distance_to(player.position)

	# Start moving toward player if close enough
	if distance <= pickup_radius:
		move_to_player = true

	# Move toward player
	if move_to_player:
		var direction = (player.position - position).normalized()
		position += direction * move_speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Heal the player
		if body.has_method("heal"):
			body.heal(heal_amount)

		# Visual feedback
		print("Health pickup! +%.0f HP" % heal_amount)

		# Remove pickup
		queue_free()
