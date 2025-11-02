extends Control

# UI References
@onready var close_button = $Panel/CloseButton
@onready var stats_container = $Panel/StatsPanel/StatsContainer
@onready var inventory_container = $Panel/InventoryPanel/InventoryContainer/InventoryScroll

# Equipment slot buttons (all 9 slots)
@onready var weapon_slot = $Panel/WeaponSlot
@onready var helmet_slot = $Panel/HelmetSlot
@onready var chest_slot = $Panel/ChestSlot
@onready var gloves_slot = $Panel/GlovesSlot
@onready var legs_slot = $Panel/LegsSlot
@onready var shoes_slot = $Panel/ShoesSlot
@onready var ring1_slot = $Panel/Ring1Slot
@onready var ring2_slot = $Panel/Ring2Slot
@onready var amulet_slot = $Panel/AmuletSlot

# Stats labels and progress bars
@onready var health_bar = $Panel/StatsPanel/StatsContainer/HealthRow/HealthBar
@onready var health_value = $Panel/StatsPanel/StatsContainer/HealthRow/HealthValue
@onready var damage_bar = $Panel/StatsPanel/StatsContainer/DamageRow/DamageBar
@onready var damage_value = $Panel/StatsPanel/StatsContainer/DamageRow/DamageValue
@onready var speed_bar = $Panel/StatsPanel/StatsContainer/SpeedRow/SpeedBar
@onready var speed_value = $Panel/StatsPanel/StatsContainer/SpeedRow/SpeedValue
@onready var crit_bar = $Panel/StatsPanel/StatsContainer/CritRow/CritBar
@onready var crit_value = $Panel/StatsPanel/StatsContainer/CritRow/CritValue
@onready var fire_rate_bar = $Panel/StatsPanel/StatsContainer/FireRateRow/FireRateBar
@onready var fire_rate_value = $Panel/StatsPanel/StatsContainer/FireRateRow/FireRateValue
@onready var armor_bar = $Panel/StatsPanel/StatsContainer/ArmorRow/ArmorBar
@onready var armor_value = $Panel/StatsPanel/StatsContainer/ArmorRow/ArmorValue
@onready var cooldown_bar = $Panel/StatsPanel/StatsContainer/CooldownRow/CooldownBar
@onready var cooldown_value = $Panel/StatsPanel/StatsContainer/CooldownRow/CooldownValue
@onready var luck_bar = $Panel/StatsPanel/StatsContainer/LuckRow/LuckBar
@onready var luck_value = $Panel/StatsPanel/StatsContainer/LuckRow/LuckValue

# Item info labels
@onready var item_name_label = $Panel/ItemInfoPanel/ItemInfoContainer/ItemName
@onready var item_description_label = $Panel/ItemInfoPanel/ItemInfoContainer/ItemDescription
@onready var item_stats_label = $Panel/ItemInfoPanel/ItemInfoContainer/ItemStats
@onready var action_button = $Panel/ItemInfoPanel/ItemInfoContainer/ActionButton
@onready var item_info_container = $Panel/ItemInfoPanel/ItemInfoContainer

# Reference to player's equipment manager
var equipment_manager: EquipmentManager = null
var player_reference: Node = null  # Direct player reference

# Dynamic comparison nodes
var comparison_container: VBoxContainer = null
var equipped_item_box: HBoxContainer = null
var new_item_box: HBoxContainer = null

# Currently selected item for display
var selected_item: Item = null
var selected_from_inventory: bool = false

# Inventory buttons (created dynamically)
var inventory_buttons: Array[Button] = []

# Character preview sprite and weapon
var character_sprite: Sprite2D = null
var equipped_weapon_sprite: Sprite2D = null

# Inventory filtering
enum InventoryFilter { ALL, WEAPONS, ARMOR, ACCESSORIES }
var current_filter: InventoryFilter = InventoryFilter.ALL

# Tab buttons
var tab_all: Button = null
var tab_weapons: Button = null
var tab_armor: Button = null
var tab_accessories: Button = null

func set_player(player: Node):
	"""Set player reference before adding to tree"""
	player_reference = player
	print("set_player() called with player reference")

func _ready():
	print("Character screen _ready() called")

	# Setup character preview sprite
	setup_character_preview()

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	else:
		print("WARNING: close_button not found!")

	# Connect action button
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)

	# Get player's equipment manager (use direct reference if available)
	# Check if equipment_manager is already set (from main menu)
	if not equipment_manager:
		var player = player_reference if player_reference else get_tree().get_first_node_in_group("player")

		if player and player.equipment_manager:
			equipment_manager = player.equipment_manager
			equipment_manager.equipment_changed.connect(update_display)
			equipment_manager.inventory_changed.connect(update_inventory_display)

			# Load any pending gear items from shop purchases
			load_pending_gear_items()

			print("Equipment manager connected from player! Inventory size: %d" % equipment_manager.inventory.size())
		else:
			print("ERROR: Could not find player or equipment_manager!")
			if not player:
				print("  -> player is null")
			elif not player.equipment_manager:
				print("  -> equipment_manager is null")
	else:
		# Equipment manager was pre-set (from main menu)
		print("Equipment manager already set! Inventory size: %d" % equipment_manager.inventory.size())

		# Still connect signals (they always exist on EquipmentManager)
		equipment_manager.equipment_changed.connect(update_display)
		equipment_manager.inventory_changed.connect(update_inventory_display)
		print("Signals connected to pre-set equipment manager")

	# Connect equipment slot buttons
	if weapon_slot:
		weapon_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.WEAPON))
	if helmet_slot:
		helmet_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.HELMET))
	if chest_slot:
		chest_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.CHEST))
	if gloves_slot:
		gloves_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.GLOVES))
	if legs_slot:
		legs_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.LEGS))
	if shoes_slot:
		shoes_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.SHOES))
	if ring1_slot:
		ring1_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.RING, 1))
	if ring2_slot:
		ring2_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.RING, 2))
	if amulet_slot:
		amulet_slot.pressed.connect(func(): _on_equipment_slot_pressed(Item.ItemType.AMULET))

	# Create inventory tabs
	create_inventory_tabs()

	# Create inventory grid
	if inventory_container:
		print("Creating inventory grid...")
		create_inventory_grid()
		print("Inventory grid created with %d buttons" % inventory_buttons.size())
	else:
		print("ERROR: inventory_container not found!")

	# Initial display update
	update_display()
	update_inventory_display()

	# Force weapon preview update (in case weapon is already equipped)
	await get_tree().process_frame
	update_character_weapon_preview()

	print("Character screen ready complete!")

