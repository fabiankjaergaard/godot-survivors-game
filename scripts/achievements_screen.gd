extends Control

# Achievements Screen - Shows all achievements with progress

@onready var scroll_container = $Panel/MarginContainer/VBox/ScrollContainer
@onready var achievements_list = $Panel/MarginContainer/VBox/ScrollContainer/AchievementsList
@onready var close_button = $Panel/MarginContainer/VBox/TopBar/CloseButton
@onready var stats_label = $Panel/MarginContainer/VBox/TopBar/StatsLabel

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	populate_achievements()

func populate_achievements():
	# Clear existing achievements
	for child in achievements_list.get_children():
		child.queue_free()

	# Get all achievements
	var all_achievements = AchievementSystem.get_all_achievements()

	# Sort achievements by unlocked status (unlocked first)
	all_achievements.sort_custom(func(a, b): return a.is_unlocked and not b.is_unlocked)

	# Create achievement entries
	for achievement in all_achievements:
		create_achievement_entry(achievement)

	# Update stats
	var unlocked_count = AchievementSystem.get_unlocked_count()
	var total_count = AchievementSystem.get_total_count()
	stats_label.text = "Achievements: %d / %d" % [unlocked_count, total_count]

func create_achievement_entry(achievement):
	# Container for one achievement
	var entry = PanelContainer.new()
	entry.custom_minimum_size = Vector2(0, 80)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	entry.add_child(margin)

	# Horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Icon
	var icon = Label.new()
	icon.text = achievement.icon if achievement.is_unlocked else "🔒"
	icon.add_theme_font_size_override("font_size", 36)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Info (name, description, progress)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = achievement.name
	name_label.add_theme_font_size_override("font_size", 18)
	if achievement.is_unlocked:
		name_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))  # Gold
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))  # Gray
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(desc_label)

	# Progress bar (if not unlocked)
	if not achievement.is_unlocked:
		var progress_hbox = HBoxContainer.new()
		progress_hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(progress_hbox)

		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(200, 20)
		progress_bar.max_value = achievement.goal
		progress_bar.value = achievement.progress
		progress_bar.show_percentage = false
		progress_hbox.add_child(progress_bar)

		var progress_text = Label.new()
		progress_text.text = "%d / %d" % [achievement.progress, achievement.goal]
		progress_text.add_theme_font_size_override("font_size", 12)
		progress_hbox.add_child(progress_text)

	# Reward
	var reward = Label.new()
	if achievement.is_unlocked:
		reward.text = "✓ UNLOCKED\n+%d coins" % achievement.reward_coins
		reward.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))  # Green
	else:
		reward.text = "Reward:\n+%d coins" % achievement.reward_coins
		reward.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))  # Yellow
	reward.add_theme_font_size_override("font_size", 14)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(reward)

	achievements_list.add_child(entry)

func _on_close_pressed():
	queue_free()
