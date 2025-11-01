extends CanvasLayer

@onready var time_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/TimeValue
@onready var level_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/LevelValue
@onready var kills_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/KillsValue
@onready var damage_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/DamageValue
@onready var xp_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/XPValue
@onready var skill_points_label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/SkillPointsValue

@onready var restart_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/QuitButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Stay active when paused
	hide()

	# Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_death_screen(stats: Dictionary):
	# Format time
	var total_seconds = int(stats.get("time_survived", 0))
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

	# Set other stats
	var level_reached = stats.get("level", 1)
	level_label.text = str(level_reached)
	kills_label.text = str(stats.get("total_kills", 0))

	# Format damage
	var total_damage = stats.get("total_damage", 0)
	if total_damage >= 1000000:
		damage_label.text = "%.2fM" % (total_damage / 1000000.0)
	elif total_damage >= 1000:
		damage_label.text = "%.1fk" % (total_damage / 1000.0)
	else:
		damage_label.text = str(int(total_damage))

	xp_label.text = str(stats.get("total_xp", 0))

	# Calculate and award skill points
	var skill_points_earned = calculate_skill_points(stats)
	SkillTreeSystem.add_skill_points(skill_points_earned)
	skill_points_label.text = str(skill_points_earned)

	# Show the death screen
	show()
	get_tree().paused = true

func calculate_skill_points(stats: Dictionary) -> int:
	var points = 0

	# Base points for completing a run
	points += 1

	# Bonus points based on level reached
	var level = stats.get("level", 1)
	if level >= 10:
		points += 1
	if level >= 20:
		points += 1
	if level >= 30:
		points += 2
	if level >= 40:
		points += 2
	if level >= 50:
		points += 3

	# Bonus points for survival time (1 point per 5 minutes)
	var time_survived = stats.get("time_survived", 0)
	points += int(time_survived / 300)

	# Bonus points for kills milestones
	var kills = stats.get("total_kills", 0)
	if kills >= 100:
		points += 1
	if kills >= 500:
		points += 1
	if kills >= 1000:
		points += 2

	# Boss kills give extra points
	var boss_kills = stats.get("boss_kills", 0)
	points += boss_kills * 2

	return points

func _on_restart_pressed():
	print("Restarting game...")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
