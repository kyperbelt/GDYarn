tool
extends Node

const GDYarnUtils := preload("res://addons/gdyarn/autoloads/gdyarn_utilities.gd")

#VM Execution States

enum ExecutionState{
	Stopped,
	Running,
	WaitingForOption,
	Suspended
}

enum HandlerState{
	PauseExecution,
	ContinueExecution
}

#Compile Status return
enum CompileStatus {
	Succeeded, SucceededUntaggedStrings,
}

enum ByteCode{
		# opA = string: label name
		Label,
		# opA = string: label name
		JumpTo,
		# peek string from stack and jump to that label
		Jump,
		# opA = int: string number
		RunLine,
		# opA = string: command text
		RunCommand,
		# opA = int: string number for option to add
		AddOption,
		# present the current list of options, then clear the list; most recently
		# selected option will be on the top of the stack
		ShowOptions,
		# opA = int: string number in table; push string to stack
		PushString,
		# opA = float: number to push to stack
		PushNumber,
		# opA = int (0 or 1): bool to push to stack
		PushBool,
		# pushes a null value onto the stack
		PushNull,
		# opA = string: label name if top of stack is not null, zero or false, jumps
		# to that label
		JumpIfFalse,
		# discard top of stack
		Pop,
		# opA = string; looks up function, pops as many arguments as needed, result is
		# pushed to stack
		CallFunc,
		# opA = name of variable to get value of and push to stack
		PushVariable,
		# opA = name of variable to store top of stack in
		StoreVariable,
		# stops execution
		Stop,
		# run the node whose name is at the top of the stack
		RunNode
}

enum TokenType {

	#0 Special tokens
	Whitespace, Indent, Dedent, EndOfLine, EndOfInput,

	#5 Numbers. Everybody loves a number
	Number,

	#6 Strings. Everybody also loves a string
	Str,

	#7 '#'
	TagMarker,

	#8 Command syntax ("<<foo>>")
	BeginCommand, EndCommand,

	#10 Variables ("$foo")
	Variable,

	#11 Shortcut syntax ("->")
	ShortcutOption,

	#12 Option syntax ("[[Let's go here|Destination]]")
	OptionStart, # [[
	OptionDelimit, # |
	OptionEnd, # ]]

	# format functions are proccessed further in the compiler


	FormatFunctionStart, # [
	FormatFunctionEnd,   # ]

	# for inline Expressions
	ExpressionFunctionStart, # {
	ExpressionFunctionEnd,    # }

	#15 Command types (specially recognised command word)
	IfToken, ElseIf, ElseToken, EndIf, Set,

	#20 Boolean values
	TrueToken, FalseToken,

	#22 The null value
	NullToken,

	#23 Parentheses
	LeftParen, RightParen,

	#25 Parameter delimiters
	Comma,

	#26 Operators
	EqualTo, # ==, eq, is
	GreaterThan, # >, gt
	GreaterThanOrEqualTo, # >=, gte
	LessThan, # <, lt
	LessThanOrEqualTo, # <=, lte
	NotEqualTo, # !=, neq

	#32 Logical operators
	Or, # ||, or
	And, # &&, and
	Xor, # ^, xor
	Not, # !, not

	# this guy's special because '=' can mean either 'equal to'
	#36 or 'becomes' depending on context
	EqualToOrAssign, # =, to

	#37
	UnaryMinus, # -; this is differentiated from Minus
	# when parsing expressions

	#38
	Add, # +
	Minus, # -
	Multiply, # *
	Divide, # /
	Modulo, # %

	#43
	AddAssign, # +=
	MinusAssign, # -=
	MultiplyAssign, # *=
	DivideAssign, # /=

	Comment, # a run of text that we ignore

	Identifier, # a single word (used for functions)

	Text # a run of text until we hit other syntax
}


enum ExpressionType{
	Value, FunctionCall
}


enum StatementTypes{
	CustomCommand,
	ShortcutOptionGroup,
	Block,
	IfStatement,
	OptionStatement,
	AssignmentStatement,
	Line
}

enum ValueType{
	Number,
	Str,
	Boolean,
	Variable,
	Nullean#null lel
}
static func get_value_type_name(valueType: int):
	for key in ValueType.keys():
		if ValueType[key] == valueType:
			return key
	return "Invalid"

func defaultValue(type):
	pass

static func token_type_name(value:int)->String:
	for key in TokenType.keys():
		if TokenType[key] == value:
			return key
	return "NOTVALID"

