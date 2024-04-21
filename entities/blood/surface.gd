extends Sprite2D
class_name BloodSurface

var surface_image: Image = Image.new()
var surface_texture: ImageTexture = ImageTexture.new()
var blood_image: Image = Image.new()
var blood_texture: ImageTexture = ImageTexture.new()

func _ready() -> void:
	surface_image.create(1500, 1000, false, Image.FORMAT_RGBAH)
	surface_image.fill(Color(0, 0, 0, 0))
	surface_texture.create_from_image(surface_image)
	
	blood_image.load(^"res://assets/sprites/blood/blood1.png")
	blood_image.convert(Image.FORMAT_RGBAH)
	blood_texture.create_from_image(blood_image)
	
	texture = surface_texture

func _physics_process(delta: float) -> void:
	surface_texture.create_from_image(surface_image)

func draw_blood(draw_pos: Vector2):
	surface_image.blit_rect(blood_image, Rect2(Vector2.ZERO, Vector2(1, 1)), draw_pos)
	surface_image.set_pixel(draw_pos.x, draw_pos.y, Color.DARK_RED)
