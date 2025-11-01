extends Resource
class_name CharacterConfig

# Character configuration

@export var character_id: String = "warrior"
@export var character_name: String = "Warrior"
@export var description: String = "Balanced fighter with good health"
@export var icon: String = "⚔️"

# Stats
@export var base_health: float = 100.0
@export var base_speed: float = 200.0
@export var base_damage_mult: float = 1.0

# Special abilities
@export var start_with_extra_weapon: bool = false
@export var crit_chance_bonus: float = 0.0  # 0.0 to 1.0
@export var crit_damage_mult: float = 1.5  # Default 1.5x
@export var dash_cooldown_mult: float = 1.0  # Lower = faster dash
@export var pickup_radius_bonus: float = 0.0
@export var xp_gain_mult: float = 1.0

# Unlock requirements
@export var is_unlocked_by_default: bool = true
@export var unlock_cost: int = 0
@export var unlock_requirement: String = ""  # e.g., "reach_level_20", "kill_100_enemies"
