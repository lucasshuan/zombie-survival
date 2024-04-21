extends Area2D

var is_colliding: bool = false
var h_speed: float = randi_range(2, -2)
var v_speed: float = randi_range(1, -1)
var blood_acc: float = randf_range(0.05, 0.1)
var do_wobble: bool = false
var max_count: int = randi_range(2, 10)
var count: int = 0

@onready var draw_surface: BloodSurface = $"/root/Surface"

func _physics_process(delta: float) -> void:
	if not is_colliding:
		do_wobble = false
		v_speed = lerp(v_speed, 5.0, 0.02)
		h_speed = lerp(h_speed, 0.0, 0.02)
		visible = true
	else:
		draw_surface.draw_blood(position)
		count += 1
		if count > max_count: 
			queue_free()
		
		if v_speed > 3: 
			v_speed = 3
		v_speed = lerp(v_speed, 0.1, blood_acc)
		
		if h_speed > 0.1 or h_speed < -0.1:
			h_speed = lerp(h_speed, 0.0 ,0.1)
		else:
			do_wobble = true
		visible = false
		
	
	if do_wobble:
		h_speed += randf_range(-0.01, 0.01)
		h_speed = clamp(h_speed, -0.1, 0.1)
	
	position.y += v_speed
	position.x += h_speed

func _on_blood_body_entered(body: Node) -> void:
	is_colliding = true

func _on_blood_body_exited(body: Node) -> void:
	is_colliding = false
