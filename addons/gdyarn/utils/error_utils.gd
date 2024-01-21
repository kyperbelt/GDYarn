class_name ErrorUtils

## class for result type object that can contain a value or an error
class Result: 

	var value:
		set(val):
			assert(val == null || error == null, "Cannot set value on error result")
			value = val
		get:
			return value

	var error : ResultError:
		set(err):
			assert(err == null || value == null, "Cannot set error on value result")
			error = err
		get:
			return error

	func _init(value = null, error = null):
		self.value = value
		self.error = error

	## return true if the result is an error
	func is_ok() -> bool:
		return self.error == null

	## if the result is ok, then return the value, else return the else_value
	func ok_or(else_value):
		if self.is_ok():
			return self.value
		else:
			return else_value

	## if the result is ok, then return the value, else return the result of the supplier
	func ok_or_else(supplier: Callable):
		if self.is_ok():
			return self.value
		else:
			return supplier.call()

	## if the result is ok, then call the then_func with the value and return the result of the then_func
	func ok_then(then_func: Callable):
		if self.is_ok():
			return then_func.call(self.value)
		else: 
			return self

	## Return an ok Result
	static func ok(value)->Result:
		return Result.new(value)

	## Return an error Result
	static func err(error_message: String , type : int = 0)->Result:
		var line : int = ErrorUtils.__LINE()
		var file_name : String = ErrorUtils.__SCRIPT_NAME()
		var error = ResultError.new(type, error_message, file_name, line)
		return Result.new(null, error)

	func unwrap():
		assert(self.error == null, "Cannot unwrap error result:%s" % [self.error])
		return self.value


class ResultError:
	var error_message: String
	var file_name: String 
	var line: int 
	var type: int

	func _init(type: int,error_message: String, file_name: String = ErrorUtils.__SCRIPT_NAME(), line: int = ErrorUtils.__LINE()):
		self.error_message = error_message
		self.file_name = file_name 
		self.line = line
		self.type = type
	
	func _to_string() -> String: 
		return "[%s:%d] %s" % [self.file_name, self.line, self.error_message]

static func __SCRIPT_NAME(__depth: int = 1) -> String: 
	var stack : Array[Dictionary]= get_stack()
	var script_name : String = stack[__depth]["source"]
	return script_name.get_file()

static func __LINE(__depth: int = 1) -> int: 
	var stack : Array[Dictionary]= get_stack()
	return stack[__depth]["line"]
	