func setup_character_preview():
	"""Setup the Wizard character preview sprite without staff"""
	if has_node("Panel/CharacterSprite"):
		character_sprite = get_node("Panel/CharacterSprite")

		# Change to WizardNoStaffGodot texture
		var wizard_no_staff_texture = load("res://Wizard/WizardNoStaffGodot.png")
		if wizard_no_staff_texture:
			character_sprite.texture = wizard_no_staff_texture
			print("✅ Loaded WizardNoStaffGodot for character preview")
		else:
			print("❌ Failed to load WizardNoStaffGodot.png")

		# Create equipped weapon sprite as child
		equipped_weapon_sprite = Sprite2D.new()
		equipped_weapon_sprite.name = "EquippedWeaponPreview"
		equipped_weapon_sprite.visible = false
		equipped_weapon_sprite.z_index = 1  # IN FRONT of wizard so we can see it!
		character_sprite.add_child(equipped_weapon_sprite)
		print("✅ Created equipped weapon preview sprite")
	else:
		print("❌ CharacterSprite not found in scene!")

func update_character_weapon_preview():
	"""Update the weapon shown on character preview"""
	print("update_character_weapon_preview() called")

	if not equipment_manager:
		print("  -> No equipment_manager")
		return

	if not equipped_weapon_sprite:
		print("  -> No equipped_weapon_sprite")
		return

	var weapon = equipment_manager.equipped_weapon
	print("  -> Equipped weapon: %s" % (weapon.item_name if weapon else "None"))

	if weapon and weapon.icon_path and weapon.icon_path != "":
		print("  -> Icon path: %s" % weapon.icon_path)
		# Load staff texture
		var staff_texture = load(weapon.icon_path)
		if staff_texture:
			equipped_weapon_sprite.texture = staff_texture
			equipped_weapon_sprite.visible = true

			# Scale staff relative to character
			# Parent sprite (wizard) is 1024x1024 pixels at 0.12 world scale
			# Staff should be visible and in wizard's hand
			equipped_weapon_sprite.scale = Vector2(0.8, 0.8)  # Bigger so we can see it!

			# Position staff in wizard's right hand (in local coordinates relative to 1024px wizard sprite)
			# Wizard is facing right, so staff goes on right side
			equipped_weapon_sprite.position = Vector2(400, 100)  # Adjust to hand position
			equipped_weapon_sprite.rotation_degrees = 45  # Angle it like wizard is holding it

			print("✅ Staff preview updated: %s (visible: %s, z_index: %d)" % [weapon.item_name, equipped_weapon_sprite.visible, equipped_weapon_sprite.z_index])
		else:
			print("❌ Failed to load staff texture: %s" % weapon.icon_path)
			equipped_weapon_sprite.visible = false
	else:
		# No weapon equipped, hide sprite
		equipped_weapon_sprite.visible = false
		print("No weapon equipped - hiding staff preview")

func create_inventory_tabs():
	"""Create filter tabs above inventory"""
	if not has_node("Panel/InventoryPanel/InventoryContainer"):
		return

	var container = get_node("Panel/InventoryPanel/InventoryContainer")

	# Create tab container
	var tab_container = HBoxContainer.new()
	tab_container.name = "TabContainer"
	tab_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.add_child(tab_container)
	container.move_child(tab_container, 0)  # Move to top

	# Tab style
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.3, 0.25, 0.15, 1)
	active_style.border_width_bottom = 3
	active_style.border_color = Color(1, 0.8, 0.3, 1)

	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)

	# Create tabs
	tab_all = Button.new()
	tab_all.text = "All"
	tab_all.custom_minimum_size = Vector2(80, 35)
	tab_all.pressed.connect(func(): _on_tab_pressed(InventoryFilter.ALL))
	tab_container.add_child(tab_all)

	tab_weapons = Button.new()
	tab_weapons.text = "Weapons"
	tab_weapons.custom_minimum_size = Vector2(100, 35)
	tab_weapons.pressed.connect(func(): _on_tab_pressed(InventoryFilter.WEAPONS))
	tab_container.add_child(tab_weapons)

	tab_armor = Button.new()
	tab_armor.text = "Armor"
	tab_armor.custom_minimum_size = Vector2(80, 35)
	tab_armor.pressed.connect(func(): _on_tab_pressed(InventoryFilter.ARMOR))
	tab_container.add_child(tab_armor)

	tab_accessories = Button.new()
	tab_accessories.text = "Accessories"
	tab_accessories.custom_minimum_size = Vector2(120, 35)
	tab_accessories.pressed.connect(func(): _on_tab_pressed(InventoryFilter.ACCESSORIES))
	tab_container.add_child(tab_accessories)

	# Set initial active tab
	update_tab_styles()

func _on_tab_pressed(filter: InventoryFilter):
	current_filter = filter
	update_tab_styles()
	update_inventory_display()
	print("Filter changed to: %s" % ["All", "Weapons", "Armor", "Accessories"][filter])

func update_tab_styles():
	"""Update tab button styles based on active filter"""
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.3, 0.25, 0.15, 1)
	active_style.border_width_bottom = 3
	active_style.border_color = Color(1, 0.8, 0.3, 1)

	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)

	if tab_all:
		tab_all.add_theme_stylebox_override("normal", active_style if current_filter == InventoryFilter.ALL else inactive_style)
	if tab_weapons:
		tab_weapons.add_theme_stylebox_override("normal", active_style if current_filter == InventoryFilter.WEAPONS else inactive_style)
	if tab_armor:
		tab_armor.add_theme_stylebox_override("normal", active_style if current_filter == InventoryFilter.ARMOR else inactive_style)
	if tab_accessories:
		tab_accessories.add_theme_stylebox_override("normal", active_style if current_filter == InventoryFilter.ACCESSORIES else inactive_style)

