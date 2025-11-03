extends Control

@onready var points_label = $Panel/VBox/Header/PointsLabel
@onready var tree_container = $Panel/VBox/ScrollContainer/TreeContainer
@onready var back_button = $Panel/VBox/BackButton

# Store skill nodes for drawing connections
var skill_nodes: Dictionary = {}

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui():
	# Update points display
	var available = SkillTreeSystem.get_available_points()
	points_label.text = "Points: %d" % available

	# Clear existing tree
	for child in tree_container.get_children():
		child.queue_free()
	skill_nodes.clear()

	# Build classic skill tree layout
	build_classic_tree()

func build_classic_tree():
	# Get all skills grouped by branch and tier
	var branches = ["attack", "defense", "utility"]
	var branch_colors = {
		"attack": Color(1, 0.6, 0.6, 1),
		"defense": Color(0.6, 0.8, 1, 1),
		"utility": Color(0.7, 1, 0.7, 1)
	}
	var branch_names = {
		"attack": "ATTACK",
		"defense": "DEFENSE",
		"utility": "UTILITY"
	}

	# Create 3 columns for 3 branches
	var columns_container = HBoxContainer.new()
	columns_container.add_theme_constant_override("separation", 40)
	columns_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_container.add_child(columns_container)

	for branch in branches:
		var branch_column = VBoxContainer.new()
		branch_column.add_theme_constant_override("separation", 15)
		branch_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns_container.add_child(branch_column)

		# Branch title
		var title = Label.new()
		title.text = branch_names[branch]
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", branch_colors[branch])
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_column.add_child(title)

		# Get skills for this branch sorted by tier
		var branch_skills = []
		for skill_id in SkillTreeSystem.all_skills.keys():
			var skill = SkillTreeSystem.all_skills[skill_id]
			if skill.branch == branch:
				branch_skills.append(skill)

		branch_skills.sort_custom(func(a, b): return a.tier < b.tier)

		# Group by tier
		var current_tier = -1
		var tier_container = null

		for skill in branch_skills:
			# New tier - create tier container
			if skill.tier != current_tier:
				current_tier = skill.tier

				# Add spacing between tiers
				if tier_container != null:
					var spacer = Control.new()
					spacer.custom_minimum_size = Vector2(0, 20)
					branch_column.add_child(spacer)

				# For tier 2 (choice paths), show label and create split
				if current_tier == 2:
					var choice_label = Label.new()
					choice_label.text = "-- CHOOSE PATH --"
					choice_label.add_theme_font_size_override("font_size", 12)
					choice_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
					choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					branch_column.add_child(choice_label)

					tier_container = HBoxContainer.new()
					tier_container.add_theme_constant_override("separation", 10)
					tier_container.alignment = BoxContainer.ALIGNMENT_CENTER
					branch_column.add_child(tier_container)
				else:
					# Normal tier - center align
					tier_container = CenterContainer.new()
					branch_column.add_child(tier_container)

			# Create skill node
			var skill_node = create_skill_node(skill, branch)
			tier_container.add_child(skill_node)

			# Store for connection drawing
			skill_nodes[skill.skill_id] = skill_node

func create_skill_node(skill, branch: String) -> Control:
	# Main container
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(200, 110)

	# Add rounded corners style (simulated with modulate)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Add small spacer at top
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(top_spacer)

	# Skill name - prominent
	var name_label = Label.new()
	name_label.text = skill.skill_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description - smaller, subtle
	var desc_label = Label.new()
	desc_label.text = skill.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Level / Cost footer
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 20)
	vbox.add_child(footer)

	var level_label = Label.new()
	level_label.text = "%d/%d" % [skill.current_level, skill.max_level]
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))
	footer.add_child(level_label)

	var separator = Label.new()
	separator.text = "|"
	separator.add_theme_font_size_override("font_size", 11)
	separator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	footer.add_child(separator)

	var cost_label = Label.new()
	cost_label.text = "%d SP" % skill.cost
	cost_label.add_theme_font_size_override("font_size", 11)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	footer.add_child(cost_label)

	# Button overlay
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = container.custom_minimum_size
	container.add_child(button)
	button.pressed.connect(_on_skill_pressed.bind(skill.skill_id))

	# Visual feedback with border color changes
	var can_unlock = SkillTreeSystem.can_unlock_skill(skill.skill_id)
	var chosen_path = SkillTreeSystem.chosen_paths.get(branch, "")
	var is_locked_path = chosen_path != "" and chosen_path != skill.path and skill.path != "shared"

	if is_locked_path:
		# Locked by path choice - red border, very dark
		style.border_color = Color(0.6, 0.2, 0.2, 1)
		container.modulate = Color(0.3, 0.3, 0.3, 0.5)
		button.disabled = true
	elif skill.current_level >= skill.max_level:
		# Maxed out - gold border
		style.border_color = Color(1, 0.85, 0.3, 1)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		container.modulate = Color(1, 1, 1, 1)
		button.disabled = true
	elif skill.current_level > 0:
		# Partially unlocked - blue border
		style.border_color = Color(0.5, 0.7, 1, 1)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		container.modulate = Color(1, 1, 1, 1)
	elif can_unlock:
		# Can unlock - bright green border
		style.border_color = Color(0.5, 1, 0.5, 1)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		container.modulate = Color(1, 1, 1, 1)
	else:
		# Locked (requirements not met) - dark gray border
		style.border_color = Color(0.3, 0.3, 0.35, 1)
		container.modulate = Color(0.5, 0.5, 0.55, 1)
		button.disabled = true

	return container

func _on_skill_pressed(skill_id: String):
	var skill = SkillTreeSystem.all_skills[skill_id]

	# Extra confirmation for choice nodes
	if skill.is_choice_node and skill.current_level == 0:
		print("Choosing %s path! This will lock the other path." % skill.path)

	if SkillTreeSystem.unlock_skill(skill_id):
		refresh_ui()
		print("Unlocked: %s" % skill_id)
	else:
		print("Cannot unlock: %s" % skill_id)

func _on_back_pressed():
	queue_free()