static func merge_dir(target, patch):
	for key in patch:
		target[key] = patch[key]
	

#same as top one woops
func token_name(type)->String:
	var string : String = ""
	
	for key in TokenType.keys():
		if TokenType[key] == type:
			return key					
	return string


## FORMAT FUNCTION HANDLERS
class FormatFunctionData:
	var name   := ""
	var value  := ""
	var parameters := {}
	var error : String = ""

	func _init():
		pass

	func _error(message : String):
		error = message
		return self

func expand_format_functions(input:String, locale : String)->String:
	# printerr("locale : %s" % locale)
	var proccessedLocale := locale.split("_")[0]
	var formattedLine:String = input

	# TODO FIXME: probably dont want to compile the regex patterns every time we expand
	# 			  a format a function. Scope this up.
	var regex = RegEx.new()

	# find anything inside of square brackets ["--"]
	regex.compile("((?<=\\[)[^\\]]*)")
	var regexResults: Array = regex.search_all(input)
	# print(" %d groups found in line <%s> "% [regexResults.size(), input])
	if !regexResults.empty():
		for regexResult in regexResults:
			var segment = regexResult.get_string()
			var functionResult : FormatFunctionData = parse_function(segment)
			# print("working on string <%s>" % segment)
			if !functionResult: # skip invalid format functions
				continue

			# display error
			if !functionResult.error.empty():
				formattedLine = formattedLine.replace("["+segment+"]", "<"+functionResult.error+">")
				continue

			var pcase = ""
			# here we use our pluralisation library to get the correct results
			# printerr("functionName = %s value=[%s] , locale=[%s]" % [functionResult.name, functionResult.value, locale])
			match functionResult.name:
				"select":
					if functionResult.value in functionResult.parameters:
						formattedLine = formattedLine.replace("["+segment+"]",functionResult.parameters[functionResult.value])
					else:
						formattedLine = formattedLine.replace("["+segment+"]","<%s has no seleciton>" % functionResult.value)
				"plural":
					pcase = NumberPlurals.plural_case_string(NumberPlurals.get_plural_case(proccessedLocale, float(functionResult.value)))

				"ordinal":
					pcase = NumberPlurals.plural_case_string(NumberPlurals.get_ordinal_case(proccessedLocale,float(functionResult.value)))

			if !pcase.empty():
				if pcase in functionResult.parameters:
					formattedLine = formattedLine.replace("["+segment+"]",functionResult.parameters[pcase])
				else:
					formattedLine = formattedLine.replace("["+segment+"]","<%s>"%pcase)




	return formattedLine


#TODO FIXME: should make a parser that actually steps through the input instead of just collecting all the patterns.
func parse_function(segment : String) -> FormatFunctionData:
	# expexting a format function in the format:
	#                    name "value" param1="paramValue1" param2="paramValue2"


	# we check if its a valid function id it starts with either
	# select | plural | ordinal
	# TODO FIXME: same as in parse_format_functions, we should move this regex compilation so that it doesnt compile each time we are parsing a function
	var functionValidator = RegEx.new()
	functionValidator.compile("^(?:(?:plural)|(?:ordinal)|(?:select))")



	var valuesRegex = RegEx.new()
	valuesRegex.compile("\"[^\"]*\"") # matches all the values in the string "value"


	var paramRegex = RegEx.new()
	paramRegex.compile("(?<=\\s)([^\\s]*(?=(?:=\")))") # matches all params

	var validFunction = functionValidator.search(segment)
	# # if this is not a valid function then we just skip it
	if !validFunction:
		return null


	# # first value in the values regex is our function value
	# # this means that paramRegex should return valuesRegex.size()-1


	var formatFunctionData := FormatFunctionData.new()

	var values : Array = valuesRegex.search_all(segment)
	var params : Array = paramRegex.search_all(segment)

	# printerr("values:%d params:%d" %[values.size(), params.size()])
	if params.size() != values.size()-1:
		printerr("input: " , segment, " params:", params.size(), " values:", values.size())
		return formatFunctionData._error("Missmatched parameters")

	formatFunctionData.name = validFunction.get_string()

	formatFunctionData.value = (values[0] as RegExMatch).get_string().replace("\"","")

	#TODO add position check to
	# # param[i].end must be < value[i].start

	for i in range(1, values.size()):
		formatFunctionData.parameters[params[i-1].get_string()] = values[i].get_string().replace("\"","").replace("%",formatFunctionData.value.replace("\"",""))



	return formatFunctionData