func get_filtered_inventory() -> Array[Item]:
	"""Get inventory items based on current filter"""
	if not equipment_manager:
		return []

	var filtered: Array[Item] = []

	for item in equipment_manager.inventory:
		var should_show = false

		match current_filter:
			InventoryFilter.ALL:
				should_show = true
			InventoryFilter.WEAPONS:
				should_show = item.item_type == Item.ItemType.WEAPON
			InventoryFilter.ARMOR:
				should_show = item.item_type in [Item.ItemType.HELMET, Item.ItemType.CHEST, Item.ItemType.GLOVES, Item.ItemType.LEGS, Item.ItemType.SHOES]
			InventoryFilter.ACCESSORIES:
				should_show = item.item_type in [Item.ItemType.RING, Item.ItemType.AMULET]

		if should_show:
			filtered.append(item)

	return filtered

func create_inventory_grid():
	if not inventory_container:
		return

	# Create a grid of buttons for inventory (8x6 = 48 slots, scrollable)
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	inventory_container.add_child(grid)

	# Create StyleBoxFlat for inventory slots
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = Color(0.4, 0.35, 0.25, 1)
	slot_style.corner_radius_top_left = 4
	slot_style.corner_radius_top_right = 4
	slot_style.corner_radius_bottom_right = 4
	slot_style.corner_radius_bottom_left = 4

	for i in range(48):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = ""
		btn.add_theme_stylebox_override("normal", slot_style)
		btn.add_theme_stylebox_override("hover", slot_style)
		btn.add_theme_stylebox_override("pressed", slot_style)
		btn.pressed.connect(func(): _on_inventory_slot_pressed(i))
		grid.add_child(btn)
		inventory_buttons.append(btn)

func update_display():
	if not equipment_manager:
		return

	# Update character preview with equipped weapon
	update_character_weapon_preview()

	# Update equipment slots
	update_equipment_slot(weapon_slot, equipment_manager.equipped_weapon)
	update_equipment_slot(helmet_slot, equipment_manager.equipped_helmet)
	update_equipment_slot(chest_slot, equipment_manager.equipped_chest)
	update_equipment_slot(gloves_slot, equipment_manager.equipped_gloves)
	update_equipment_slot(legs_slot, equipment_manager.equipped_legs)
	update_equipment_slot(shoes_slot, equipment_manager.equipped_shoes)
	update_equipment_slot(ring1_slot, equipment_manager.equipped_ring1)
	update_equipment_slot(ring2_slot, equipment_manager.equipped_ring2)
	update_equipment_slot(amulet_slot, equipment_manager.equipped_amulet)

	# Update stats display
	update_stats_display()

func update_equipment_slot(slot_button: Button, item: Item):
	if not slot_button:
		return

	if item:
		# Try to load and display icon if available
		if item.icon_path and item.icon_path != "":
			var texture = load(item.icon_path)
			if texture:
				slot_button.icon = texture
				slot_button.text = ""  # Clear text when showing icon
				slot_button.expand_icon = true
			else:
				# Fallback to text if icon fails to load
				slot_button.icon = null
				slot_button.text = item.item_name
		else:
			# No icon path, use text
			slot_button.icon = null
			slot_button.text = item.item_name

		slot_button.modulate = Color(1, 1, 1, 1)  # White modulate so colors show properly

		# Create border with rarity color
		var border_style = StyleBoxFlat.new()
		border_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
		border_style.border_width_left = 4
		border_style.border_width_top = 4
		border_style.border_width_right = 4
		border_style.border_width_bottom = 4
		border_style.border_color = item.get_rarity_color()
		border_style.corner_radius_top_left = 6
		border_style.corner_radius_top_right = 6
		border_style.corner_radius_bottom_right = 6
		border_style.corner_radius_bottom_left = 6
		border_style.shadow_size = 4
		border_style.shadow_offset = Vector2(0, 2)

		slot_button.add_theme_stylebox_override("normal", border_style)
		slot_button.add_theme_stylebox_override("hover", border_style)
		slot_button.add_theme_stylebox_override("pressed", border_style)
	else:
		# Clear any icon from previous item
		slot_button.icon = null

		# Restore original Unicode symbols from scene
		var original_text = ""
		if slot_button == weapon_slot:
			original_text = "⚔"
		elif slot_button == helmet_slot:
			original_text = "⛑"
		elif slot_button == chest_slot:
			original_text = "◈"
		elif slot_button == gloves_slot:
			original_text = "✊"
		elif slot_button == legs_slot:
			original_text = "▼"
		elif slot_button == shoes_slot:
			original_text = "▲"
		elif slot_button == ring1_slot:
			original_text = "◯"
		elif slot_button == ring2_slot:
			original_text = "◯"
		elif slot_button == amulet_slot:
			original_text = "◆"

		slot_button.text = original_text
		slot_button.modulate = Color(0.5, 0.5, 0.5, 1)

		# Restore original empty slot style
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
		empty_style.border_width_left = 3
		empty_style.border_width_top = 3
		empty_style.border_width_right = 3
		empty_style.border_width_bottom = 3
		empty_style.border_color = Color(0.5, 0.4, 0.25, 1)
		empty_style.corner_radius_top_left = 6
		empty_style.corner_radius_top_right = 6
		empty_style.corner_radius_bottom_right = 6
		empty_style.corner_radius_bottom_left = 6
		empty_style.shadow_size = 4
		empty_style.shadow_offset = Vector2(0, 2)

		slot_button.add_theme_stylebox_override("normal", empty_style)
		slot_button.add_theme_stylebox_override("hover", empty_style)
		slot_button.add_theme_stylebox_override("pressed", empty_style)

