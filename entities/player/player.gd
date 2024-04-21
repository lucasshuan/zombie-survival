extends CharacterBody2D
class_name Player

signal died
signal health_changed(health: float)
signal stamina_changed(stamina: float)

signal inventory_changed(slot: Weapon.Slot)
signal active_weapon_switched(slot: Weapon.Slot)

const GRAVITY = 480.0
const ACCELERATION_ON_AIR = 0.05
const DEFAULT_INVINCIBILITY_DURATION = 1.2

@export_group("Stats")
@export_subgroup("Movement")
@export var speed: float = 40.0
@export var run_speed: float = 70.0
@export var exhausted_speed: float = 25.0
@export var acceleration: float = 0.35
@export var friction: float = 0.25

@export_subgroup("Jump")
@export var jump_velocity: float = -180.0

@export_subgroup("Health")
@export var health: float = 100.0 : set = set_health
@export var stamina: float = 120.0 : set = set_stamina

@export_group("Internal")
@export var loot_scene: PackedScene
@export var default_arm_sprite_frames: SpriteFrames
@export var body_sprite: AnimatedSprite2D
@export var arm_sprite: AnimatedSprite2D
@export var pickup_area: Area2D
@export var melee_hitbox_area: Area2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var exhausted_stamina_bar_fill_stylebox: StyleBoxFlat
@export var shot_spawn_point: Node2D

var current_health: float = health : set = set_current_health
var current_stamina: float = stamina : set = set_current_stamina
var jump_stamina_loss: float = 40.0
var run_stamina_loss_rate: float = 60.0
var stamina_recovery_rate: float = 120.0
var exhausted_stamina_recovery_rate: float = 60.0
var is_running: bool = false
var is_exhausted: bool = false
var is_invincible: bool = false
var active_weapon_slot: Weapon.Slot
var inventory: Dictionary = {
	Weapon.Slot.MELEE: null,
	Weapon.Slot.PRIMARY: null,
	Weapon.Slot.TERTIARY: null,
}
var loot_to_pick: Loot = null
var direction: int = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta 
	
	find_loot_to_pick()
	
	var angle = arm_sprite.global_position.angle_to_point(get_global_mouse_position()) - (PI/2)
	if get_active_weapon():
		arm_sprite.rotation = angle
	
	var is_flipped = rad_to_deg(angle) > 0 or rad_to_deg(angle) < -180
	body_sprite.scale.x = -1 if is_flipped else 1
	arm_sprite.scale.x = -1 if is_flipped else 1
	
	direction = Input.get_axis("left", "right")
	if direction:
		is_running = Input.is_action_pressed("sprint") and not is_exhausted
		
		var is_walking_backwards
		if direction == 1:
			is_walking_backwards = body_sprite.flip_h
		if direction == -1:
			is_walking_backwards = not body_sprite.flip_h
		
		body_sprite.play("walk_backwards" if is_walking_backwards else "walk")
		
		var move_speed = exhausted_speed if is_exhausted else (run_speed if is_running else speed)
		velocity.x = lerp(velocity.x, direction * move_speed, acceleration if is_on_floor() else ACCELERATION_ON_AIR)
	else:
		is_running = false
		body_sprite.play("idle")
		velocity.x = lerp(velocity.x, 0.0, friction)
	
	if is_on_floor():
		if is_running:
			body_sprite.speed_scale = 2.0
			current_stamina -= run_stamina_loss_rate * delta
		else:
			body_sprite.speed_scale = 1.0
			current_stamina += (exhausted_stamina_recovery_rate if is_exhausted else stamina_recovery_rate) * delta
	else:
		body_sprite.play("jump")
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		primary_action()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("equip_1"):
		active_weapon_slot = Weapon.Slot.MELEE
		equip_weapon(active_weapon_slot)
		active_weapon_switched.emit(active_weapon_slot)
	elif event.is_action_pressed("equip_2"):
		active_weapon_slot = Weapon.Slot.PRIMARY
		equip_weapon(active_weapon_slot)
		active_weapon_switched.emit(active_weapon_slot)
	elif event.is_action_pressed("equip_3"):
		active_weapon_slot = Weapon.Slot.TERTIARY
		equip_weapon(active_weapon_slot)
		active_weapon_switched.emit(active_weapon_slot)
	elif event.is_action_pressed("drop"):
		drop_active_weapon()
	elif event.is_action_pressed("pickup") and loot_to_pick:
		pick_item()
	elif event.is_action_pressed("jump") and is_on_floor() and not is_exhausted:
		current_stamina -= 10
		velocity.y = jump_velocity
	elif event.is_action_released("jump"):
		if velocity.y < -50:
			velocity.y = -50
	elif event.is_action_pressed("down"):
		set_collision_mask_value(6, false)
	elif event.is_action_released("down"):
		set_collision_mask_value(6, true)
	elif event.is_action_pressed("reload"):
		reload()

func set_health(value: float) -> void:
	health = value
	health_bar.max_value = health

func set_stamina(value: float) -> void:
	stamina = value
	stamina_bar.max_value = stamina

func set_current_health(value: float) -> void:
	current_health = clamp(value, 0, health)
	health_bar.value = current_health
	health_changed.emit(current_health, health)

