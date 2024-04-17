extends Resource
class_name Item

enum Slot {
	MELEE,
	PRIMARY,
	TERTIARY,
}

@export var slot: Slot
@export var name: String

@export var arm_sprite_frames: SpriteFrames
@export var drop_sprite_texture: Texture2D
@export var icon_sprite_texture: Texture2D
