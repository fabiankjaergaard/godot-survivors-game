extends CanvasLayer

@onready var back_button = $MarginContainer/PanelContainer/VBoxContainer/BackButton
@onready var coins_label = $MarginContainer/PanelContainer/VBoxContainer/Header/CoinsLabel
@onready var upgrades_container = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/UpgradesContainer

# Gear shop items (regenerated each time shop is opened)
var shop_gear_items: Array[Item] = []
var gear_shop_size: int = 6  # Number of gear items in shop

# Filter system
enum FilterType { ALL, PASSIVE, WEAPONS, GEAR, META }
var current_filter: FilterType = FilterType.ALL

# Filter buttons
var filter_buttons: Array[Button] = []

func _ready():
	# Style the coins label with a background
	style_coins_display()

	# Create filter buttons
	create_filter_buttons()

	# Connect back button
	back_button.pressed.connect(_on_back_pressed)

	# Generate shop gear items
	generate_shop_gear()

	# Update coins display
	update_coins_display()

	# Populate upgrades
	populate_upgrades()

func style_coins_display():
	# Add a styled background panel to coins label
	var header = coins_label.get_parent()
	if not header:
		return

	# Remove coins label from header temporarily
	header.remove_child(coins_label)

	# Create a panel container for the coin display
	var coin_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.8, 0.6, 0.1, 0.3)
	panel_style.border_color = Color(1, 0.8, 0.3, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	coin_panel.add_theme_stylebox_override("panel", panel_style)
	coin_panel.custom_minimum_size = Vector2(200, 60)

	# Create HBox for icon + label
	var coin_hbox = HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 10)
	coin_panel.add_child(coin_hbox)

	# Add coin icon (circle with "C")
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(40, 40)
	coin_hbox.add_child(icon_container)

	var icon_panel = PanelContainer.new()
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(1, 0.8, 0.2, 0.9)
	icon_style.corner_radius_top_left = 20
	icon_style.corner_radius_top_right = 20
	icon_style.corner_radius_bottom_left = 20
	icon_style.corner_radius_bottom_right = 20
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	icon_panel.custom_minimum_size = Vector2(36, 36)
	icon_container.add_child(icon_panel)

	var icon_label = Label.new()
	icon_label.text = "C"
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon_label)

	# Add coins label back
	coin_hbox.add_child(coins_label)

	# Add panel to header
	header.add_child(coin_panel)

func update_coins_display():
	coins_label.text = "%d Coins" % SaveSystem.total_coins

func create_filter_buttons():
	# Get the scroll container's parent (VBoxContainer)
	var vbox = upgrades_container.get_parent().get_parent()

	# Create filter bar container
	var filter_bar = HBoxContainer.new()
	filter_bar.name = "FilterBar"
	filter_bar.add_theme_constant_override("separation", 12)

	# Add spacer for centering
	var spacer_left = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_bar.add_child(spacer_left)

	# Filter label
	var filter_label = Label.new()
	filter_label.text = "FILTER:"
	filter_label.add_theme_font_size_override("font_size", 18)
	filter_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	filter_bar.add_child(filter_label)

	# Create filter buttons
	var filters = [
		{"name": "ALL", "type": FilterType.ALL},
		{"name": "GEAR", "type": FilterType.GEAR},
		{"name": "PASSIVE", "type": FilterType.PASSIVE},
		{"name": "META", "type": FilterType.META}
	]

	for filter_data in filters:
		var btn = Button.new()
		btn.text = filter_data.name
		btn.custom_minimum_size = Vector2(120, 45)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_filter_pressed.bind(filter_data.type))

		filter_buttons.append(btn)
		filter_bar.add_child(btn)

	# Add spacer for centering
	var spacer_right = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_bar.add_child(spacer_right)

	# Insert filter bar after header separator
	var separator_index = -1
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if child.name == "Separator":
			separator_index = i
			break

	if separator_index != -1:
		vbox.add_child(filter_bar)
		vbox.move_child(filter_bar, separator_index + 1)

		# Add spacing after filter bar
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 15)
		vbox.add_child(spacer)
		vbox.move_child(spacer, separator_index + 2)

	# Update button styles
	update_filter_buttons()

func update_filter_buttons():
	for i in range(filter_buttons.size()):
		var btn = filter_buttons[i]
		var is_active = false

		match i:
			0: is_active = current_filter == FilterType.ALL
			1: is_active = current_filter == FilterType.GEAR
			2: is_active = current_filter == FilterType.PASSIVE
			3: is_active = current_filter == FilterType.META

		# Create button style
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8

		if is_active:
			style.bg_color = Color(0.8, 0.6, 0.1, 0.95)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color(1, 0.8, 0.3, 1)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 0.8)
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

