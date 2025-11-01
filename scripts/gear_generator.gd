extends Node
class_name GearGenerator

# Rarity weights (higher = more common)
const RARITY_WEIGHTS = {
	Item.Rarity.COMMON: 50,
	Item.Rarity.UNCOMMON: 30,
	Item.Rarity.RARE: 15,
	Item.Rarity.EPIC: 4,
	Item.Rarity.LEGENDARY: 1
}

# Item type weights
const TYPE_WEIGHTS = {
	Item.ItemType.WEAPON: 15,
	Item.ItemType.HELMET: 10,
	Item.ItemType.CHEST: 15,
	Item.ItemType.GLOVES: 10,
	Item.ItemType.LEGS: 10,
	Item.ItemType.SHOES: 10,
	Item.ItemType.RING: 20,
	Item.ItemType.AMULET: 10
}

# Prefixes and suffixes for random names
const WEAPON_PREFIXES = ["Ancient", "Blazing", "Frozen", "Lightning", "Mystic", "Dark", "Holy", "Arcane"]
const WEAPON_BASES = ["Staff", "Wand", "Scepter", "Rod", "Orb"]
const WEAPON_SUFFIXES = ["of Power", "of Wisdom", "of Destruction", "of the Mage", "of Eternity"]

const HELMET_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Sage's", "Wizard's", "Sorcerer's"]
const HELMET_BASES = ["Hat", "Hood", "Crown", "Circlet", "Helm"]
const HELMET_SUFFIXES = ["of Insight", "of Knowledge", "of Power", "of the Archmage"]

const CHEST_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Protective", "Blessed", "Warded"]
const CHEST_BASES = ["Robes", "Vestments", "Garments", "Cloak", "Mantle"]
const CHEST_SUFFIXES = ["of Protection", "of Resilience", "of the Defender", "of Warding"]

const GLOVES_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Blessed", "Warded"]
const GLOVES_BASES = ["Gloves", "Gauntlets", "Handwraps", "Mitts"]
const GLOVES_SUFFIXES = ["of Dexterity", "of Power", "of the Mage"]

const LEGS_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Protective", "Blessed"]
const LEGS_BASES = ["Leggings", "Pants", "Trousers", "Greaves"]
const LEGS_SUFFIXES = ["of Swiftness", "of Protection", "of the Traveler"]

const SHOES_PREFIXES = ["Enchanted", "Mystic", "Swift", "Light", "Blessed"]
const SHOES_BASES = ["Boots", "Shoes", "Slippers", "Sandals"]
const SHOES_SUFFIXES = ["of Speed", "of Swiftness", "of the Wind"]

const RING_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Ancient", "Blessed", "Cursed"]
const RING_BASES = ["Ring", "Band", "Circle"]
const RING_SUFFIXES = ["of Power", "of Speed", "of Might", "of the Elements", "of Fortune"]

const AMULET_PREFIXES = ["Enchanted", "Mystic", "Arcane", "Ancient", "Blessed", "Holy"]
const AMULET_BASES = ["Amulet", "Pendant", "Talisman", "Charm", "Necklace"]
const AMULET_SUFFIXES = ["of Power", "of Wisdom", "of Protection", "of the Archmage"]

static func generate_random_item() -> Item:
	var item = Item.new()

	# Random rarity (weighted)
	item.rarity = get_random_rarity()

	# Random type (weighted)
	item.item_type = get_random_type()

	# Generate name based on type
	item.item_name = generate_item_name(item.item_type)

	# Generate description
	item.description = generate_description(item)

	# Generate stats based on rarity and type
	generate_stats(item)

	return item

static func get_random_rarity() -> Item.Rarity:
	var total_weight = 0
	for weight in RARITY_WEIGHTS.values():
		total_weight += weight

	var rand_value = randf() * total_weight
	var current_weight = 0

	for rarity in RARITY_WEIGHTS:
		current_weight += RARITY_WEIGHTS[rarity]
		if rand_value <= current_weight:
			return rarity

	return Item.Rarity.COMMON

