extends Item
class_name Gun

@export var damage: float = 1
@export var fire_rate: float = 1
@export var mag_size: int = 6
@export var mag_quantity: int = 2
@export var is_automatic: bool = false
@export var reload_duration: float = 1

var current_mag_size: int = mag_size

func shoot(_origin: Vector2, _direction: Vector2) -> void:
	if current_mag_size == 0:
		return
	current_mag_size -= 1

func reload() -> void:
	if mag_quantity == 0:
		return
	mag_quantity -= 1
	current_mag_size = mag_size
