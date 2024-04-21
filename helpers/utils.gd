extends Node
class_name Utils

static var blood_scene: PackedScene = load(^"res://entities/blood/blood.tscn")

static func get_closest_body(obj: Node, bodies: Array[Node2D]) -> Node2D:
	var closest_body = null
	var closest_distance = INF
	for body in bodies:
		var distance = obj.global_position.distance_to(body.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_body = body
	return closest_body

static func splatter_blood(obj: Node2D, amount: int) -> void:
	for n in amount:
		var blood_instance = blood_scene.instantiate() as Area2D
		blood_instance.global_position = obj.global_position
		obj.get_tree().root.add_child(blood_instance)
