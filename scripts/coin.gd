extends Area2D

var coin_value: int = 1
var move_speed: float = 400.0
var pickup_radius: float = 80.0
var player: Node2D = null

func _ready():
	# Add to coins group
	add_to_group("coins")

	# Find player
	await get_tree().process_frame
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player:
		return

	var distance = position.distance_to(player.position)

	# Move towards player when close
	if distance < pickup_radius:
		var direction = (player.position - position).normalized()
		position += direction * move_speed * delta

		# Pickup when touching
		if distance < 20.0:
			pickup()

func pickup():
	# Apply luck multiplier if player has it
	var final_coin_value = coin_value
	if player and "luck_multiplier" in player:
		final_coin_value = int(coin_value * (1.0 + player.luck_multiplier))

	# Add coins to save system
	if SaveSystem.has_method("add_coins"):
		SaveSystem.add_coins(final_coin_value)

	print("Collected %d coins (base: %d)! Total: %d" % [final_coin_value, coin_value, SaveSystem.total_coins])

	queue_free()

func set_value(value: int):
	coin_value = value
