@tool
extends RigidBody2D
class_name Loot

@export_group("External")
@export var item: Item :
	set(value):
		item = value
		if item:
			var texture = item.drop_sprite_texture
			sprite.texture = texture
			collision.shape = RectangleShape2D.new()
			collision.shape.size = texture.get_size()

@export_group("Internal")
@export var sprite: Sprite2D
@export var collision: CollisionShape2D
