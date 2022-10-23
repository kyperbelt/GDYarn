extends Object

var command: String
var args: Array


func _init(input: String):
	var result = input.strip_edges().split(" ")
	self.command = result[0]

	if result.size() > 1:
		result.remove(0)
		args = result
		for i in args.size():
			var arg: String = args[i]
			var arg_lower := arg.to_lower()
			if arg.is_valid_float():
				args[i] = float(arg)
			elif arg.is_valid_integer():
				args[i] = int(arg)
			elif arg_lower == "true":
				args[i] = true
			elif arg_lower == "false":
				args[i] = false