static func get_random_type() -> Item.ItemType:
	var total_weight = 0
	for weight in TYPE_WEIGHTS.values():
		total_weight += weight

	var rand_value = randf() * total_weight
	var current_weight = 0

	for type in TYPE_WEIGHTS:
		current_weight += TYPE_WEIGHTS[type]
		if rand_value <= current_weight:
			return type

	return Item.ItemType.WEAPON

static func generate_item_name(type: Item.ItemType) -> String:
	var prefix = ""
	var base = ""
	var suffix = ""

	match type:
		Item.ItemType.WEAPON:
			prefix = WEAPON_PREFIXES[randi() % WEAPON_PREFIXES.size()]
			base = WEAPON_BASES[randi() % WEAPON_BASES.size()]
			if randf() < 0.6:  # 60% chance for suffix
				suffix = " " + WEAPON_SUFFIXES[randi() % WEAPON_SUFFIXES.size()]
		Item.ItemType.HELMET:
			prefix = HELMET_PREFIXES[randi() % HELMET_PREFIXES.size()]
			base = HELMET_BASES[randi() % HELMET_BASES.size()]
			if randf() < 0.6:
				suffix = " " + HELMET_SUFFIXES[randi() % HELMET_SUFFIXES.size()]
		Item.ItemType.CHEST:
			prefix = CHEST_PREFIXES[randi() % CHEST_PREFIXES.size()]
			base = CHEST_BASES[randi() % CHEST_BASES.size()]
			if randf() < 0.6:
				suffix = " " + CHEST_SUFFIXES[randi() % CHEST_SUFFIXES.size()]
		Item.ItemType.GLOVES:
			prefix = GLOVES_PREFIXES[randi() % GLOVES_PREFIXES.size()]
			base = GLOVES_BASES[randi() % GLOVES_BASES.size()]
			if randf() < 0.6:
				suffix = " " + GLOVES_SUFFIXES[randi() % GLOVES_SUFFIXES.size()]
		Item.ItemType.LEGS:
			prefix = LEGS_PREFIXES[randi() % LEGS_PREFIXES.size()]
			base = LEGS_BASES[randi() % LEGS_BASES.size()]
			if randf() < 0.6:
				suffix = " " + LEGS_SUFFIXES[randi() % LEGS_SUFFIXES.size()]
		Item.ItemType.SHOES:
			prefix = SHOES_PREFIXES[randi() % SHOES_PREFIXES.size()]
			base = SHOES_BASES[randi() % SHOES_BASES.size()]
			if randf() < 0.6:
				suffix = " " + SHOES_SUFFIXES[randi() % SHOES_SUFFIXES.size()]
		Item.ItemType.RING:
			prefix = RING_PREFIXES[randi() % RING_PREFIXES.size()]
			base = RING_BASES[randi() % RING_BASES.size()]
			if randf() < 0.6:
				suffix = " " + RING_SUFFIXES[randi() % RING_SUFFIXES.size()]
		Item.ItemType.AMULET:
			prefix = AMULET_PREFIXES[randi() % AMULET_PREFIXES.size()]
			base = AMULET_BASES[randi() % AMULET_BASES.size()]
			if randf() < 0.6:
				suffix = " " + AMULET_SUFFIXES[randi() % AMULET_SUFFIXES.size()]

	return prefix + " " + base + suffix

static func generate_description(item: Item) -> String:
	var desc = "A %s " % item.get_rarity_name().to_lower()

	match item.item_type:
		Item.ItemType.WEAPON:
			desc += "weapon for spellcasters."
		Item.ItemType.HELMET:
			desc += "headpiece that enhances magical abilities."
		Item.ItemType.CHEST:
			desc += "protective garment for wizards."
		Item.ItemType.GLOVES:
			desc += "pair of gloves imbued with magic."
		Item.ItemType.LEGS:
			desc += "protective legwear for adventurers."
		Item.ItemType.SHOES:
			desc += "magical footwear that enhances mobility."
		Item.ItemType.RING:
			desc += "ring imbued with arcane power."
		Item.ItemType.AMULET:
			desc += "amulet blessed with magical properties."

	return desc

