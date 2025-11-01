extends Label

# Damage number settings
var velocity: Vector2 = Vector2(0, -50)  # Float upwards
var lifetime: float = 1.0  # How long it lasts
var fade_start: float = 0.5  # When to start fading
var time_alive: float = 0.0

# Randomize horizontal movement slightly
var horizontal_spread: float = 20.0
var target_scale: Vector2 = Vector2(1.0, 1.0)

func _ready():
	# Add some random horizontal movement
	velocity.x = randf_range(-horizontal_spread, horizontal_spread)

	# Make sure it's on top of everything
	z_index = 100

	# Pop-in animation
	scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta):
	time_alive += delta

	# Move upward
	position += velocity * delta

	# Slow down over time
	velocity *= 0.95

	# Fade out
	if time_alive >= fade_start:
		var fade_progress = (time_alive - fade_start) / (lifetime - fade_start)
		modulate.a = 1.0 - fade_progress

	# Remove when lifetime is up
	if time_alive >= lifetime:
		queue_free()

func set_damage(damage_amount: float, is_critical: bool = false):
	# Format the damage text
	if damage_amount >= 1000:
		text = "%.1fk" % (damage_amount / 1000.0)
	else:
		text = str(int(damage_amount))

	# Set color and size based on damage type
	if is_critical:
		# Critical hits are bigger and red
		add_theme_font_size_override("font_size", 36)
		add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
		text = "CRIT! " + text
		target_scale = Vector2(1.5, 1.5)
		velocity.y = -70  # Crits float faster
	elif damage_amount >= 100:
		# Big hits are orange
		add_theme_font_size_override("font_size", 26)
		add_theme_color_override("font_color", Color(1, 0.6, 0.1, 1))
		target_scale = Vector2(1.2, 1.2)
	elif damage_amount >= 50:
		# Medium hits are yellow
		add_theme_font_size_override("font_size", 22)
		add_theme_color_override("font_color", Color(1, 1, 0.2, 1))
		target_scale = Vector2(1.1, 1.1)
	else:
		# Small hits are white
		add_theme_font_size_override("font_size", 18)
		add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		target_scale = Vector2(1.0, 1.0)

	# Add outline for readability
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 3)
