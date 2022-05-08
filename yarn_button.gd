### A Simple button that pulses up and down at the specified interval
extends TextureButton

export(float, 0.1, 100) var period = 0.1
export(float) var amplitude = 10

var elapsed: float = 0
var startingPosition: Vector2


func _ready():
	startingPosition = rect_position
	pass


func _process(delta):
	rect_position.y = startingPosition.y + (amplitude * sin(elapsed * ((2 * PI) / period)))
	elapsed += delta


func show_button():
	get_parent().update()
	elapsed = 0
	visible = true


func hide_button():
	visible = false
