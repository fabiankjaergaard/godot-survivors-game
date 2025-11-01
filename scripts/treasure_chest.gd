extends Area2D

var min_coins: int = 10
var max_coins: int = 50
var opened: bool = false

var pickup_radius: float = 60.0
var player: Node2D = null

func _ready():
	# Find player
	await get_tree().process_frame
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if opened or not player:
		return

	var distance = position.distance_to(player.position)

	# Show UI when player is close
	if distance < pickup_radius:
		open_chest()

func open_chest():
	if opened:
		return

	opened = true
	print("Treasure chest found!")

	# Find the ChestOpeningUI in the main scene
	var main = get_parent()
	if main.has_node("ChestOpeningUI"):
		var chest_ui = main.get_node("ChestOpeningUI")
		chest_ui.show_chest(min_coins, max_coins)

		# Wait for chest to be opened
		await chest_ui.chest_opened

	# Remove chest
	queue_free()

func set_coin_range(min_val: int, max_val: int):
	min_coins = min_val
	max_coins = max_val
