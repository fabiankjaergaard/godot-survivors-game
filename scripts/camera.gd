extends Camera2D

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

var player: Node2D = null

func _ready():
	original_offset = offset

	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		print("Camera found player!")

func _process(delta):
	# Follow player
	if player and is_instance_valid(player):
		global_position = player.global_position

	# Camera shake effect
	if shake_timer > 0:
		shake_timer -= delta

		# Random shake offset
		offset = original_offset + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)

		if shake_timer <= 0:
			offset = original_offset
	else:
		offset = original_offset

func shake(duration: float, amount: float):
	shake_duration = duration
	shake_amount = amount
	shake_timer = duration
