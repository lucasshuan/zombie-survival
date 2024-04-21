extends Weapon
class_name Gun

@export var damage: float = 5.0
@export var fire_rate: float = 1.0
@export var bullet_speed: float = 500.0
@export var mag_size: int = 6
@export var mag_quantity: int = 2
@export var is_automatic: bool = false
@export var reload_duration: float = 1.0
@export var shot_spawn_point_offset: Vector2 = Vector2(0, 0)
@export var bullet_scene: PackedScene

var current_mag_size: int = mag_size

func use() -> void:
	if not can_shoot():
		return
	current_mag_size -= 1

func can_shoot() -> bool:
	return current_mag_size != 0

func reload() -> void:
	if mag_quantity == 0:
		return
	mag_quantity -= 1
	current_mag_size = mag_size
