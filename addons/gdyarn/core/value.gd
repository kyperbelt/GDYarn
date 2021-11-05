class_name Value

const NULL_STRING : String = "null"
const FALSE_STRING : String= "false"
const TRUE_STRING : String = "true"
const NANI : String = "NaN"

var type : int = YarnGlobals.ValueType.Nullean
var number : float = 0
var string : String = ""
var variable : String = ""
var boolean : bool = false


func _init(value=NANI):

	if typeof(value) == TYPE_OBJECT && value.has_method("as_number"):
		if value.type == YarnGlobals.ValueType.Variable:
			self.type = value.type
			self.variable = value.variable
		else:
			set_value(value.value())
	else:
		set_value(value)
	

func value():
	match type:
		YarnGlobals.ValueType.Number:
			return number
		YarnGlobals.ValueType.Str:
			return string
		YarnGlobals.ValueType.Boolean:
			return boolean 
		YarnGlobals.ValueType.Variable:
			return variable
	return null

func as_bool()->bool:
	match type:
		YarnGlobals.ValueType.Number:
			return number!=0
		YarnGlobals.ValueType.Str:
			return !string.empty()
		YarnGlobals.ValueType.Boolean:
			return boolean
	return false

func as_string()->String:
	return "%s" % value()

func as_number()->float:
	match type:
		YarnGlobals.ValueType.Number:
			return number
		YarnGlobals.ValueType.Str:
			return float(string)
		YarnGlobals.ValueType.Boolean:
			return 0.0 if !boolean else 1.0 
	return 0.0

func set_value(value):
	
	if value == null || (typeof(value) == TYPE_STRING && value == NANI):
		type = YarnGlobals.ValueType.Nullean
		# printerr("NULLEAN VALUE ",value)
		return

	match typeof(value):
		TYPE_INT,TYPE_REAL:
			type = YarnGlobals.ValueType.Number
			number = value

			# printerr("NUMBER VALUE ",value)
		TYPE_STRING:
			type = YarnGlobals.ValueType.Str
			string = value
			# printerr("String VALUE ",value)
		TYPE_BOOL:
			type = YarnGlobals.ValueType.Boolean
			boolean = value
			# printerr("bool VALUE ",value)
		

#operations >> 

#addition
func add(other):
	if self.type == YarnGlobals.ValueType.Str:
		return get_script().new("%s%s"%[self.value(),other.value()])
	if self.type == YarnGlobals.ValueType.Number:
		return get_script().new(self.number + other.as_number())

	return get_script().new(other.as_number() + self.as_number())

func equals(other)->bool:
	if other.get_script() != self.get_script():
		return false
	if other.value() != self.value():
		return false
	return true

func xor(other):
	if self.type == YarnGlobals.ValueType.Number:
		return get_script().new(pow(self.as_number(),other.as_number()))
	return get_script().new(self.as_bool() != self.as_bool())

#subtract
func sub(other):
	# TODO: add a distinction when subtracting numbers from a string, maybe remove x amount of characters?
	#                        so   ("hello world!" - 5 ) -> "hello w"
	if self.type == YarnGlobals.ValueType.Str:
		return get_script().new(str(value()).replace(str(other.value()),""))
	if self.type == YarnGlobals.ValueType.Number :
		return get_script().new(self.number - other.as_number())
	printerr("NOOOO WE ARE NULLLL")
	return get_script().new(self.as_number() - other.as_number())


#multiply
func mult(other):
	if self.type == YarnGlobals.ValueType.Number:
		return get_script().new(self.number * other.as_number())
	return get_script().new( self.as_number() * other.as_number())

#division
func div(other):
	if self.type == YarnGlobals.ValueType.Number:
		return get_script().new(self.number / other.as_number())
	return get_script().new(self.as_number() / other.as_number())

#modulus
func mod(other):
	if self.type == YarnGlobals.ValueType.Number && other.type == YarnGlobals.ValueType.Number:
		return get_script().new(self.number % other.number)
	return

func negative():
	if self.type == YarnGlobals.ValueType.Number: 
		return get_script().new(-self.number)
	if self.type == YarnGlobals.ValueType.Boolean:
		return get_script().new(!self.as_bool())
	return null

#greater than other
func greater(other)->bool:
	if self.type == YarnGlobals.ValueType.Number && other.type == YarnGlobals.ValueType.Number:
		return self.number > other.number
	return false

#less than other
func less(other)->bool:
	if self.type == YarnGlobals.ValueType.Number && other.type == YarnGlobals.ValueType.Number:
		return self.number < other.number
	return false

#greater than or equal to other
func geq(other)->bool:
	if self.type == YarnGlobals.ValueType.Number && other.type == YarnGlobals.ValueType.Number:
		return self.number > other.number || self.equals(other)
	return false

#lesser than or equal to other
func leq(other)->bool:
	if self.type == YarnGlobals.ValueType.Number && other.type == YarnGlobals.ValueType.Number:
		return self.number < other.number || self.equals(other)
	return false



func _to_string():
	return "value(type[%s]: %s)" % [type,value()]