func _on_filter_pressed(filter_type: FilterType):
	current_filter = filter_type
	update_filter_buttons()
	populate_upgrades()

func generate_shop_gear():
	# Generate random gear items for the shop
	shop_gear_items.clear()
	for i in range(gear_shop_size):
		var item = GearGenerator.generate_random_item()
		shop_gear_items.append(item)
	print("Generated %d gear items for shop" % shop_gear_items.size())

func populate_upgrades():
	# Clear existing children
	for child in upgrades_container.get_children():
		child.queue_free()

	# Filter content based on current filter
	match current_filter:
		FilterType.ALL:
			_create_gear_shop_section()
			_create_passive_section()
			_create_meta_section()
		FilterType.GEAR:
			_create_gear_shop_section()
		FilterType.PASSIVE:
			_create_passive_section()
		FilterType.META:
			_create_meta_section()

func _create_passive_section():
	# Group passive unlocks
	var passive_unlocks = []
	for unlock_id in SaveSystem.available_unlocks:
		var unlock = SaveSystem.available_unlocks[unlock_id]
		if unlock.get("category", "passive") == "passive":
			passive_unlocks.append({"id": unlock_id, "data": unlock})

	_create_category_section("PASSIVE UPGRADES", passive_unlocks)

func _create_meta_section():
	# Group meta unlocks
	var meta_unlocks = []
	for unlock_id in SaveSystem.available_unlocks:
		var unlock = SaveSystem.available_unlocks[unlock_id]
		if unlock.get("category", "passive") == "meta":
			meta_unlocks.append({"id": unlock_id, "data": unlock})

	_create_category_section("META UPGRADES", meta_unlocks)

func _create_category_section(title: String, unlocks: Array):
	if unlocks.is_empty():
		return

	# Category title with separator line
	var title_container = HBoxContainer.new()
	title_container.add_theme_constant_override("separation", 10)
	upgrades_container.add_child(title_container)

	# Left line
	var left_line = ColorRect.new()
	left_line.color = Color(1, 0.8, 0.3, 0.5)
	left_line.custom_minimum_size = Vector2(80, 2)
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(left_line)

	# Title text
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 3)
	title_container.add_child(title_label)

	# Right line
	var right_line = ColorRect.new()
	right_line.color = Color(1, 0.8, 0.3, 0.5)
	right_line.custom_minimum_size = Vector2(10, 2)
	right_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(right_line)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	upgrades_container.add_child(spacer1)

	# Add each unlock
	for item in unlocks:
		_create_upgrade_item(item.id, item.data)

	# Category spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	upgrades_container.add_child(spacer2)

