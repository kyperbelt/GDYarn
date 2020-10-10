extends Object

enum ValueType{
	None,
	StringValue,
	BooleanValue,
	FloatValue
}

var value

var type

func _init(value):
	if typeof(value) == TYPE_OBJECT && value.get_script() == self.get_script():
		#operand
		self.set_value(value.value)
	else:
		set_value(value)

func set_value(value):
	match typeof(value):
		TYPE_REAL,TYPE_INT:
			set_number(value)
		TYPE_BOOL:
			set_boolean(value)
		TYPE_STRING:
			set_string(value)
		_:
			pass

func set_boolean(value: bool):
	_value(value)
	type = ValueType.BooleanValue
	return self

func set_string(value:String):
	_value(value)
	type = ValueType.StringValue
	return self

func set_number(value:float):
	_value(value)
	type = ValueType.FloatValue
	return self

func clear_value():
	type = ValueType.None
	value = null

func clone():
	return get_script().new(self)

func _to_string():
	return "Operand[%s:%s]" % [type,value]

func _value(value):
	self.value = value