func update_stats_display():
	if not equipment_manager:
		return

	var player = player_reference if player_reference else get_tree().get_first_node_in_group("player")

	# Get total equipment bonuses
	var stats = equipment_manager.get_total_stats()

	# If we have a player, show real stats
	if player:
		# Update health
		if health_bar and health_value:
			health_bar.max_value = player.max_health
			health_bar.value = player.current_health
			health_value.text = "%.0f / %.0f" % [player.current_health, player.max_health]

		# Update damage
		if damage_bar and damage_value:
			var damage_mult = (1.0 + player.passive_damage_boost) * 100
			damage_bar.value = damage_mult
			damage_value.text = "%.0f%%" % damage_mult

		# Update speed
		if speed_bar and speed_value:
			speed_bar.value = player.move_speed
			speed_value.text = "%.0f" % player.move_speed

		# Update crit
		if crit_bar and crit_value:
			crit_bar.value = player.crit_chance * 100
			crit_value.text = "%.1f%% (x%.1f)" % [player.crit_chance * 100, player.crit_multiplier]
	else:
		# No player (main menu) - show base stats from equipment only
		if health_bar and health_value:
			health_bar.max_value = 100 + stats.health_bonus
			health_bar.value = 100 + stats.health_bonus
			health_value.text = "%.0f / %.0f" % [100 + stats.health_bonus, 100 + stats.health_bonus]

		# Update damage from equipment
		if damage_bar and damage_value:
			var damage_mult = (1.0 + stats.damage_bonus) * 100
			damage_bar.value = damage_mult
			damage_value.text = "%.0f%%" % damage_mult

		# Update speed from equipment
		if speed_bar and speed_value:
			speed_bar.value = 200 + stats.speed_bonus
			speed_value.text = "%.0f" % (200 + stats.speed_bonus)

		# Update crit from equipment
		if crit_bar and crit_value:
			crit_bar.value = stats.crit_chance_bonus * 100
			crit_value.text = "%.1f%%" % (stats.crit_chance_bonus * 100)

	# Update fire rate (same for both)
	if fire_rate_bar and fire_rate_value:
		var fire_rate_percent = (1.0 + stats.fire_rate_bonus) * 100
		fire_rate_bar.value = fire_rate_percent
		fire_rate_value.text = "%.0f%%" % fire_rate_percent

	# Update armor (same for both)
	if armor_bar and armor_value:
		var armor_percent = stats.armor_bonus * 100
		armor_bar.value = armor_percent
		armor_value.text = "%.0f%%" % armor_percent

	# Update cooldown reduction (same for both)
	if cooldown_bar and cooldown_value:
		var cooldown_percent = stats.cooldown_reduction_bonus * 100
		cooldown_bar.value = cooldown_percent
		cooldown_value.text = "%.0f%%" % cooldown_percent

	# Update luck (same for both)
	if luck_bar and luck_value:
		var luck_percent = stats.luck_bonus * 100
		luck_bar.value = luck_percent
		luck_value.text = "%.0f%%" % luck_percent

func update_inventory_display():
	if not equipment_manager:
		print("update_inventory_display: No equipment_manager!")
		return

	# Get filtered items based on current tab
	var filtered_items = get_filtered_inventory()
	print("Updating inventory display... Filtered items: %d, Buttons: %d" % [filtered_items.size(), inventory_buttons.size()])

	# Update inventory slots
	for i in range(inventory_buttons.size()):
		var btn = inventory_buttons[i]
		if i < filtered_items.size():
			var item = filtered_items[i]
			print("Slot %d: %s (icon: %s)" % [i, item.item_name, item.icon_path])

			# Try to load and display icon if available
			if item.icon_path and item.icon_path != "":
				var texture = load(item.icon_path)
				if texture:
					btn.icon = texture
					btn.text = ""  # Clear text when showing icon
					btn.expand_icon = true
					btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
					print("  -> Loaded icon successfully")
				else:
					# Fallback to truncated text if icon fails to load
					btn.icon = null
					btn.text = item.item_name.substr(0, 8)
					print("  -> Failed to load icon, using text")
			else:
				# No icon path, use truncated text
				btn.icon = null
				btn.text = item.item_name.substr(0, 8)
				print("  -> No icon path, using text")

			# Create border with rarity color
			var border_style = StyleBoxFlat.new()
			border_style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
			border_style.border_width_left = 3
			border_style.border_width_top = 3
			border_style.border_width_right = 3
			border_style.border_width_bottom = 3
			border_style.border_color = item.get_rarity_color()
			border_style.corner_radius_top_left = 4
			border_style.corner_radius_top_right = 4
			border_style.corner_radius_bottom_right = 4
			border_style.corner_radius_bottom_left = 4

			btn.add_theme_stylebox_override("normal", border_style)
			btn.add_theme_stylebox_override("hover", border_style)
			btn.add_theme_stylebox_override("pressed", border_style)
			btn.modulate = Color(1, 1, 1, 1)  # White to show icons properly
			btn.tooltip_text = "%s\n%s\n%s" % [item.item_name, item.get_rarity_name(), item.description]
		else:
			# Empty slot
			btn.icon = null
			btn.text = ""
			btn.modulate = Color(0.3, 0.3, 0.3, 1)
			btn.tooltip_text = ""

			# Reset to default empty style
			var empty_style = StyleBoxFlat.new()
			empty_style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
			empty_style.border_width_left = 2
			empty_style.border_width_top = 2
			empty_style.border_width_right = 2
			empty_style.border_width_bottom = 2
			empty_style.border_color = Color(0.4, 0.35, 0.25, 1)
			empty_style.corner_radius_top_left = 4
			empty_style.corner_radius_top_right = 4
			empty_style.corner_radius_bottom_right = 4
			empty_style.corner_radius_bottom_left = 4

			btn.add_theme_stylebox_override("normal", empty_style)
			btn.add_theme_stylebox_override("hover", empty_style)
			btn.add_theme_stylebox_override("pressed", empty_style)

	print("Inventory display update complete!")

