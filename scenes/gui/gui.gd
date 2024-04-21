extends CanvasLayer

@export_group("External")
@export var player: Player

@export_group("Internal")
@export var melee_slot_box: Panel
@export var primary_slot_box: Panel
@export var tertiary_slot_box: Panel
@export var active_slot_panel_stylebox: StyleBoxFlat
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar

func _ready() -> void:
	player.connect("health_changed", on_health_changed)
	player.connect("stamina_changed", on_stamina_changed)
	player.connect("inventory_changed", on_inventory_change)
	player.connect("active_weapon_switched", on_active_weapon_switched)
	
	on_health_changed(player.current_health, player.health)
	on_stamina_changed(player.current_stamina, player.stamina)
	
	for slot in Weapon.Slot.values():
		on_inventory_change(slot)
	
	on_active_weapon_switched(player.active_weapon_slot)

func on_health_changed(health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = health

func on_stamina_changed(stamina: float, max_stamina: float):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

func on_inventory_change(slot: Weapon.Slot) -> void:
	var slot_box: Panel
	var weapon: Weapon = player.inventory[slot]
	
	match slot:
		Weapon.Slot.MELEE:
			slot_box = melee_slot_box
		
		Weapon.Slot.PRIMARY:
			slot_box = primary_slot_box
			var label = slot_box.get_node(^"Label") as Label
			if not weapon:
				label.hide()
			else:
				label.show()
				label.set_text("%d|%d" % [weapon.current_mag_size, weapon.mag_quantity])
		
		Weapon.Slot.TERTIARY:
			slot_box = tertiary_slot_box
			var label = slot_box.get_node(^"Label") as Label
			if not weapon:
				label.hide()
			else:
				label.show()
				label.set_text("%d" % weapon.amount)
	
	var icon = slot_box.get_node(^"Icon") as TextureRect
	icon.texture = weapon.icon_sprite_texture if weapon else null

func on_active_weapon_switched(slot: Weapon.Slot) -> void:
	match slot:
		Weapon.Slot.MELEE:
			melee_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
			primary_slot_box.remove_theme_stylebox_override("panel")
			tertiary_slot_box.remove_theme_stylebox_override("panel")
		Weapon.Slot.PRIMARY:
			melee_slot_box.remove_theme_stylebox_override("panel")
			primary_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
			tertiary_slot_box.remove_theme_stylebox_override("panel")
		Weapon.Slot.TERTIARY:
			melee_slot_box.remove_theme_stylebox_override("panel")
			primary_slot_box.remove_theme_stylebox_override("panel")
			tertiary_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
