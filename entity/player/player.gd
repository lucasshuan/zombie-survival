extends CharacterBody2D
class_name Player

signal health_changed(health: float)
signal stamina_changed(stamina: float)

signal inventory_changed(slot: Item.Slot)
signal active_item_switched(slot: Item.Slot)

const GRAVITY = 480.0

@export_group("Stats")
@export_subgroup("Movement")
@export var speed: float = 40.0
@export var run_speed: float = 70.0
@export var exhausted_speed: float = 25.0
@export var acceleration: float = 0.35
@export var friction: float = 0.25

@export_subgroup("Jump")
@export var jump_velocity: float = -180.0
@export var acceleration_on_air: float = 0.05

@export_subgroup("Health")
@export var health: float = 100.0

@export_subgroup("Stamina")
@export var stamina: float = 120.0
@export var jump_stamina_loss: float = 40.0
@export var run_stamina_loss_rate: float = 60.0
@export var stamina_recovery_rate: float = 120.0
@export var exhausted_stamina_recovery_rate: float = 60.0

@export_group("Internal")
@export var exhausted_stamina_bar_fill_stylebox: StyleBoxFlat
@export var loot_scene: PackedScene
@export var default_arm_sprite_frames: SpriteFrames
@export var body_sprite: AnimatedSprite2D
@export var arm_sprite: AnimatedSprite2D
@export var pickup_area: Area2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar

var current_health: float = health : set = set_current_health
var current_stamina: float = stamina : set = set_current_stamina
var is_running: bool = false
var is_exhausted: bool = false
var active_item_slot: Item.Slot
var inventory: Dictionary = {
	Item.Slot.MELEE: null,
	Item.Slot.PRIMARY: null,
	Item.Slot.TERTIARY: null,
}
var loot_to_pick: Loot = null

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta 
	
	find_loot_to_pick()
	
	var angle = arm_sprite.global_position.angle_to_point(get_global_mouse_position()) - (PI/2)
	if get_active_item():
		arm_sprite.rotation = angle
	
	var is_flipped = rad_to_deg(angle) > 0 or rad_to_deg(angle) < -180
	body_sprite.flip_h = is_flipped
	arm_sprite.flip_h = is_flipped
	
	var direction = Input.get_axis("left", "right")
	if direction:
		is_running = Input.is_action_pressed("sprint") and not is_exhausted
		
		var is_walking_backwards
		if direction == 1:
			is_walking_backwards = body_sprite.flip_h
		if direction == -1:
			is_walking_backwards = not body_sprite.flip_h
		
		body_sprite.play("walk_backwards" if is_walking_backwards else "walk")
		
		var move_speed = exhausted_speed if is_exhausted else (run_speed if is_running else speed)
		velocity.x = lerp(velocity.x, direction * move_speed, acceleration if is_on_floor() else acceleration_on_air)
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
		active_item_slot = Item.Slot.MELEE
		equip_item(active_item_slot)
		active_item_switched.emit(active_item_slot)
	elif event.is_action_pressed("equip_2"):
		active_item_slot = Item.Slot.PRIMARY
		equip_item(active_item_slot)
		active_item_switched.emit(active_item_slot)
	elif event.is_action_pressed("equip_3"):
		active_item_slot = Item.Slot.TERTIARY
		equip_item(active_item_slot)
		active_item_switched.emit(active_item_slot)
	elif event.is_action_pressed("drop"):
		drop_active_item()
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

func get_active_item() -> Item:
	return inventory[active_item_slot]

func find_loot_to_pick() -> void:
	var bodies_in_range = pickup_area.get_overlapping_bodies()
	if not bodies_in_range.is_empty():
		var pickable_drops = bodies_in_range.filter(func(area): return area is Loot)
		var closest_drop = Utils.get_closest_body(self, pickable_drops) as Loot
		if closest_drop != loot_to_pick:
			loot_to_pick = closest_drop

func drop_active_item() -> void:
	drop_item(active_item_slot)

func drop_item(slot: Item.Slot) -> void:
	if inventory[slot] == null:
		return
	
	var loot_scene_instance: Loot = loot_scene.instantiate()
	loot_scene_instance.item = inventory[slot]
	loot_scene_instance.position = global_position
	get_tree().root.add_child(loot_scene_instance)
	
	inventory[slot] = null
	
	if active_item_slot == slot:
		arm_sprite.sprite_frames = default_arm_sprite_frames
		arm_sprite.rotation_degrees = 0

func pick_item() -> void:
	if not loot_to_pick:
		return
	
	var item = loot_to_pick.item
	
	drop_item(item.slot)
	inventory[item.slot] = loot_to_pick.item
	if active_item_slot == item.slot:
		equip_item(item.slot)
	
	loot_to_pick.queue_free()
	loot_to_pick = null
	
	inventory_changed.emit(item.slot)

func equip_item(slot: Item.Slot) -> void:
	var item = inventory[slot]
	if item:
		arm_sprite.sprite_frames = item.arm_sprite_frames
		return
	arm_sprite.sprite_frames = default_arm_sprite_frames
	arm_sprite.rotation_degrees = 0

func primary_action() -> void:
	var item = get_active_item()
	if not item:
		return
	
	if item is Gun:
		item.shoot(global_position, get_global_mouse_position())
		inventory_changed.emit(active_item_slot)
	
	var on_animation_finished = func():
		arm_sprite.play("idle")
	
	arm_sprite.play("use")
	arm_sprite.animation_looped.connect(on_animation_finished, CONNECT_ONE_SHOT)

func reload() -> void:
	var item = get_active_item()
	if item is Gun:
		item.reload()
		inventory_changed.emit(active_item_slot)

func take_damage(damage: float) -> void:
	health -= damage
