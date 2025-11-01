extends Resource
class_name Item

# Item info
@export var item_name: String = "Unknown Item"
@export var description: String = "No description"
@export var icon_path: String = ""

# Item type
enum ItemType { WEAPON, HELMET, CHEST, GLOVES, LEGS, SHOES, RING, AMULET, CONSUMABLE, SPELL }
@export var item_type: ItemType = ItemType.WEAPON

# Item rarity
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
@export var rarity: Rarity = Rarity.COMMON

# Stats bonuses (all items can have these)
@export var health_bonus: float = 0.0
@export var damage_bonus: float = 0.0  # Percentage (0.1 = 10%)
@export var speed_bonus: float = 0.0
@export var crit_chance_bonus: float = 0.0  # Percentage (0.05 = 5%)
@export var crit_damage_bonus: float = 0.0  # Multiplier (0.5 = 50% more crit damage)

# Special bonuses
@export var fire_rate_bonus: float = 0.0  # Percentage (0.2 = 20% faster)
@export var armor_bonus: float = 0.0  # Percentage (0.1 = 10% damage reduction)
@export var cooldown_reduction_bonus: float = 0.0  # Percentage (0.2 = 20% faster cooldowns)
@export var luck_bonus: float = 0.0  # Percentage (0.15 = 15% better loot)

# Value
@export var sell_value: int = 10

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color(0.8, 0.8, 0.8, 1)  # Gray
		Rarity.UNCOMMON:
			return Color(0.3, 1, 0.3, 1)  # Green
		Rarity.RARE:
			return Color(0.3, 0.5, 1, 1)  # Blue
		Rarity.EPIC:
			return Color(0.8, 0.3, 1, 1)  # Purple
		Rarity.LEGENDARY:
			return Color(1, 0.6, 0.1, 1)  # Orange
	return Color.WHITE

func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
	return "Unknown"

func get_type_name() -> String:
	match item_type:
		ItemType.WEAPON:
			return "Weapon"
		ItemType.HELMET:
			return "Helmet"
		ItemType.CHEST:
			return "Chest"
		ItemType.GLOVES:
			return "Gloves"
		ItemType.LEGS:
			return "Legs"
		ItemType.SHOES:
			return "Shoes"
		ItemType.RING:
			return "Ring"
		ItemType.AMULET:
			return "Amulet"
		ItemType.CONSUMABLE:
			return "Consumable"
		ItemType.SPELL:
			return "Spell"
	return "Unknown"

func to_dict() -> Dictionary:
	return {
		"item_name": item_name,
		"description": description,
		"icon_path": icon_path,
		"item_type": item_type,
		"rarity": rarity,
		"health_bonus": health_bonus,
		"damage_bonus": damage_bonus,
		"speed_bonus": speed_bonus,
		"crit_chance_bonus": crit_chance_bonus,
		"crit_damage_bonus": crit_damage_bonus,
		"fire_rate_bonus": fire_rate_bonus,
		"armor_bonus": armor_bonus,
		"cooldown_reduction_bonus": cooldown_reduction_bonus,
		"luck_bonus": luck_bonus,
		"sell_value": sell_value
	}

static func from_dict(data: Dictionary) -> Item:
	var item = Item.new()
	item.item_name = data.get("item_name", "Unknown")
	item.description = data.get("description", "")
	item.icon_path = data.get("icon_path", "")
	item.item_type = data.get("item_type", ItemType.WEAPON)
	item.rarity = data.get("rarity", Rarity.COMMON)
	item.health_bonus = data.get("health_bonus", 0.0)
	item.damage_bonus = data.get("damage_bonus", 0.0)
	item.speed_bonus = data.get("speed_bonus", 0.0)
	item.crit_chance_bonus = data.get("crit_chance_bonus", 0.0)
	item.crit_damage_bonus = data.get("crit_damage_bonus", 0.0)
	item.fire_rate_bonus = data.get("fire_rate_bonus", 0.0)
	item.armor_bonus = data.get("armor_bonus", 0.0)
	item.cooldown_reduction_bonus = data.get("cooldown_reduction_bonus", 0.0)
	item.luck_bonus = data.get("luck_bonus", 0.0)
	item.sell_value = data.get("sell_value", 0)
	return item
