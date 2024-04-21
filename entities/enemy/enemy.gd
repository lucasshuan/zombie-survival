extends CharacterBody2D
class_name Enemy

signal died

const GRAVITY = 480.0
const ATTACK_PAUSE_DURATION = 0.3
const ATTACK_COOLDOWN = 2.0
const VERTICAL_DIRECTION_THRESHOLD = 0.75
const MIN_ATTACK_DISTANCE = 10.0

@export_group("Stats")
@export var damage: float = 25.0
@export var knockback: Vector2 = Vector2(200.0, -40.0)
@export var health: float = 10.0
@export var speed: float = 45.0
@export var acceleration: float = 0.1
@export var friction: float = 0.2
@export var jump_velocity: float = -180.0

@export_group("External")
@export var player: Player

@export_group("Internal")
@export var sprite: AnimatedSprite2D
@export var melee_hitbox_area: Area2D

var current_health: float = health : set = set_current_health
var facing_direction: int = 0
var should_jump: bool = false
var is_thinking: bool = false
var thought_duration: float = 1.0
var thought_elapsed_time: float = randf() * thought_duration
var can_attack: bool = true
var is_attacking: bool = false
var player_distance: Vector2

func set_current_health(value: float) -> void:
	current_health = clamp(value, 0, health)
	if current_health == 0:
		die()

func _physics_process(delta: float) -> void:
	if is_attacking:
		velocity.x = lerp(velocity.x, 0.0, friction)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	var player_position = player.global_position
	player_distance = player_position - global_position
	
	var is_player_in_melee_range = player_distance.length() < MIN_ATTACK_DISTANCE
	if is_on_floor() and is_player_in_melee_range and can_attack:
		attack()
	
	if not is_attacking:
		movement()
	
	move_and_slide()
	
	if thought_elapsed_time < thought_duration and not is_attacking:
		thought_elapsed_time += delta
		return
	thought_elapsed_time = 0.0
	
	should_jump = player_distance.normalized().y < -VERTICAL_DIRECTION_THRESHOLD
	facing_direction = -1 if player_position.x < global_position.x else 1

func movement() -> void:
	if facing_direction:
		sprite.play("walk")
		sprite.scale.x = -1 if facing_direction < 0 else 1
		velocity.x = lerp(velocity.x, facing_direction * speed, acceleration)
	elif not is_on_floor():
		sprite.play("jump")
	else:
		velocity.x = lerp(velocity.x, 0.0, friction)
		sprite.play("idle")
	
	if should_jump and is_on_floor():
		should_jump = false
		velocity.y = jump_velocity

func attack() -> void:
	is_attacking = true
	
	var on_attack_frame = func():
		if sprite.frame == 1:
			sprite.scale.x = -1 if facing_direction < 0 else 1
			velocity.x = facing_direction * 70.0
			var bodies = melee_hitbox_area.get_overlapping_bodies()
			for body in bodies:
				body.take_damage(damage, Vector2(knockback.x * facing_direction, knockback.y))
	
	var on_animation_finished = func():
		can_attack = false
		sprite.pause()
		await get_tree().create_timer(ATTACK_PAUSE_DURATION).timeout
		is_attacking = false
		sprite.play("idle")
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout
		can_attack = true
	
	sprite.play("attack")
	sprite.animation_looped.connect(on_animation_finished, CONNECT_ONE_SHOT)
	sprite.frame_changed.connect(on_attack_frame, CONNECT_ONE_SHOT)

func take_damage(damage: float, knockback: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	velocity += knockback
	
	Utils.splatter_blood(self, 5)
	
	current_health -= damage

func die() -> void:
	queue_free()
