extends CanvasLayer

@onready var back_button = $CenterContainer/PanelContainer/VBoxContainer/BackButton
@onready var coins_label = $CenterContainer/PanelContainer/VBoxContainer/Header/CoinsLabel
@onready var upgrades_container = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/UpgradesContainer

# Gear shop items (regenerated each time shop is opened)
var shop_gear_items: Array[Item] = []
var gear_shop_size: int = 6  # Number of gear items in shop

func _ready():
	# Connect back button
	back_button.pressed.connect(_on_back_pressed)

	# Generate shop gear items
	generate_shop_gear()

	# Update coins display
	update_coins_display()

	# Populate upgrades
	populate_upgrades()

func update_coins_display():
	coins_label.text = "💰 %d Coins" % SaveSystem.total_coins

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

	# Add gear shop first
	_create_gear_shop_section()

	# Group unlocks by category
	var categories = {
		"passive": [],
		"weapon": [],
		"meta": []
	}

	for unlock_id in SaveSystem.available_unlocks:
		var unlock = SaveSystem.available_unlocks[unlock_id]
		var category = unlock.get("category", "passive")
		categories[category].append({"id": unlock_id, "data": unlock})

	# Create category sections
	_create_category_section("⚡ PASSIVE UPGRADES", categories.passive)
	_create_category_section("🔫 WEAPONS", categories.weapon)
	_create_category_section("✨ META UPGRADES", categories.meta)

func _create_category_section(title: String, unlocks: Array):
	if unlocks.is_empty():
		return

	# Category title
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 2)
	upgrades_container.add_child(title_label)

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

	# Container
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(700, 80)
	upgrades_container.add_child(item_container)

	# HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	item_container.add_child(hbox)

	# Icon
	var icon_label = Label.new()
	icon_label.text = unlock_data.get("icon", "❓")
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label = Label.new()
	name_label.text = unlock_data.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1) if not is_unlocked else Color(0.5, 1, 0.5, 1))
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = unlock_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	info_vbox.add_child(desc_label)

	# Buy button or status
	if is_unlocked:
		var unlocked_label = Label.new()
		unlocked_label.text = "✓ UNLOCKED"
		unlocked_label.add_theme_font_size_override("font_size", 18)
		unlocked_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
		unlocked_label.custom_minimum_size = Vector2(150, 60)
		unlocked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlocked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(unlocked_label)
	elif not has_requirements:
		var locked_label = Label.new()
		locked_label.text = "🔒 LOCKED"
		locked_label.add_theme_font_size_override("font_size", 18)
		locked_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		locked_label.custom_minimum_size = Vector2(150, 60)
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(locked_label)
	else:
		var buy_button = Button.new()
		buy_button.text = "💰 %d" % unlock_data.cost
		buy_button.custom_minimum_size = Vector2(150, 60)
		buy_button.add_theme_font_size_override("font_size", 20)
		buy_button.disabled = not can_afford
		buy_button.pressed.connect(_on_buy_pressed.bind(unlock_id))

		if can_afford:
			buy_button.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		else:
			buy_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

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
	# Category title
	var title_label = Label.new()
	title_label.text = "⚔️ GEAR SHOP"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0.6, 0.1, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 2)
	upgrades_container.add_child(title_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Random gear items refresh each time you visit the shop!"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	upgrades_container.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	upgrades_container.add_child(spacer1)

	# Add each gear item
	for i in range(shop_gear_items.size()):
		_create_gear_item(i, shop_gear_items[i])

	# Category spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	upgrades_container.add_child(spacer2)

func _create_gear_item(index: int, item: Item):
	var can_afford = SaveSystem.total_coins >= item.sell_value

	# Container
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(700, 100)

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

	# Icon (gear type icon)
	var icon_label = Label.new()
	match item.item_type:
		Item.ItemType.WEAPON:
			icon_label.text = "⚔️"
		Item.ItemType.HELMET:
			icon_label.text = "🎩"
		Item.ItemType.CHEST:
			icon_label.text = "👔"
		Item.ItemType.GLOVES:
			icon_label.text = "🧤"
		Item.ItemType.LEGS:
			icon_label.text = "👖"
		Item.ItemType.SHOES:
			icon_label.text = "👞"
		Item.ItemType.RING:
			icon_label.text = "💍"
		Item.ItemType.AMULET:
			icon_label.text = "📿"
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name with rarity
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [item.item_name, item.get_rarity_name()]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	info_vbox.add_child(desc_label)

	# Stats
	var stats_text = get_item_stats_text(item)
	if stats_text != "":
		var stats_label = Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 11)
		stats_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6, 1))
		info_vbox.add_child(stats_label)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "💰 %d" % item.sell_value
	buy_button.custom_minimum_size = Vector2(120, 80)
	buy_button.add_theme_font_size_override("font_size", 20)
	buy_button.disabled = not can_afford
	buy_button.pressed.connect(_on_buy_gear_pressed.bind(index))

	if can_afford:
		buy_button.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
	else:
		buy_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

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