func _create_upgrade_item(unlock_id: String, unlock_data: Dictionary):
	var is_unlocked = SaveSystem.is_unlocked(unlock_id)
	var can_afford = SaveSystem.total_coins >= unlock_data.cost
	var has_requirements = true

	# Check requirements
	if "requires" in unlock_data:
		for req in unlock_data.requires:
			if not SaveSystem.is_unlocked(req):
				has_requirements = false
				break

	# Container with custom style
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(0, 100)

	# Custom panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	if is_unlocked:
		style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	elif not has_requirements:
		style.border_color = Color(0.3, 0.3, 0.3, 0.4)
	elif can_afford:
		style.border_color = Color(1, 0.8, 0.3, 0.8)
	else:
		style.border_color = Color(0.5, 0.3, 0.3, 0.6)

	item_container.add_theme_stylebox_override("panel", style)
	upgrades_container.add_child(item_container)

	# HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	item_container.add_child(hbox)

	# Icon with background circle
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	hbox.add_child(icon_container)

	var icon_bg = PanelContainer.new()
	var icon_bg_style = StyleBoxFlat.new()
	icon_bg_style.bg_color = Color(0.2, 0.25, 0.35, 0.9)
	icon_bg_style.corner_radius_top_left = 38
	icon_bg_style.corner_radius_top_right = 38
	icon_bg_style.corner_radius_bottom_left = 38
	icon_bg_style.corner_radius_bottom_right = 38
	icon_bg_style.border_width_left = 2
	icon_bg_style.border_width_right = 2
	icon_bg_style.border_width_top = 2
	icon_bg_style.border_width_bottom = 2

	# Border color based on status
	if is_unlocked:
		icon_bg_style.border_color = Color(0.3, 0.8, 0.3, 0.8)
	elif can_afford:
		icon_bg_style.border_color = Color(1, 0.8, 0.3, 0.8)
	else:
		icon_bg_style.border_color = Color(0.4, 0.4, 0.4, 0.6)

	icon_bg.add_theme_stylebox_override("panel", icon_bg_style)
	icon_bg.custom_minimum_size = Vector2(75, 75)
	icon_container.add_child(icon_bg)

	var icon_label = Label.new()
	# Use text-based icons instead of emojis
	var icon_text = unlock_data.get("icon", "?")
	icon_label.text = icon_text
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_bg.add_child(icon_label)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label = Label.new()
	name_label.text = unlock_data.name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1) if not is_unlocked else Color(0.5, 1, 0.5, 1))
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = unlock_data.description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	info_vbox.add_child(desc_label)

	# Buy button or status
	if is_unlocked:
		var status_container = PanelContainer.new()
		var status_style = StyleBoxFlat.new()
		status_style.bg_color = Color(0.2, 0.5, 0.2, 0.4)
		status_style.corner_radius_top_left = 6
		status_style.corner_radius_top_right = 6
		status_style.corner_radius_bottom_left = 6
		status_style.corner_radius_bottom_right = 6
		status_container.add_theme_stylebox_override("panel", status_style)
		status_container.custom_minimum_size = Vector2(140, 60)
		hbox.add_child(status_container)

		var unlocked_label = Label.new()
		unlocked_label.text = "UNLOCKED"
		unlocked_label.add_theme_font_size_override("font_size", 18)
		unlocked_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
		unlocked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlocked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_container.add_child(unlocked_label)
	elif not has_requirements:
		var status_container = PanelContainer.new()
		var status_style = StyleBoxFlat.new()
		status_style.bg_color = Color(0.2, 0.2, 0.2, 0.4)
		status_style.corner_radius_top_left = 6
		status_style.corner_radius_top_right = 6
		status_style.corner_radius_bottom_left = 6
		status_style.corner_radius_bottom_right = 6
		status_container.add_theme_stylebox_override("panel", status_style)
		status_container.custom_minimum_size = Vector2(140, 60)
		hbox.add_child(status_container)

		var locked_label = Label.new()
		locked_label.text = "LOCKED"
		locked_label.add_theme_font_size_override("font_size", 18)
		locked_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_container.add_child(locked_label)
	else:
		var buy_button = Button.new()
		buy_button.text = "%d COINS" % unlock_data.cost
		buy_button.custom_minimum_size = Vector2(160, 70)
		buy_button.add_theme_font_size_override("font_size", 18)
		buy_button.disabled = not can_afford
		buy_button.pressed.connect(_on_buy_pressed.bind(unlock_id))

		# Custom button style
		var button_style = StyleBoxFlat.new()
		if can_afford:
			button_style.bg_color = Color(0.8, 0.6, 0.1, 0.9)
			buy_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			button_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
			buy_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

		button_style.corner_radius_top_left = 6
		button_style.corner_radius_top_right = 6
		button_style.corner_radius_bottom_left = 6
		button_style.corner_radius_bottom_right = 6
		buy_button.add_theme_stylebox_override("normal", button_style)
		buy_button.add_theme_stylebox_override("hover", button_style)
		buy_button.add_theme_stylebox_override("pressed", button_style)

		hbox.add_child(buy_button)

func _on_buy_pressed(unlock_id: String):
	if SaveSystem.unlock_item(unlock_id):
		print("Successfully unlocked: %s" % unlock_id)
		# Refresh the shop display
		populate_upgrades()
		update_coins_display()
	else:
		print("Failed to unlock: %s" % unlock_id)

func _create_gear_shop_section():
	# Category title with separator line
	var title_container = HBoxContainer.new()
	title_container.add_theme_constant_override("separation", 10)
	upgrades_container.add_child(title_container)

	# Left line
	var left_line = ColorRect.new()
	left_line.color = Color(1, 0.6, 0.2, 0.6)
	left_line.custom_minimum_size = Vector2(60, 4)
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(left_line)

	# Title text
	var title_label = Label.new()
	title_label.text = "GEAR SHOP"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1, 0.75, 0.25, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 5)
	title_container.add_child(title_label)

	# Right line
	var right_line = ColorRect.new()
	right_line.color = Color(1, 0.6, 0.2, 0.6)
	right_line.custom_minimum_size = Vector2(10, 4)
	right_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(right_line)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Random gear items refresh each time you visit the shop"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))
	upgrades_container.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	upgrades_container.add_child(spacer1)

	# Create grid for gear items (2 columns)
	var grid_container = GridContainer.new()
	grid_container.columns = 2
	grid_container.add_theme_constant_override("h_separation", 20)
	grid_container.add_theme_constant_override("v_separation", 20)
	upgrades_container.add_child(grid_container)

	# Add each gear item to grid
	for i in range(shop_gear_items.size()):
		_create_gear_item_card(grid_container, i, shop_gear_items[i])

	# Category spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	upgrades_container.add_child(spacer2)

