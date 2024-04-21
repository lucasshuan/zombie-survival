extends Item
class_name Weapon

enum Slot {
	MELEE,
	PRIMARY,
	TERTIARY,
}

@export var slot: Slot
@export var arm_sprite_frames: SpriteFrames
@export var icon_sprite_texture: Texture2D

func use() -> void:
	pass