func _on_equipment_slot_pressed(slot_type: Item.ItemType, ring_slot: int = 1):
	if not equipment_manager:
		return

	# Get the item in this slot to show info
	var item: Item = null
	match slot_type:
		Item.ItemType.WEAPON:
			item = equipment_manager.equipped_weapon
		Item.ItemType.HELMET:
			item = equipment_manager.equipped_helmet
		Item.ItemType.CHEST:
			item = equipment_manager.equipped_chest
		Item.ItemType.GLOVES:
			item = equipment_manager.equipped_gloves
		Item.ItemType.LEGS:
			item = equipment_manager.equipped_legs
		Item.ItemType.SHOES:
			item = equipment_manager.equipped_shoes
		Item.ItemType.RING:
			if ring_slot == 1:
				item = equipment_manager.equipped_ring1
			else:
				item = equipment_manager.equipped_ring2
		Item.ItemType.AMULET:
			item = equipment_manager.equipped_amulet

	if item:
		# Show item info (from equipment slot)
		show_item_info(item, false)
	else:
		# Slot is empty, show that
		clear_item_info()

func _on_inventory_slot_pressed(slot_index: int):
	if not equipment_manager:
		return

	# Get filtered items based on current tab
	var filtered_items = get_filtered_inventory()

	if slot_index >= filtered_items.size():
		clear_item_info()
		return

	var item = filtered_items[slot_index]

	# Show item info
	show_item_info(item)

func load_pending_gear_items():
	if not equipment_manager:
		return

	# Check if there are any pending gear items from shop purchases
	if SaveSystem.has("pending_gear_items"):
		var pending_items = SaveSystem.get_value("pending_gear_items", [])

		for item_data in pending_items:
			# Recreate Item from dictionary
			var item = Item.from_dict(item_data)

			# Add to inventory
			if equipment_manager.add_to_inventory(item):
				print("Added pending shop item to inventory: %s" % item.item_name)
			else:
				print("Inventory full, couldn't add: %s" % item.item_name)

		# Clear pending items
		SaveSystem.set_value("pending_gear_items", [])
		SaveSystem.save_data()

func show_item_info(item: Item, from_inventory: bool = true):
	if not item:
		clear_item_info()
		return

	selected_item = item
	selected_from_inventory = from_inventory

	# Set title
	if item_name_label:
		item_name_label.text = "⚖️ ITEM COMPARISON"

	# Hide description label (we'll use custom layout)
	if item_description_label:
		item_description_label.visible = false

	# Build visual comparison
	var stats_text = ""

	# If selecting from inventory, compare with equipped item
	if from_inventory and equipment_manager:
		var equipped_item: Item = null
		match item.item_type:
			Item.ItemType.WEAPON:
				equipped_item = equipment_manager.equipped_weapon
			Item.ItemType.HELMET:
				equipped_item = equipment_manager.equipped_helmet
			Item.ItemType.CHEST:
				equipped_item = equipment_manager.equipped_chest
			Item.ItemType.GLOVES:
				equipped_item = equipment_manager.equipped_gloves
			Item.ItemType.LEGS:
				equipped_item = equipment_manager.equipped_legs
			Item.ItemType.SHOES:
				equipped_item = equipment_manager.equipped_shoes
			Item.ItemType.RING:
				# For rings, just compare with ring1 for simplicity
				equipped_item = equipment_manager.equipped_ring1
			Item.ItemType.AMULET:
				equipped_item = equipment_manager.equipped_amulet

		# Visual comparison layout
		if equipped_item:
			stats_text += build_visual_comparison(equipped_item, item)
		else:
			# No item equipped - just show the new item
			stats_text += "[center][color=#FFD700]⚠️ NO ITEM EQUIPPED IN THIS SLOT[/color][/center]\n\n"
			stats_text += "[center][b][color=%s]%s[/color][/b][/center]\n" % [item.get_rarity_color().to_html(), item.item_name]
			stats_text += "[center][color=#888888](%s)[/color][/center]\n\n" % item.get_rarity_name()
			stats_text += get_item_stats_text(item)
	else:
		# Just show equipped item stats (no comparison)
		stats_text += "[center][b][color=%s]%s[/color][/b][/center]\n" % [item.get_rarity_color().to_html(), item.item_name]
		stats_text += "[center][color=#888888](%s)[/color][/center]\n\n" % item.get_rarity_name()
		stats_text += get_item_stats_text(item)

	if item_stats_label:
		item_stats_label.text = stats_text if stats_text != "" else "No stat bonuses"

	# Show action button
	if action_button:
		action_button.visible = true
		if from_inventory:
			action_button.text = "⚡ EQUIP"
		else:
			action_button.text = "📤 UNEQUIP"

func build_visual_comparison(equipped: Item, new: Item) -> String:
	"""Builds a visual comparison with item images"""
	var text = ""

	# Clear any old comparison containers
	clear_comparison_nodes()

	# Create main comparison container (if not exists)
	if not comparison_container:
		comparison_container = VBoxContainer.new()
		comparison_container.name = "ComparisonContainer"
		comparison_container.add_theme_constant_override("separation", 20)  # More vertical spacing
		# Insert after ItemName but before ItemStats
		var insert_index = item_name_label.get_index() + 1
		item_info_container.add_child(comparison_container)
		item_info_container.move_child(comparison_container, insert_index)

	# === EQUIPPED ITEM BOX ===
	var equipped_box = create_item_comparison_box(equipped, true)
	comparison_container.add_child(equipped_box)

	# === ARROW SEPARATOR ===
	var arrow_container = VBoxContainer.new()
	arrow_container.add_theme_constant_override("separation", 5)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 10)
	arrow_container.add_child(spacer_top)

	var arrow_label = Label.new()
	arrow_label.text = "⬇ ⬇ ⬇"
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.add_theme_font_size_override("font_size", 28)
	arrow_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	arrow_container.add_child(arrow_label)

	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 10)
	arrow_container.add_child(spacer_bottom)

	comparison_container.add_child(arrow_container)

	# === NEW ITEM BOX ===
	var new_box = create_item_comparison_box(new, false, equipped)
	comparison_container.add_child(new_box)

	# Hide the regular stats label since we're using custom layout
	if item_stats_label:
		item_stats_label.visible = false

	return ""  # Return empty since we're building nodes, not text

