extends Control

# Achievements Screen - Shows all achievements with progress
# Modern design matching shop/character screen style

@onready var scroll_container = $BackgroundPanel/ContentMargin/MainVBox/ScrollContainer
@onready var achievements_list = $BackgroundPanel/ContentMargin/MainVBox/ScrollContainer/AchievementsList
@onready var close_button = $BackgroundPanel/ContentMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/CloseButton
@onready var stats_label = $BackgroundPanel/ContentMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderHBox/StatsLabel

func _ready():
	# Setup background panel style
	setup_background_panel()

	# Setup header panel style
	setup_header_panel()

	# Setup close button
	close_button.pressed.connect(_on_close_pressed)

	# Populate achievements
	populate_achievements()

	# Focus close button for ESC key support
	close_button.grab_focus()

func setup_background_panel():
	# Main background panel style
	var bg_panel = get_node("BackgroundPanel")
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.98)
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color(0.3, 0.3, 0.35, 1)
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bg_panel.add_theme_stylebox_override("panel", bg_style)

func setup_header_panel():
	# Header panel style
	var header = get_node("BackgroundPanel/ContentMargin/MainVBox/HeaderPanel")
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.15, 0.15, 0.18, 1)
	header_style.border_width_bottom = 2
	header_style.border_color = Color(0.8, 0.7, 0.2, 0.5)
	header_style.corner_radius_top_left = 8
	header_style.corner_radius_top_right = 8
	header.add_theme_stylebox_override("panel", header_style)

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
	stats_label.text = "Achievements: %d / %d  X" % [unlocked_count, total_count]

func create_achievement_entry(achievement):
	# Main container with custom background
	var entry = Panel.new()
	entry.custom_minimum_size = Vector2(0, 100)

	# Background style based on unlock status
	var style_box = StyleBoxFlat.new()
	if achievement.is_unlocked:
		# Golden/green gradient for unlocked
		style_box.bg_color = Color(0.15, 0.2, 0.1, 0.95)
		style_box.border_width_left = 4
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.8, 0.7, 0.2, 1)  # Gold border
	else:
		# Dark gray for locked
		style_box.bg_color = Color(0.12, 0.12, 0.15, 0.9)
		style_box.border_width_left = 4
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.3, 0.3, 0.35, 1)  # Gray border

	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	entry.add_theme_stylebox_override("panel", style_box)

	# Margin inside panel
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	entry.add_child(margin)

	# Horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# Icon container (colored background circle)
	var icon_container = Panel.new()
	icon_container.custom_minimum_size = Vector2(60, 60)

	var icon_style = StyleBoxFlat.new()
	if achievement.is_unlocked:
		icon_style.bg_color = Color(0.2, 0.6, 0.2, 0.3)  # Green glow
	else:
		icon_style.bg_color = Color(0.2, 0.2, 0.25, 0.5)  # Dark gray
	icon_style.corner_radius_top_left = 30
	icon_style.corner_radius_top_right = 30
	icon_style.corner_radius_bottom_left = 30
	icon_style.corner_radius_bottom_right = 30
	icon_container.add_theme_stylebox_override("panel", icon_style)
	hbox.add_child(icon_container)

	# Icon label (centered in circle)
	var icon = Label.new()
	icon.text = achievement.icon if achievement.is_unlocked else "?"
	icon.add_theme_font_size_override("font_size", 32)
	icon.add_theme_color_override("font_color", Color(1, 1, 1, 1) if achievement.is_unlocked else Color(0.5, 0.5, 0.5, 1))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_container.add_child(icon)

	# Info section (name, description, progress)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(vbox)

	# Name with status indicator
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(name_hbox)

	var name_label = Label.new()
	name_label.text = achievement.name
	name_label.add_theme_font_size_override("font_size", 20)
	if achievement.is_unlocked:
		name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))  # Bright gold
	else:
		name_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7, 1))  # Light gray
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 1)
	name_hbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	vbox.add_child(desc_label)

	# Progress bar (if not unlocked)
	if not achievement.is_unlocked:
		var progress_hbox = HBoxContainer.new()
		progress_hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(progress_hbox)

		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(250, 24)
		progress_bar.max_value = achievement.goal
		progress_bar.value = achievement.progress
		progress_bar.show_percentage = false

		# Custom progress bar style
		var progress_bg = StyleBoxFlat.new()
		progress_bg.bg_color = Color(0.15, 0.15, 0.18, 1)
		progress_bg.corner_radius_top_left = 4
		progress_bg.corner_radius_top_right = 4
		progress_bg.corner_radius_bottom_left = 4
		progress_bg.corner_radius_bottom_right = 4
		progress_bar.add_theme_stylebox_override("background", progress_bg)

		var progress_fill = StyleBoxFlat.new()
		progress_fill.bg_color = Color(0.3, 0.6, 0.9, 1)  # Blue fill
		progress_fill.corner_radius_top_left = 4
		progress_fill.corner_radius_top_right = 4
		progress_fill.corner_radius_bottom_left = 4
		progress_fill.corner_radius_bottom_right = 4
		progress_bar.add_theme_stylebox_override("fill", progress_fill)

		progress_hbox.add_child(progress_bar)

		var progress_text = Label.new()
		progress_text.text = "%d / %d" % [achievement.progress, achievement.goal]
		progress_text.add_theme_font_size_override("font_size", 14)
		progress_text.add_theme_color_override("font_color", Color(0.8, 0.9, 1, 1))
		progress_hbox.add_child(progress_text)

	# Reward panel (right side)
	var reward_panel = Panel.new()
	reward_panel.custom_minimum_size = Vector2(120, 60)

	var reward_style = StyleBoxFlat.new()
	if achievement.is_unlocked:
		reward_style.bg_color = Color(0.2, 0.5, 0.2, 0.4)  # Green background
	else:
		reward_style.bg_color = Color(0.3, 0.25, 0.1, 0.3)  # Dark gold background
	reward_style.corner_radius_top_left = 6
	reward_style.corner_radius_top_right = 6
	reward_style.corner_radius_bottom_left = 6
	reward_style.corner_radius_bottom_right = 6
	reward_panel.add_theme_stylebox_override("panel", reward_style)
	hbox.add_child(reward_panel)

	var reward = Label.new()
	if achievement.is_unlocked:
		reward.text = "[UNLOCKED]\n+%d coins" % achievement.reward_coins
		reward.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))  # Bright green
	else:
		reward.text = "Reward:\n+%d coins" % achievement.reward_coins
		reward.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))  # Gold
	reward.add_theme_font_size_override("font_size", 14)
	reward.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	reward.add_theme_constant_override("outline_size", 1)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_panel.add_child(reward)

	achievements_list.add_child(entry)

func _on_close_pressed():
	queue_free()

func _input(event):
	# Allow ESC key to close
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
