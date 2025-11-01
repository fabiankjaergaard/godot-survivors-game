extends Area2D

var damage_per_tick: float = 15.0
var tick_rate: float = 0.5  # Damage every 0.5 seconds
var lifetime: float = 5.0  # Pool lasts 5 seconds
var radius: float = 60.0

var time_alive: float = 0.0
var tick_timer: float = 0.0
var player_damage_boost: float = 0.0
var area_damage_mult: float = 0.0

# Track enemies already damaged this tick to prevent double hits
var damaged_this_tick: Array = []

func _ready():
	# Set up collision
	collision_layer = 0
	collision_mask = 2  # Hit enemies
	z_index = 0  # Same level as ground

	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Create visual
	create_visual()

func setup(damage_boost: float = 0.0, area_mult: float = 0.0):
	player_damage_boost = damage_boost
	area_damage_mult = area_mult

func _process(delta):
	time_alive += delta
	tick_timer += delta

	# Clear damaged list each tick
	if tick_timer >= tick_rate:
		damaged_this_tick.clear()
		tick_timer = 0.0

	# Fade out as it ages
	modulate.a = 1.0 - (time_alive / lifetime)

	# Remove when lifetime ends
	if time_alive >= lifetime:
		queue_free()

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies"):
		damage_enemy(parent)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		damage_enemy(body)

func damage_enemy(enemy: Node):
	# Only damage once per tick
	if enemy in damaged_this_tick:
		return

	if enemy.has_method("take_damage"):
		var total_damage = damage_per_tick * (1.0 + player_damage_boost + area_damage_mult)
		enemy.take_damage(total_damage)
		damaged_this_tick.append(enemy)

func create_visual():
	# Create circular collision shape
	var circle = CircleShape2D.new()
	circle.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = circle
	add_child(collision)

	# Create toxic visual - multiple green/purple circles
	for i in range(12):
		var blob = ColorRect.new()
		var size = randf_range(15, 30)
		blob.custom_minimum_size = Vector2(size, size)

		# Random green/purple toxic colors
		var color_choice = randf()
		if color_choice < 0.5:
			blob.color = Color(0.2, 0.8, 0.2, 0.6)  # Toxic green
		else:
			blob.color = Color(0.5, 0.2, 0.8, 0.6)  # Purple

		# Random position within radius
		var angle = randf() * TAU
		var dist = randf() * radius * 0.8
		blob.position = Vector2(cos(angle), sin(angle)) * dist - Vector2(size/2, size/2)

		add_child(blob)

	# Add outer ring for better visibility
	for i in range(16):
		var segment = ColorRect.new()
		segment.custom_minimum_size = Vector2(20, 8)
		segment.color = Color(0.3, 1, 0.3, 0.8)  # Bright green

		var angle = (TAU / 16) * i
		segment.position = Vector2(cos(angle), sin(angle)) * radius - Vector2(10, 4)
		segment.rotation = angle

		add_child(segment)
