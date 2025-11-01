extends Line2D

# Projectile trail effect

var max_points: int = 10
var point_lifetime: float = 0.3
var point_timers: Array = []

func _ready():
	width = 3.0
	default_color = Color(1, 1, 1, 0.6)
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

func _process(delta):
	# Age all points
	for i in range(point_timers.size()):
		point_timers[i] += delta

	# Remove old points
	while point_timers.size() > 0 and point_timers[0] >= point_lifetime:
		remove_point(0)
		point_timers.remove_at(0)

	# Fade trail based on age
	for i in range(get_point_count()):
		if i < point_timers.size():
			var age_ratio = point_timers[i] / point_lifetime
			var alpha = 0.6 * (1.0 - age_ratio)
			set_point_color(i, Color(default_color.r, default_color.g, default_color.b, alpha))

func add_trail_point(pos: Vector2):
	# Add new point at the beginning
	add_point(pos, 0)
	point_timers.insert(0, 0.0)

	# Remove excess points
	while get_point_count() > max_points:
		remove_point(get_point_count() - 1)
		point_timers.pop_back()

func set_point_color(index: int, color: Color):
	# Godot Line2D doesn't support per-point colors directly,
	# so we'll use gradient or modulate the whole line
	pass

func set_trail_color(color: Color):
	default_color = color
