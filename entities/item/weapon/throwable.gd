extends Weapon
class_name Throwable

@export_range(1, 3) var amount: int = 1

func use() -> void:
	amount -= 1
