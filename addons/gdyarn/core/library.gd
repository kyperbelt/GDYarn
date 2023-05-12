class_name Library

var functions: Dictionary = {}  # String , FunctionInfo


func get_function(name: String) -> FunctionInfo:
	if functions.has(name):
		return functions[name]
	else:
		printerr("Invalid Function: %s" % name)
		return null


func import_library(other) -> void:
	YarnGlobals.merge_dir(functions, other.functions)


func register_function(
	name: String, paramCount: int, function: Callable, returnsValue: bool
) -> void:
	var functionInfo: FunctionInfo = FunctionInfo.new(name, paramCount, function, returnsValue)
	functions[name] = functionInfo


func deregister_function(name: String) -> void:
	if !functions.erase(name):
		pass