func set_current_stamina(value: float) -> void:
	current_stamina = clamp(value, 0, stamina)
	stamina_bar.value = current_stamina
	stamina_changed.emit(current_stamina, stamina)
	if current_stamina == stamina:
		return
	stamina_bar.visible = true
	if current_stamina >= stamina-2:
		is_exhausted = false
		stamina_bar.remove_theme_stylebox_override("fill")
		stamina_bar.visible = false
	if current_stamina == 0:
		is_exhausted = true
		stamina_bar.add_theme_stylebox_override("fill", exhausted_stamina_bar_fill_stylebox)

func get_active_weapon() -> Weapon:
	return inventory[active_weapon_slot]

func find_loot_to_pick() -> void:
	var bodies_in_range = pickup_area.get_overlapping_bodies()
	if not bodies_in_range.is_empty():
		var pickable_drops = bodies_in_range.filter(func(area): return area is Loot)
		var closest_drop = Utils.get_closest_body(self, pickable_drops) as Loot
		if closest_drop != loot_to_pick:
			loot_to_pick = closest_drop

func drop_active_weapon() -> void:
	drop_weapon(active_weapon_slot)

func drop_weapon(slot: Weapon.Slot) -> void:
	if inventory[slot] == null:
		return
	
	var loot_scene_instance: Loot = loot_scene.instantiate()
	loot_scene_instance.item = inventory[slot]
	loot_scene_instance.position = global_position
	get_tree().root.add_child(loot_scene_instance)
	
	inventory[slot] = null
	inventory_changed.emit(slot)
	
	if active_weapon_slot == slot:
		arm_sprite.sprite_frames = default_arm_sprite_frames
		arm_sprite.rotation_degrees = 0

func pick_item() -> void:
	if not loot_to_pick:
		return
	
	var item = loot_to_pick.item
	
	if item is Weapon:
		drop_weapon(item.slot)
		inventory[item.slot] = loot_to_pick.item
		inventory_changed.emit(item.slot)
		if active_weapon_slot == item.slot:
			equip_weapon(item.slot)
		
		loot_to_pick.queue_free()
		loot_to_pick = null

func equip_weapon(slot: Weapon.Slot) -> void:
	var weapon = inventory[slot]
	
	if not weapon:
		arm_sprite.sprite_frames = default_arm_sprite_frames
		arm_sprite.rotation_degrees = 0
		return
	
	if weapon is Gun:
		shot_spawn_point.position = weapon.shot_spawn_point_offset
	
	arm_sprite.sprite_frames = weapon.arm_sprite_frames

func primary_action() -> void:
	var weapon = get_active_weapon()
	if not weapon:
		return
	
	arm_sprite.play("use")
	
	var on_animation_finished = func():
		arm_sprite.play("idle")
	
	if weapon is Melee:
		attack(weapon)
	elif weapon is Gun:
		shoot(weapon)
	elif weapon is Throwable:
		throw(weapon)
	inventory_changed.emit(active_weapon_slot)
	
	arm_sprite.animation_looped.connect(on_animation_finished, CONNECT_ONE_SHOT)

func attack(melee: Melee) -> void:
	melee.use()
	
	var on_attack_frame = func():
		if arm_sprite.frame == 1:
			var bodies = melee_hitbox_area.get_overlapping_bodies()
			for body in bodies:
				var knockback = Vector2(melee.knockback.x * direction, melee.knockback.y)
				body.take_damage(melee.damage, melee.knockback)
	
	arm_sprite.frame_changed.connect(on_attack_frame, CONNECT_ONE_SHOT)

func shoot(gun: Gun) -> void:
	if not gun.can_shoot():
		return
	gun.use()
	var bullet_instance = gun.bullet_scene.instantiate() as Bullet
	var spawn_position = shot_spawn_point.global_position 
	var direction = (get_global_mouse_position() - spawn_position).normalized()
	bullet_instance.global_position = spawn_position
	bullet_instance.damage = gun.damage
	bullet_instance.velocity = direction * gun.bullet_speed
	get_tree().root.add_child(bullet_instance)

func throw(throwable: Throwable) -> void:
	throwable.use()
	if throwable.amount <= 0:
		inventory[active_weapon_slot] = null

func reload() -> void:
	var weapon = get_active_weapon()
	if weapon is Gun:
		weapon.reload()
		inventory_changed.emit(active_weapon_slot)

func take_damage(damage: float, knockback: Vector2) -> void:
	if is_invincible:
		return
	is_invincible = true
	current_health -= damage
	velocity += knockback
	
	var damage_tween = create_tween()
	damage_tween.tween_property(self, "modulate", Color.RED, 0.05)
	damage_tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	
	await damage_tween.finished
	
	var invincibility_tween = create_tween()
	invincibility_tween.set_loops(20)
	invincibility_tween.tween_property(self, "visible", true, 0.2)
	invincibility_tween.tween_property(self, "visible", false, 0.01)
	
	Utils.splatter_blood(self, 5)
	
	await get_tree().create_timer(DEFAULT_INVINCIBILITY_DURATION).timeout
	
	invincibility_tween.stop()
	visible = true
	is_invincible = false
