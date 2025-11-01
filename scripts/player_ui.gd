extends Control

# Player UI that follows the player - XP bar, level, etc.

@onready var xp_bar = $VBox/XPBar
@onready var level_label = $VBox/LevelLabel

var player: Node2D = null

func _ready():
	# Center the UI above the player
	position = Vector2(-75, -60)  # Centered above player
	z_index = 50  # Above most things

func update_ui(current_xp: int, xp_threshold: int, current_level: int):
	# Update progress bar
	xp_bar.max_value = xp_threshold
	xp_bar.value = current_xp

	# Update level text
	level_label.text = "Lv %d" % current_level
