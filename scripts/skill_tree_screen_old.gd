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
	for skill_id in SkillTreeSystem.all_skills.keys():
		var skill = SkillTreeSystem.all_skills[skill_id]
		var skill_button = create_skill_button(skill)

		match skill.branch:
			"attack":
				attack_column.add_child(skill_button)
			"defense":
				defense_column.add_child(skill_button)
			"utility":
				utility_column.add_child(skill_button)

func create_skill_button(skill) -> Control:
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
	name_label.add_theme_font_size_override("font_size", 18)
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

	# Button overlay
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = container.custom_minimum_size
	container.add_child(button)
	button.pressed.connect(_on_skill_pressed.bind(skill.skill_id))

	# Visual feedback for locked/unlocked
	var can_unlock = SkillTreeSystem.can_unlock_skill(skill.skill_id)
	if skill.current_level >= skill.max_level:
		container.modulate = Color(0.4, 1, 0.4, 1)  # Green = maxed
		button.disabled = true
	elif skill.current_level > 0:
		container.modulate = Color(0.8, 0.8, 1, 1)  # Light blue = partially unlocked
	elif can_unlock:
		container.modulate = Color(1, 1, 1, 1)  # White = can unlock
	else:
		container.modulate = Color(0.5, 0.5, 0.5, 1)  # Gray = locked
		button.disabled = true

	return container

func _on_skill_pressed(skill_id: String):
	if SkillTreeSystem.unlock_skill(skill_id):
		refresh_ui()
		# Show feedback
		print("Unlocked skill: %s" % skill_id)
	else:
		print("Cannot unlock skill: %s" % skill_id)

func _on_back_pressed():
	queue_free()
