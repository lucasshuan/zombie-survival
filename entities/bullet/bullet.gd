extends RigidBody2D
class_name Bullet

@export_group("Internal")
@export var sprite: Sprite2D
@export var collision: CollisionShape2D
@export var texture: Texture2D

var damage: float = 0.0
var knockback: float = 80.0
var velocity: Vector2 : set = set_velocity

func _enter_tree() -> void:
	sprite.texture = texture
	var shape = RectangleShape2D.new()
	shape.size = texture.get_size()
	collision.shape = shape

func set_velocity(value: Vector2) -> void:
	velocity = value
	rotation = velocity.angle() - PI/2
	linear_velocity = velocity

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(damage, velocity.normalized() * knockback)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
