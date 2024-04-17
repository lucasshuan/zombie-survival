extends Node
class_name Utils

static func get_closest_body(obj: Node, bodies: Array[Node2D]) -> Node2D:
	var closest_body = null
	var closest_distance = INF
	for body in bodies:
		var distance = obj.global_position.distance_to(body.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_body = body
	return closest_body