func create_item_comparison_box(item: Item, is_equipped: bool, compare_to: Item = null) -> PanelContainer:
	"""Creates a visual box with item icon + stats"""
	var panel = PanelContainer.new()

	# Style the panel with more padding
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 0.85, 0.4) if is_equipped else Color(0, 1, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	# Add more padding inside the box
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	# Main HBox (icon on left, stats on right)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)  # More space between icon and stats
	panel.add_child(hbox)

	# === LEFT: Item Icon ===
	var icon_container = VBoxContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	hbox.add_child(icon_container)

	# Title label
	var title_label = Label.new()
	title_label.text = "EQUIPPED" if is_equipped else "NEW ITEM"
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_container.add_child(title_label)

	# Item icon (TextureRect)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Load item texture based on type
	var texture = get_item_texture(item)
	if texture:
		icon.texture = texture
	icon_container.add_child(icon)

	# === RIGHT: Stats ===
	var stats_container = VBoxContainer.new()
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 8)  # Space between elements
	hbox.add_child(stats_container)

	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_container.add_child(name_label)

	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = item.get_rarity_name()
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_container.add_child(rarity_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	stats_container.add_child(spacer)

	# Stats (with color coding if comparing)
	var stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.custom_minimum_size = Vector2(250, 120)  # More space for stats
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if compare_to:
		stats_label.text = get_item_stats_text_with_diff(item, compare_to)
	else:
		stats_label.text = get_item_stats_text_compact(item)

	stats_container.add_child(stats_label)

	return panel

func get_item_texture(item: Item) -> Texture2D:
	"""Gets the texture for an item based on its type"""
	var path = ""

	# For weapons (staffs), use the staff sprites
	if item.item_type == Item.ItemType.WEAPON:
		# Try to match item name to staff texture
		if "Nature" in item.item_name:
			path = "res://Staffs/Staff2Godot.png"
		elif "Lightning" in item.item_name or "Embers" in item.item_name:
			path = "res://Staffs/Staff1Godot.png"
		elif "Archmage" in item.item_name:
			path = "res://Staffs/Staff3Godot.png"
		elif "Cosmic" in item.item_name:
			path = "res://Staffs/Staff4Godot.png"
		elif "Fire" in item.item_name:
			path = "res://Staffs/Staff5Godot.png"
		elif "Ice" in item.item_name:
			path = "res://Staffs/Staff6Godot.png"
		elif "Shadow" in item.item_name:
			path = "res://Staffs/Staff7Godot.png"
		else:
			path = "res://Staffs/Staff1Godot.png"  # Default staff

	# For other items, use placeholder for now
	elif item.item_type == Item.ItemType.HELMET:
		path = "res://Items/HelmetGodot.png"
	elif item.item_type == Item.ItemType.GLOVES:
		path = "res://Items/GlovesGodot.png"
	elif item.item_type == Item.ItemType.RING:
		path = "res://Items/RingGodot.png"
	elif item.item_type == Item.ItemType.SHOES:
		path = "res://Items/BootsGodot.png"

	if path != "" and ResourceLoader.exists(path):
		return load(path)

	return null

func clear_comparison_nodes():
	"""Remove old comparison nodes"""
	if comparison_container:
		comparison_container.queue_free()
		comparison_container = null

func get_item_stats_text_compact(item: Item) -> String:
	"""Compact stat display without colors"""
	var text = ""
	if item.health_bonus > 0:
		text += "   [HP] +%.0f\n" % item.health_bonus
	if item.damage_bonus > 0:
		text += "   [DMG] +%.1f%%\n" % (item.damage_bonus * 100)
	if item.speed_bonus > 0:
		text += "   [SPD] +%.0f\n" % item.speed_bonus
	if item.crit_chance_bonus > 0:
		text += "   [CRIT] +%.1f%%\n" % (item.crit_chance_bonus * 100)
	if item.crit_damage_bonus > 0:
		text += "   [CRIT DMG] +%.1f%%\n" % (item.crit_damage_bonus * 100)
	if item.fire_rate_bonus > 0:
		text += "   [FIRE RATE] +%.1f%%\n" % (item.fire_rate_bonus * 100)
	if item.armor_bonus > 0:
		text += "   [ARMOR] +%.1f%%\n" % (item.armor_bonus * 100)
	if item.cooldown_reduction_bonus > 0:
		text += "   [CDR] +%.1f%%\n" % (item.cooldown_reduction_bonus * 100)
	if item.luck_bonus > 0:
		text += "   [LUCK] +%.1f%%\n" % (item.luck_bonus * 100)
	return text

func get_item_stats_text_with_diff(new_item: Item, old_item: Item) -> String:
	"""Shows stats with color coding based on comparison"""
	var text = ""

	# Helper to get color
	var get_color = func(new_val: float, old_val: float) -> String:
		if new_val > old_val:
			return "#00FF00"  # Green = better
		elif new_val < old_val:
			return "#FF0000"  # Red = worse
		else:
			return "#FFFFFF"  # White = same

	if new_item.health_bonus > 0 or old_item.health_bonus > 0:
		var color = get_color.call(new_item.health_bonus, old_item.health_bonus)
		text += "   [color=%s][HP] +%.0f[/color]\n" % [color, new_item.health_bonus]

	if new_item.damage_bonus > 0 or old_item.damage_bonus > 0:
		var color = get_color.call(new_item.damage_bonus, old_item.damage_bonus)
		text += "   [color=%s][DMG] +%.1f%%[/color]\n" % [color, new_item.damage_bonus * 100]

	if new_item.speed_bonus > 0 or old_item.speed_bonus > 0:
		var color = get_color.call(new_item.speed_bonus, old_item.speed_bonus)
		text += "   [color=%s][SPD] +%.0f[/color]\n" % [color, new_item.speed_bonus]

	if new_item.crit_chance_bonus > 0 or old_item.crit_chance_bonus > 0:
		var color = get_color.call(new_item.crit_chance_bonus, old_item.crit_chance_bonus)
		text += "   [color=%s][CRIT] +%.1f%%[/color]\n" % [color, new_item.crit_chance_bonus * 100]

	if new_item.crit_damage_bonus > 0 or old_item.crit_damage_bonus > 0:
		var color = get_color.call(new_item.crit_damage_bonus, old_item.crit_damage_bonus)
		text += "   [color=%s][CRIT DMG] +%.1f%%[/color]\n" % [color, new_item.crit_damage_bonus * 100]

	if new_item.fire_rate_bonus > 0 or old_item.fire_rate_bonus > 0:
		var color = get_color.call(new_item.fire_rate_bonus, old_item.fire_rate_bonus)
		text += "   [color=%s][FIRE RATE] +%.1f%%[/color]\n" % [color, new_item.fire_rate_bonus * 100]

	if new_item.armor_bonus > 0 or old_item.armor_bonus > 0:
		var color = get_color.call(new_item.armor_bonus, old_item.armor_bonus)
		text += "   [color=%s][ARMOR] +%.1f%%[/color]\n" % [color, new_item.armor_bonus * 100]

	if new_item.cooldown_reduction_bonus > 0 or old_item.cooldown_reduction_bonus > 0:
		var color = get_color.call(new_item.cooldown_reduction_bonus, old_item.cooldown_reduction_bonus)
		text += "   [color=%s][CDR] +%.1f%%[/color]\n" % [color, new_item.cooldown_reduction_bonus * 100]

	if new_item.luck_bonus > 0 or old_item.luck_bonus > 0:
		var color = get_color.call(new_item.luck_bonus, old_item.luck_bonus)
		text += "   [color=%s][LUCK] +%.1f%%[/color]\n" % [color, new_item.luck_bonus * 100]

	return text

func get_item_stats_text(item: Item) -> String:
	var text = ""
	if item.health_bonus > 0:
		text += "[HP] +%.0f\n" % item.health_bonus
	if item.damage_bonus > 0:
		text += "[DMG] +%.1f%%\n" % (item.damage_bonus * 100)
	if item.speed_bonus > 0:
		text += "[SPD] +%.0f\n" % item.speed_bonus
	if item.crit_chance_bonus > 0:
		text += "[CRIT] +%.1f%%\n" % (item.crit_chance_bonus * 100)
	if item.crit_damage_bonus > 0:
		text += "[CRIT DMG] +%.1f%%\n" % (item.crit_damage_bonus * 100)
	if item.fire_rate_bonus > 0:
		text += "[FIRE RATE] +%.1f%%\n" % (item.fire_rate_bonus * 100)
	if item.armor_bonus > 0:
		text += "[ARMOR] +%.1f%%\n" % (item.armor_bonus * 100)
	if item.cooldown_reduction_bonus > 0:
		text += "[CDR] +%.1f%%\n" % (item.cooldown_reduction_bonus * 100)
	if item.luck_bonus > 0:
		text += "[LUCK] +%.1f%%\n" % (item.luck_bonus * 100)
	return text

func get_stat_difference_summary(new_item: Item, old_item: Item) -> String:
	"""Shows only the differences between two items in a clear format"""
	var text = ""
	var has_any_difference = false

	# Health difference
	var health_diff = new_item.health_bonus - old_item.health_bonus
	if health_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if health_diff > 0 else "#FF0000"
		var sign = "+" if health_diff > 0 else ""
		text += "[color=%s][HP] %s%.0f[/color]\n" % [color, sign, health_diff]

	# Damage difference
	var damage_diff = new_item.damage_bonus - old_item.damage_bonus
	if damage_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if damage_diff > 0 else "#FF0000"
		var sign = "+" if damage_diff > 0 else ""
		text += "[color=%s][DMG] %s%.1f%%[/color]\n" % [color, sign, damage_diff * 100]

	# Speed difference
	var speed_diff = new_item.speed_bonus - old_item.speed_bonus
	if speed_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if speed_diff > 0 else "#FF0000"
		var sign = "+" if speed_diff > 0 else ""
		text += "[color=%s][SPD] %s%.0f[/color]\n" % [color, sign, speed_diff]

	# Crit chance difference
	var crit_chance_diff = new_item.crit_chance_bonus - old_item.crit_chance_bonus
	if crit_chance_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if crit_chance_diff > 0 else "#FF0000"
		var sign = "+" if crit_chance_diff > 0 else ""
		text += "[color=%s][CRIT] %s%.1f%%[/color]\n" % [color, sign, crit_chance_diff * 100]

	# Crit damage difference
	var crit_dmg_diff = new_item.crit_damage_bonus - old_item.crit_damage_bonus
	if crit_dmg_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if crit_dmg_diff > 0 else "#FF0000"
		var sign = "+" if crit_dmg_diff > 0 else ""
		text += "[color=%s][CRIT DMG] %s%.1f%%[/color]\n" % [color, sign, crit_dmg_diff * 100]

	# Fire rate difference
	var fire_rate_diff = new_item.fire_rate_bonus - old_item.fire_rate_bonus
	if fire_rate_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if fire_rate_diff > 0 else "#FF0000"
		var sign = "+" if fire_rate_diff > 0 else ""
		text += "[color=%s][FIRE RATE] %s%.1f%%[/color]\n" % [color, sign, fire_rate_diff * 100]

	# Armor difference
	var armor_diff = new_item.armor_bonus - old_item.armor_bonus
	if armor_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if armor_diff > 0 else "#FF0000"
		var sign = "+" if armor_diff > 0 else ""
		text += "[color=%s][ARMOR] %s%.1f%%[/color]\n" % [color, sign, armor_diff * 100]

	# Cooldown difference
	var cooldown_diff = new_item.cooldown_reduction_bonus - old_item.cooldown_reduction_bonus
	if cooldown_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if cooldown_diff > 0 else "#FF0000"
		var sign = "+" if cooldown_diff > 0 else ""
		text += "[color=%s][CDR] %s%.1f%%[/color]\n" % [color, sign, cooldown_diff * 100]

	# Luck difference
	var luck_diff = new_item.luck_bonus - old_item.luck_bonus
	if luck_diff != 0:
		has_any_difference = true
		var color = "#00FF00" if luck_diff > 0 else "#FF0000"
		var sign = "+" if luck_diff > 0 else ""
		text += "[color=%s][LUCK] %s%.1f%%[/color]\n" % [color, sign, luck_diff * 100]

	if not has_any_difference:
		text = "[center][color=#888888]Items have identical stats[/color][/center]\n"

	return text

func get_stat_comparison_text(new_item: Item, old_item: Item) -> String:
	var text = ""

	# Health comparison
	var health_diff = new_item.health_bonus - old_item.health_bonus
	if health_diff != 0:
		var color = "#00FF00" if health_diff > 0 else "#FF0000"
		var sign_str = "+" if health_diff > 0 else ""
		text += "[color=%s]❤️ %s%.0f HP[/color]\n" % [color, sign_str, health_diff]

	# Damage comparison
	var damage_diff = new_item.damage_bonus - old_item.damage_bonus
	if damage_diff != 0:
		var color = "#00FF00" if damage_diff > 0 else "#FF0000"
		var sign_str = "+" if damage_diff > 0 else ""
		text += "[color=%s]⚔️ %s%.1f%% Damage[/color]\n" % [color, sign_str, damage_diff * 100]

	# Speed comparison
	var speed_diff = new_item.speed_bonus - old_item.speed_bonus
	if speed_diff != 0:
		var color = "#00FF00" if speed_diff > 0 else "#FF0000"
		var sign_str = "+" if speed_diff > 0 else ""
		text += "[color=%s]⚡ %s%.0f Speed[/color]\n" % [color, sign_str, speed_diff]

	# Crit chance comparison
	var crit_diff = new_item.crit_chance_bonus - old_item.crit_chance_bonus
	if crit_diff != 0:
		var color = "#00FF00" if crit_diff > 0 else "#FF0000"
		var sign_str = "+" if crit_diff > 0 else ""
		text += "[color=%s]💥 %s%.1f%% Crit Chance[/color]\n" % [color, sign_str, crit_diff * 100]

	# Crit damage comparison
	var crit_dmg_diff = new_item.crit_damage_bonus - old_item.crit_damage_bonus
	if crit_dmg_diff != 0:
		var color = "#00FF00" if crit_dmg_diff > 0 else "#FF0000"
		var sign_str = "+" if crit_dmg_diff > 0 else ""
		text += "[color=%s]💥 %s%.1f%% Crit Damage[/color]\n" % [color, sign_str, crit_dmg_diff * 100]

	# Fire rate comparison
	var fire_rate_diff = new_item.fire_rate_bonus - old_item.fire_rate_bonus
	if fire_rate_diff != 0:
		var color = "#00FF00" if fire_rate_diff > 0 else "#FF0000"
		var sign_str = "+" if fire_rate_diff > 0 else ""
		text += "[color=%s]🔫 %s%.1f%% Fire Rate[/color]\n" % [color, sign_str, fire_rate_diff * 100]

	# Armor comparison
	var armor_diff = new_item.armor_bonus - old_item.armor_bonus
	if armor_diff != 0:
		var color = "#00FF00" if armor_diff > 0 else "#FF0000"
		var sign_str = "+" if armor_diff > 0 else ""
		text += "[color=%s]🛡️ %s%.1f%% Armor[/color]\n" % [color, sign_str, armor_diff * 100]

	# Cooldown reduction comparison
	var cooldown_diff = new_item.cooldown_reduction_bonus - old_item.cooldown_reduction_bonus
	if cooldown_diff != 0:
		var color = "#00FF00" if cooldown_diff > 0 else "#FF0000"
		var sign_str = "+" if cooldown_diff > 0 else ""
		text += "[color=%s]🔄 %s%.1f%% Cooldown Reduction[/color]\n" % [color, sign_str, cooldown_diff * 100]

	# Luck comparison
	var luck_diff = new_item.luck_bonus - old_item.luck_bonus
	if luck_diff != 0:
		var color = "#00FF00" if luck_diff > 0 else "#FF0000"
		var sign_str = "+" if luck_diff > 0 else ""
		text += "[color=%s]🍀 %s%.1f%% Luck[/color]\n" % [color, sign_str, luck_diff * 100]

	if text == "":
		text = "[color=#FFFF00]Same stats as equipped item[/color]"

	return text

func clear_item_info():
	selected_item = null

	# Clear comparison nodes
	clear_comparison_nodes()

	if item_name_label:
		item_name_label.text = "Select an item to view details"
		item_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	if item_description_label:
		item_description_label.text = ""
		item_description_label.visible = true

	if item_stats_label:
		item_stats_label.text = ""
		item_stats_label.visible = true

	if action_button:
		action_button.visible = false

func _on_action_button_pressed():
	if not selected_item or not equipment_manager:
		return

	if selected_from_inventory:
		# Equip the item from inventory
		if equipment_manager.equip_item(selected_item):
			print("Equipped: %s" % selected_item.item_name)

			# Force update weapon preview if weapon was equipped
			if selected_item.item_type == Item.ItemType.WEAPON:
				update_character_weapon_preview()

			# Clear selection after equipping
			clear_item_info()
		else:
			print("Failed to equip item")
	else:
		# Unequip the item (need to determine which slot)
		var slot_type = selected_item.item_type
		var ring_slot = 1

		# For rings, determine which ring slot
		if slot_type == Item.ItemType.RING:
			if equipment_manager.equipped_ring1 == selected_item:
				ring_slot = 1
			elif equipment_manager.equipped_ring2 == selected_item:
				ring_slot = 2

		if equipment_manager.unequip_item(slot_type, ring_slot):
			print("Unequipped: %s" % selected_item.item_name)

			# Force update weapon preview if weapon was unequipped
			if slot_type == Item.ItemType.WEAPON:
				update_character_weapon_preview()

			# Clear selection after unequipping
			clear_item_info()
		else:
			print("Failed to unequip item (inventory might be full)")

func _on_close_pressed():
	queue_free()
