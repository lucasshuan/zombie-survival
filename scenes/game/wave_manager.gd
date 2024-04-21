extends Node

@export var enemy: PackedScene

var current_wave = 0

func start_wave() -> void:
	current_wave += 1

func create_enemy() -> void:
	get_tree().create_timer(1)

func on_enemy_died() -> void:
	pass
