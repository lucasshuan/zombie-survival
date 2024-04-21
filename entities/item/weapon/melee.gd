extends Weapon
class_name Melee

@export var damage: float = 5.0
@export var knockback: Vector2 = Vector2(150.0, -30.0)
@export_range(0, 50) var durability: float = 100.0
@export_range(0, 3) var attack_speed: float = 1.0