static func generate_stats(item: Item):
	# Base multiplier based on rarity
	var rarity_mult = 1.0
	match item.rarity:
		Item.Rarity.COMMON:
			rarity_mult = 1.0
		Item.Rarity.UNCOMMON:
			rarity_mult = 1.5
		Item.Rarity.RARE:
			rarity_mult = 2.5
		Item.Rarity.EPIC:
			rarity_mult = 4.0
		Item.Rarity.LEGENDARY:
			rarity_mult = 6.0

	# Generate stats based on item type
	match item.item_type:
		Item.ItemType.WEAPON:
			# Weapons: damage, fire rate, crit
			item.damage_bonus = randf_range(0.1, 0.3) * rarity_mult
			item.fire_rate_bonus = randf_range(0.05, 0.15) * rarity_mult
			if randf() < 0.5:
				item.crit_chance_bonus = randf_range(0.05, 0.15) * rarity_mult
			if randf() < 0.3:
				item.crit_damage_bonus = randf_range(0.2, 0.4) * rarity_mult
			item.sell_value = int(100 * rarity_mult)

		Item.ItemType.HELMET:
			# Helmets: health, armor, crit chance
			item.health_bonus = randf_range(20, 40) * rarity_mult
			item.armor_bonus = randf_range(0.05, 0.15) * rarity_mult
			if randf() < 0.4:
				item.crit_chance_bonus = randf_range(0.05, 0.1) * rarity_mult
			item.sell_value = int(75 * rarity_mult)

		Item.ItemType.CHEST:
			# Chest: health, speed, armor
			item.health_bonus = randf_range(30, 60) * rarity_mult
			item.speed_bonus = randf_range(20, 40) * rarity_mult
			if randf() < 0.4:
				item.armor_bonus = randf_range(0.08, 0.15) * rarity_mult
			item.sell_value = int(100 * rarity_mult)

		Item.ItemType.GLOVES:
			# Gloves: damage, crit, cooldown
			item.damage_bonus = randf_range(0.1, 0.2) * rarity_mult
			if randf() < 0.5:
				item.crit_chance_bonus = randf_range(0.05, 0.1) * rarity_mult
			if randf() < 0.3:
				item.cooldown_reduction_bonus = randf_range(0.05, 0.15) * rarity_mult
			item.sell_value = int(80 * rarity_mult)

		Item.ItemType.LEGS:
			# Legs: health, speed
			item.health_bonus = randf_range(25, 50) * rarity_mult
			item.speed_bonus = randf_range(15, 30) * rarity_mult
			item.sell_value = int(90 * rarity_mult)

		Item.ItemType.SHOES:
			# Shoes: speed, minor health
			item.speed_bonus = randf_range(30, 50) * rarity_mult
			if randf() < 0.4:
				item.health_bonus = randf_range(10, 20) * rarity_mult
			item.sell_value = int(70 * rarity_mult)

		Item.ItemType.RING:
			# Rings: varied powerful bonuses
			if randf() < 0.6:
				item.damage_bonus = randf_range(0.1, 0.2) * rarity_mult
			if randf() < 0.6:
				item.crit_chance_bonus = randf_range(0.05, 0.1) * rarity_mult
			if randf() < 0.4:
				item.crit_damage_bonus = randf_range(0.2, 0.4) * rarity_mult
			if randf() < 0.4:
				item.luck_bonus = randf_range(0.1, 0.2) * rarity_mult
			item.sell_value = int(150 * rarity_mult)

		Item.ItemType.AMULET:
			# Amulets: health, damage, cooldown, luck
			item.health_bonus = randf_range(20, 40) * rarity_mult
			if randf() < 0.5:
				item.damage_bonus = randf_range(0.1, 0.15) * rarity_mult
			if randf() < 0.3:
				item.cooldown_reduction_bonus = randf_range(0.1, 0.2) * rarity_mult
			if randf() < 0.3:
				item.luck_bonus = randf_range(0.1, 0.15) * rarity_mult
			item.sell_value = int(120 * rarity_mult)
