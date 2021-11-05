extends Object

# var Value : Script = load("res://addons/gdyarn/core/value.gd")

#name of the function
var name : String

#param count of this function
# -1 means variable arguments
var paramCount : int = 0

#function implementation 
var function : FuncRef

var returnsValue : bool = false

func _init(name:String, paramCount : int, function : FuncRef = null,returnsValue : bool = false):
	self.name = name 
	self.paramCount = paramCount
	self.function = function
	self.returnsValue = returnsValue
	

func invoke(params:Array = []):
	var length = 0
	if params != null:
		length = params.size()
	if check_param_count(length):
		if returnsValue:
			if length > 0:
				var result = function.call_funcv(params)
				# printerr("function is returning null when it shouldnt, ", result," type of ", typeof(result))
				return Value.new(result)
			else:
				return Value.new(function.call_func())
		else:
			if length > 0:
				function.call_funcv(params)
			else :
				function.call_func()
	return null

func check_param_count(pramCount : int)->bool:
	return self.paramCount == paramCount || self.paramCount == -1
