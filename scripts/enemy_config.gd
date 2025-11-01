extends Resource
class_name EnemyConfig

@export var enemy_name: String = "Enemy"
@export var color: Color = Color.WHITE
@export var size: Vector2 = Vector2(32, 32)
@export var max_health: float = 20.0
@export var move_speed: float = 100.0
@export var damage_amount: float = 10.0
@export var attack_interval: float = 1.0
@export var xp_reward: int = 10
