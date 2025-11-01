extends Resource
class_name PassiveItemConfig

@export var item_name: String = "Item"
@export var item_description: String = "A mysterious item"
@export var color: Color = Color.WHITE
@export var stat_type: String = "damage"  # damage, speed, health, xp_gain, pickup_radius
@export var stat_value: float = 1.0  # Multiplier or flat bonus
