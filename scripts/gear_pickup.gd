extends Area2D

# Gear item that this pickup contains
var gear_item: Item = null

# Visual elements
@onready var color_rect = $ColorRect
@onready var label = $Label

# Pickup radius
var pickup_radius: float = 60.0

# Player reference
var player = null

# Animation
var float_offset: float = 0.0
var base_y: float = 0.0

func _ready():
	# Set up collision
	body_entered.connect(_on_body_entered)

	# Store initial Y position for floating animation
	base_y = position.y

	# Find player
	player = get_tree().get_first_node_in_group("player")

	# Visual setup based on item
	if gear_item:
		update_visuals()

func _process(delta):
	# Floating animation
	float_offset += delta * 3.0
	position.y = base_y + sin(float_offset) * 5.0

	# Gentle rotation
	rotation += delta * 0.5

	# Move toward player if close enough
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance < pickup_radius:
			# Pull toward player
			var direction = (player.global_position - global_position).normalized()
			global_position += direction * 300.0 * delta

func update_visuals():
	if not gear_item:
		return

	# Set color based on rarity
	if color_rect:
		color_rect.color = gear_item.get_rarity_color()

	# Set label
	if label:
		label.text = gear_item.item_name
		label.add_theme_color_override("font_color", gear_item.get_rarity_color())

func set_item(item: Item):
	gear_item = item
	if is_inside_tree():
		update_visuals()

func _on_body_entered(body):
	# Check if player picked up this item
	if body.is_in_group("player"):
		pickup(body)

func pickup(body):
	if not gear_item:
		return

	# Add to player's inventory
	if body.has_node("EquipmentManager") or (body.equipment_manager and is_instance_valid(body.equipment_manager)):
		var eq_manager = body.equipment_manager
		if eq_manager.add_to_inventory(gear_item):
			print("Picked up: %s (%s)" % [gear_item.item_name, gear_item.get_rarity_name()])

			# Visual/audio feedback could go here

			# Remove pickup from scene
			queue_free()
		else:
			print("Inventory full! Cannot pick up: %s" % gear_item.item_name)
