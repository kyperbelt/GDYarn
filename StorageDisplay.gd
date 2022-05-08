extends Label

var strings: PoolStringArray = []

onready var storage = get_node("../VariableStorage")


func _ready():
	if storage == null:
		print("something went wrong")
	pass  # Replace with function body.


func _process(_delta):
	strings.resize(0)
	strings.append("Stored Variables:\n")
	for key in storage.var_names():
		strings.append("\t%s : %s \n" % [key, storage.get_value(key)])
	text = strings.join("")
