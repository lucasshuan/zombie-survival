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
	player.connect("health_changed", on_health_bar_change)
	player.connect("stamina_changed", on_stamina_bar_change)
	player.connect("inventory_changed", on_weapon_slot_box_change)
	player.connect("active_item_switched", on_active_weapon_switch)
	
	on_health_bar_change(player.current_health, player.health)
	on_stamina_bar_change(player.current_stamina, player.stamina)
	
	for slot in Item.Slot.values():
		on_weapon_slot_box_change(slot)
	
	on_active_weapon_switch(player.active_item_slot)

func on_health_bar_change(health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = health

func on_stamina_bar_change(stamina: float, max_stamina: float):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

func on_weapon_slot_box_change(slot: Item.Slot) -> void:
	var slot_box: Panel
	var item = player.inventory[slot]
	
	match slot:
		Item.Slot.MELEE:
			slot_box = melee_slot_box
		
		Item.Slot.PRIMARY:
			slot_box = primary_slot_box
			var label = slot_box.get_node(^"Label") as Label
			if not item:
				label.hide()
			else:
				label.show()
				label.set_text("%d|%d" % [item.current_mag_size, item.mag_quantity])
		
		Item.Slot.TERTIARY:
			slot_box = tertiary_slot_box
			var label = slot_box.get_node(^"Label") as Label
			if not item:
				label.hide()
			else:
				label.show()
				label.set_text("%d" % item.amount)
	
	var icon = slot_box.get_node(^"Icon") as TextureRect
	icon.texture = item.icon_sprite_texture if item else null

func on_active_weapon_switch(slot: Item.Slot) -> void:
	match slot:
		Item.Slot.MELEE:
			melee_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
			primary_slot_box.remove_theme_stylebox_override("panel")
			tertiary_slot_box.remove_theme_stylebox_override("panel")
		Item.Slot.PRIMARY:
			melee_slot_box.remove_theme_stylebox_override("panel")
			primary_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
			tertiary_slot_box.remove_theme_stylebox_override("panel")
		Item.Slot.TERTIARY:
			melee_slot_box.remove_theme_stylebox_override("panel")
			primary_slot_box.remove_theme_stylebox_override("panel")
			tertiary_slot_box.add_theme_stylebox_override("panel", active_slot_panel_stylebox)
