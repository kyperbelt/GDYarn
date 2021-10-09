extends Resource


export(Array, String, FILE , "*.gd") var libraries setget set_libraries

func set_libraries(value):
	if value.size() > libraries.size():
		# added a library
		var added = value.back()
		if !added.is_empty():
			var check : Script = load(added)
			if _is_valid_library(check):
				libraries = value
	elif value.size() == libraries.size():
		# library not added but changed
		var index : int = -1
		for i in range(value.size()):
			if libraries[i] != value[i]:
				index = i
				break
		if _is_valid_library(load(value[index]) as Script):
			libraries = value
	else:
		libraries = value


func _is_valid_library(lib : Script)-> bool:

	if lib.has_method("get_function"):
		return true
	else:
		printerr("Invalid library script : %s")
	return false
