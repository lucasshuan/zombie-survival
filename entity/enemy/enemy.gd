extends CharacterBody2D
class_name Enemy

const GRAVITY = 480.0

@export_group("Stats")
@export var health: float = 1.0
@export var speed: float = 40.0
@export var acceleration: float = 0.1
@export var friction: float = 0.2
@export var jump_velocity: float = -180.0
@export var vertical_direction_threshold: float = 0.75

@export_group("External")
@export var player: Player

@export_group("Internal")
@export var sprite: AnimatedSprite2D

var current_health: float = health : set = set_current_health
var facing_direction: int = 0
var should_jump: bool = false
var is_thinking: bool = false
var thought_duration: float = 1.0
var thought_elapsed_time: float = randf() * thought_duration

func set_current_health(value: float) -> void:
	current_health = clamp(value, 0, health)
	if current_health < 0:
		die()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var player_position = player.global_position
	var player_direction = (player_position - global_position).normalized()
	if facing_direction:
		sprite.play("walk")
		sprite.flip_h = facing_direction < 0
		velocity.x = lerp(velocity.x, facing_direction * speed, acceleration)
	elif not is_on_floor():
		sprite.play("jump")
	else:
		velocity.x = lerp(velocity.x, 0.0, friction)
		sprite.play("idle")
	
	if should_jump and is_on_floor():
		should_jump = false
		velocity.y = jump_velocity
	
	move_and_slide()
	
	if thought_elapsed_time < thought_duration:
		thought_elapsed_time += delta
		return
	thought_elapsed_time = 0.0
	
	should_jump = player_direction.y < -vertical_direction_threshold
	facing_direction = -1 if player_position.x < global_position.x else 1

func take_damage(damage: float) -> void:
	health -= damage

func die() -> void:
	queue_free()
