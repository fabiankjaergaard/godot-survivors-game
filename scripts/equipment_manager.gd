extends Node
class_name EquipmentManager

# Equipment slots
var equipped_weapon: Item = null
var equipped_helmet: Item = null
var equipped_chest: Item = null
var equipped_gloves: Item = null
var equipped_legs: Item = null
var equipped_shoes: Item = null
var equipped_ring1: Item = null
var equipped_ring2: Item = null
var equipped_amulet: Item = null

# Inventory (max 48 items, scrollable)
var inventory: Array[Item] = []
var max_inventory_size: int = 48

signal equipment_changed
signal inventory_changed

func equip_item(item: Item) -> bool:
	if not item:
		return false

	var old_item: Item = null

	match item.item_type:
		Item.ItemType.WEAPON:
			old_item = equipped_weapon
			equipped_weapon = item
		Item.ItemType.HELMET:
			old_item = equipped_helmet
			equipped_helmet = item
		Item.ItemType.CHEST:
			old_item = equipped_chest
			equipped_chest = item
		Item.ItemType.GLOVES:
			old_item = equipped_gloves
			equipped_gloves = item
		Item.ItemType.LEGS:
			old_item = equipped_legs
			equipped_legs = item
		Item.ItemType.SHOES:
			old_item = equipped_shoes
			equipped_shoes = item
		Item.ItemType.RING:
			# Try to equip in first empty ring slot
			if equipped_ring1 == null:
				equipped_ring1 = item
			elif equipped_ring2 == null:
				equipped_ring2 = item
			else:
				# Both slots full, replace ring1
				old_item = equipped_ring1
				equipped_ring1 = item
		Item.ItemType.AMULET:
			old_item = equipped_amulet
			equipped_amulet = item
		_:
			print("Cannot equip item type: ", item.get_type_name())
			return false

	# Remove from inventory
	inventory.erase(item)

	# Add old item back to inventory if there was one
	if old_item:
		add_to_inventory(old_item)

	equipment_changed.emit()
	inventory_changed.emit()
	print("Equipped: %s" % item.item_name)
	return true

func unequip_item(slot_type: Item.ItemType, ring_slot: int = 1) -> bool:
	var item: Item = null

	match slot_type:
		Item.ItemType.WEAPON:
			item = equipped_weapon
			equipped_weapon = null
		Item.ItemType.HELMET:
			item = equipped_helmet
			equipped_helmet = null
		Item.ItemType.CHEST:
			item = equipped_chest
			equipped_chest = null
		Item.ItemType.GLOVES:
			item = equipped_gloves
			equipped_gloves = null
		Item.ItemType.LEGS:
			item = equipped_legs
			equipped_legs = null
		Item.ItemType.SHOES:
			item = equipped_shoes
			equipped_shoes = null
		Item.ItemType.RING:
			# Unequip specific ring slot
			if ring_slot == 1:
				item = equipped_ring1
				equipped_ring1 = null
			else:
				item = equipped_ring2
				equipped_ring2 = null
		Item.ItemType.AMULET:
			item = equipped_amulet
			equipped_amulet = null
		_:
			return false

	if item:
		if add_to_inventory(item):
			equipment_changed.emit()
			inventory_changed.emit()
			print("Unequipped: %s" % item.item_name)
			return true
		else:
			# Inventory full, re-equip
			match slot_type:
				Item.ItemType.WEAPON:
					equipped_weapon = item
				Item.ItemType.HELMET:
					equipped_helmet = item
				Item.ItemType.CHEST:
					equipped_chest = item
				Item.ItemType.GLOVES:
					equipped_gloves = item
				Item.ItemType.LEGS:
					equipped_legs = item
				Item.ItemType.SHOES:
					equipped_shoes = item
				Item.ItemType.RING:
					if ring_slot == 1:
						equipped_ring1 = item
					else:
						equipped_ring2 = item
				Item.ItemType.AMULET:
					equipped_amulet = item
			print("Cannot unequip - inventory full!")
			return false

	return false

func add_to_inventory(item: Item) -> bool:
	if inventory.size() >= max_inventory_size:
		print("Inventory full!")
		return false

	inventory.append(item)
	inventory_changed.emit()
	print("Added to inventory: %s" % item.item_name)
	return true

func remove_from_inventory(item: Item) -> bool:
	if item in inventory:
		inventory.erase(item)
		inventory_changed.emit()
		return true
	return false

func get_total_stats() -> Dictionary:
	var stats = {
		"health_bonus": 0.0,
		"damage_bonus": 0.0,
		"speed_bonus": 0.0,
		"crit_chance_bonus": 0.0,
		"crit_damage_bonus": 0.0,
		"fire_rate_bonus": 0.0,
		"armor_bonus": 0.0,
		"cooldown_reduction_bonus": 0.0,
		"luck_bonus": 0.0
	}

	# Sum all equipped item bonuses
	var equipped_items = [
		equipped_weapon, equipped_helmet, equipped_chest, equipped_gloves,
		equipped_legs, equipped_shoes, equipped_ring1, equipped_ring2, equipped_amulet
	]
	for item in equipped_items:
		if item:
			stats.health_bonus += item.health_bonus
			stats.damage_bonus += item.damage_bonus
			stats.speed_bonus += item.speed_bonus
			stats.crit_chance_bonus += item.crit_chance_bonus
			stats.crit_damage_bonus += item.crit_damage_bonus
			stats.fire_rate_bonus += item.fire_rate_bonus
			stats.armor_bonus += item.armor_bonus
			stats.cooldown_reduction_bonus += item.cooldown_reduction_bonus
			stats.luck_bonus += item.luck_bonus

	return stats

func clear_all():
	equipped_weapon = null
	equipped_helmet = null
	equipped_chest = null
	equipped_gloves = null
	equipped_legs = null
	equipped_shoes = null
	equipped_ring1 = null
	equipped_ring2 = null
	equipped_amulet = null
	inventory.clear()
	equipment_changed.emit()
	inventory_changed.emit()
