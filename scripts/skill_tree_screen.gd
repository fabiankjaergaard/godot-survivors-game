extends Control

@onready var points_label = $Panel/VBox/Header/PointsLabel
@onready var attack_column = $Panel/VBox/Columns/AttackColumn/SkillList
@onready var defense_column = $Panel/VBox/Columns/DefenseColumn/SkillList
@onready var utility_column = $Panel/VBox/Columns/UtilityColumn/SkillList
@onready var back_button = $Panel/VBox/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	refresh_ui()

func refresh_ui():
	# Update points display
	var available = SkillTreeSystem.get_available_points()
	var total = SkillTreeSystem.total_skill_points
	points_label.text = "Skill Points: %d / %d" % [available, total]

	# Clear existing skills
	for child in attack_column.get_children():
		child.queue_free()
	for child in defense_column.get_children():
		child.queue_free()
	for child in utility_column.get_children():
		child.queue_free()

	# Populate skills by branch
	populate_branch("attack", attack_column)
	populate_branch("defense", defense_column)
	populate_branch("utility", utility_column)

func populate_branch(branch: String, container: Control):
	# Get all skills for this branch sorted by tier
	var branch_skills = []
	for skill_id in SkillTreeSystem.all_skills.keys():
		var skill = SkillTreeSystem.all_skills[skill_id]
		if skill.branch == branch:
			branch_skills.append(skill)

	# Sort by tier
	branch_skills.sort_custom(func(a, b): return a.tier < b.tier)

	var current_tier = 0
	var tier_container = null

	for skill in branch_skills:
		# Create new tier container if needed
		if skill.tier != current_tier:
			current_tier = skill.tier

			# Add spacing
			if tier_container != null:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(0, 10)
				container.add_child(spacer)

			# For choice nodes (tier 2), create horizontal split
			if current_tier == 2:
				var choice_label = Label.new()
				choice_label.text = "═══ CHOOSE YOUR PATH ═══"
				choice_label.add_theme_font_size_override("font_size", 16)
				choice_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
				choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				container.add_child(choice_label)

				tier_container = HBoxContainer.new()
				tier_container.add_theme_constant_override("separation", 10)
				tier_container.alignment = BoxContainer.ALIGNMENT_CENTER
				container.add_child(tier_container)
			else:
				tier_container = container

		# Create skill button
		var skill_button = create_skill_button(skill, branch)

		# For tier 2+, check if this path is locked
		if skill.tier >= 2:
			var chosen_path = SkillTreeSystem.chosen_paths.get(branch, "")
			var is_locked_path = chosen_path != "" and chosen_path != skill.path and skill.path != "shared"

			if is_locked_path:
				skill_button.modulate = Color(0.3, 0.3, 0.3, 0.5)  # Very dark for locked paths

		tier_container.add_child(skill_button)

func create_skill_button(skill, branch: String) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(220, 100)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Icon and Name
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var icon_label = Label.new()
	icon_label.text = skill.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	header.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = skill.skill_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = skill.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	# Level and Cost
	var footer = HBoxContainer.new()
	vbox.add_child(footer)

	var level_label = Label.new()
	level_label.text = "Level: %d/%d" % [skill.current_level, skill.max_level]
	level_label.add_theme_font_size_override("font_size", 14)
	footer.add_child(level_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var cost_label = Label.new()
	cost_label.text = "Cost: %d SP" % skill.cost
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	footer.add_child(cost_label)

	# Choice node indicator
	if skill.is_choice_node:
		var choice_marker = Label.new()
		choice_marker.text = "⚠️ LOCKS PATH"
		choice_marker.add_theme_font_size_override("font_size", 12)
		choice_marker.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))
		choice_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(choice_marker)

	# Button overlay
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = container.custom_minimum_size
	container.add_child(button)
	button.pressed.connect(_on_skill_pressed.bind(skill.skill_id))

	# Visual feedback
	var can_unlock = SkillTreeSystem.can_unlock_skill(skill.skill_id)
	var chosen_path = SkillTreeSystem.chosen_paths.get(branch, "")
	var is_locked_path = chosen_path != "" and chosen_path != skill.path and skill.path != "shared"

	if is_locked_path:
		# Locked by path choice
		container.modulate = Color(0.3, 0.3, 0.3, 0.5)
		button.disabled = true
	elif skill.current_level >= skill.max_level:
		# Maxed out
		container.modulate = Color(0.4, 1, 0.4, 1)
		button.disabled = true
	elif skill.current_level > 0:
		# Partially unlocked
		container.modulate = Color(0.7, 0.7, 1, 1)
	elif can_unlock:
		# Can unlock
		container.modulate = Color(1, 1, 1, 1)
	else:
		# Locked (requirements not met)
		container.modulate = Color(0.5, 0.5, 0.5, 1)
		button.disabled = true

	return container

func _on_skill_pressed(skill_id: String):
	var skill = SkillTreeSystem.all_skills[skill_id]

	# Extra confirmation for choice nodes
	if skill.is_choice_node and skill.current_level == 0:
		print("⚠️ Choosing %s path! This will lock the other path." % skill.path)

	if SkillTreeSystem.unlock_skill(skill_id):
		refresh_ui()
		print("Unlocked skill: %s" % skill_id)
	else:
		print("Cannot unlock skill: %s" % skill_id)

func _on_back_pressed():
	queue_free()
