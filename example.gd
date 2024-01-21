extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():

	var file := FileAccess.open("res://test/scripts/projects/space/Scene1.yarn", FileAccess.READ)
	print(file.get_as_text())

	var program := YarnProgram.new()	
	var error = YarnCompiler.compile_string(file.get_as_text(), "Example", program, true, true)
	if error != Error.OK:
		print("Error compiling Yarn script: " + error)
		return
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
