extends Node

const Value = preload("res://addons/gdyarn/core/value.gd")
var variables : Dictionary = {} setget _set_vars,_get_vars

func set_value(name:String,value):
	if !(value is Value):
		variables[name] = Value.new(value)
	else:
		variables[name] = value

# internal function to set the value in the storage - to be used by the virtual machine
func _set_value_(name: String,value):
	set_value(name.trim_prefix("$"),value)

# get a value property from the value stored in the storage
func get_value(name:String):
	return get_value_raw(name).value()

# get the raw Value from the storage
func get_value_raw(name : String):
	return variables[name] if variables.has(name) else null

# function to get the value internally from the dialogue virtual machine
# it removes the '$'
func _get_value_(name:String):
	return get_value_raw(name.trim_prefix("$"))

func clear_values():
	variables.clear()

func _get_vars():
	printerr("Do not access variables in variable store directly - Use `get_value` function")
	return variables

func _set_vars(value):
	printerr("Do not access variables in variable store directly - Use `set_value` function")

# return all the variables currently being stored
func var_names()->Array:
	return variables.keys()