func _create_gear_item_card(grid: GridContainer, index: int, item: Item):
	var can_afford = SaveSystem.total_coins >= item.sell_value

	# Card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Card style with gradient effect
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = item.get_rarity_color()
	card.add_theme_stylebox_override("panel", style)

	grid.add_child(card)

	# Card VBox with padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Top section with icon and name
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(top_hbox)

	# Icon
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(90, 90)
	top_hbox.add_child(icon_container)

	var icon_bg = PanelContainer.new()
	var icon_bg_style = StyleBoxFlat.new()
	icon_bg_style.bg_color = Color(0.2, 0.2, 0.25, 1)
	icon_bg_style.corner_radius_top_left = 12
	icon_bg_style.corner_radius_top_right = 12
	icon_bg_style.corner_radius_bottom_left = 12
	icon_bg_style.corner_radius_bottom_right = 12
	icon_bg_style.border_width_left = 3
	icon_bg_style.border_width_right = 3
	icon_bg_style.border_width_top = 3
	icon_bg_style.border_width_bottom = 3
	icon_bg_style.border_color = item.get_rarity_color()
	icon_bg.add_theme_stylebox_override("panel", icon_bg_style)
	icon_bg.custom_minimum_size = Vector2(85, 85)
	icon_container.add_child(icon_bg)

	var icon_label = Label.new()
	match item.item_type:
		Item.ItemType.WEAPON: icon_label.text = "W"
		Item.ItemType.HELMET: icon_label.text = "H"
		Item.ItemType.CHEST: icon_label.text = "C"
		Item.ItemType.GLOVES: icon_label.text = "G"
		Item.ItemType.LEGS: icon_label.text = "L"
		Item.ItemType.SHOES: icon_label.text = "S"
		Item.ItemType.RING: icon_label.text = "R"
		Item.ItemType.AMULET: icon_label.text = "A"
	icon_label.add_theme_font_size_override("font_size", 44)
	icon_label.add_theme_color_override("font_color", item.get_rarity_color())
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_bg.add_child(icon_label)

	# Name and rarity VBox
	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_vbox)

	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 30)
	name_vbox.add_child(name_label)

	var rarity_label = Label.new()
	rarity_label.text = item.get_rarity_name().to_upper()
	rarity_label.add_theme_font_size_override("font_size", 15)
	rarity_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_vbox.add_child(rarity_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 45)
	vbox.add_child(desc_label)

	# Stats
	var stats_text = get_item_stats_text(item)
	if stats_text != "":
		var stats_label = Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1))
		stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(stats_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buy button at bottom
	var buy_button = Button.new()
	buy_button.text = "BUY FOR %d COINS" % item.sell_value
	buy_button.custom_minimum_size = Vector2(0, 55)
	buy_button.add_theme_font_size_override("font_size", 18)
	buy_button.disabled = not can_afford
	buy_button.pressed.connect(_on_buy_gear_pressed.bind(index))

	var button_style = StyleBoxFlat.new()
	if can_afford:
		button_style.bg_color = Color(0.8, 0.6, 0.1, 1)
		buy_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		button_style.bg_color = Color(0.3, 0.3, 0.3, 0.7)
		buy_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("normal", button_style)
	buy_button.add_theme_stylebox_override("hover", button_style)
	buy_button.add_theme_stylebox_override("pressed", button_style)

	vbox.add_child(buy_button)

func _create_gear_item(index: int, item: Item):
	var can_afford = SaveSystem.total_coins >= item.sell_value

	# Container
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(0, 110)

	# Color based on rarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = item.get_rarity_color()
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	item_container.add_theme_stylebox_override("panel", style)

	upgrades_container.add_child(item_container)

	# HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	item_container.add_child(hbox)

	# Icon with styled background
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(95, 95)
	hbox.add_child(icon_container)

	var icon_bg = PanelContainer.new()
	var icon_bg_style = StyleBoxFlat.new()
	icon_bg_style.bg_color = Color(0.25, 0.25, 0.3, 0.95)
	icon_bg_style.corner_radius_top_left = 10
	icon_bg_style.corner_radius_top_right = 10
	icon_bg_style.corner_radius_bottom_left = 10
	icon_bg_style.corner_radius_bottom_right = 10
	icon_bg_style.border_width_left = 3
	icon_bg_style.border_width_right = 3
	icon_bg_style.border_width_top = 3
	icon_bg_style.border_width_bottom = 3
	icon_bg_style.border_color = item.get_rarity_color()
	icon_bg.add_theme_stylebox_override("panel", icon_bg_style)
	icon_bg.custom_minimum_size = Vector2(85, 85)
	icon_container.add_child(icon_bg)

	var icon_label = Label.new()
	# Use text-based type indicators
	match item.item_type:
		Item.ItemType.WEAPON:
			icon_label.text = "W"
		Item.ItemType.HELMET:
			icon_label.text = "H"
		Item.ItemType.CHEST:
			icon_label.text = "C"
		Item.ItemType.GLOVES:
			icon_label.text = "G"
		Item.ItemType.LEGS:
			icon_label.text = "L"
		Item.ItemType.SHOES:
			icon_label.text = "S"
		Item.ItemType.RING:
			icon_label.text = "R"
		Item.ItemType.AMULET:
			icon_label.text = "A"
	icon_label.add_theme_font_size_override("font_size", 42)
	icon_label.add_theme_color_override("font_color", item.get_rarity_color())
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_bg.add_child(icon_label)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name with rarity
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [item.item_name, item.get_rarity_name()]
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	info_vbox.add_child(desc_label)

	# Stats
	var stats_text = get_item_stats_text(item)
	if stats_text != "":
		var stats_label = Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
		info_vbox.add_child(stats_label)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "%d\nCOINS" % item.sell_value
	buy_button.custom_minimum_size = Vector2(130, 90)
	buy_button.add_theme_font_size_override("font_size", 18)
	buy_button.disabled = not can_afford
	buy_button.pressed.connect(_on_buy_gear_pressed.bind(index))

	# Custom button style
	var button_style = StyleBoxFlat.new()
	if can_afford:
		button_style.bg_color = Color(0.8, 0.6, 0.1, 0.95)
		buy_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		button_style.bg_color = Color(0.3, 0.3, 0.3, 0.6)
		buy_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("normal", button_style)
	buy_button.add_theme_stylebox_override("hover", button_style)
	buy_button.add_theme_stylebox_override("pressed", button_style)

	hbox.add_child(buy_button)

func get_item_stats_text(item: Item) -> String:
	var stats = []

	if item.health_bonus > 0:
		stats.append("+%.0f HP" % item.health_bonus)
	if item.damage_bonus > 0:
		stats.append("+%.0f%% Damage" % (item.damage_bonus * 100))
	if item.speed_bonus > 0:
		stats.append("+%.0f Speed" % item.speed_bonus)
	if item.crit_chance_bonus > 0:
		stats.append("+%.1f%% Crit" % (item.crit_chance_bonus * 100))
	if item.crit_damage_bonus > 0:
		stats.append("+%.0f%% Crit Dmg" % (item.crit_damage_bonus * 100))
	if item.fire_rate_bonus > 0:
		stats.append("+%.0f%% Fire Rate" % (item.fire_rate_bonus * 100))
	if item.armor_bonus > 0:
		stats.append("+%.1f%% Armor" % (item.armor_bonus * 100))
	if item.cooldown_reduction_bonus > 0:
		stats.append("+%.1f%% CDR" % (item.cooldown_reduction_bonus * 100))
	if item.luck_bonus > 0:
		stats.append("+%.1f%% Luck" % (item.luck_bonus * 100))

	return " | ".join(stats)

func _on_buy_gear_pressed(index: int):
	var item = shop_gear_items[index]

	# Check if player can afford
	if SaveSystem.total_coins < item.sell_value:
		print("Not enough coins!")
		return

	# Check if player has inventory space
	# We need to access the player's equipment manager
	# Since we're in the shop (separate scene), we can't directly access it
	# Instead, we'll save the purchased item and add it when the player returns to game

	# For now, let's use a simple approach: save items to be added to SaveSystem
	if not SaveSystem.has("pending_gear_items"):
		SaveSystem.set_value("pending_gear_items", [])

	var pending_items = SaveSystem.get_value("pending_gear_items", [])
	pending_items.append(item.to_dict())  # Convert item to dictionary for serialization
	SaveSystem.set_value("pending_gear_items", pending_items)

	# Deduct coins
	SaveSystem.total_coins -= item.sell_value
	SaveSystem.save_data()

	print("Purchased: %s for %d coins" % [item.item_name, item.sell_value])

	# Remove from shop
	shop_gear_items.remove_at(index)

	# Refresh display
	populate_upgrades()
	update_coins_display()

func _on_back_pressed():
	# Go back to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
