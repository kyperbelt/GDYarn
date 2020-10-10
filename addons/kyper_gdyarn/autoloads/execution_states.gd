extends Node

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
	
	for key in YarnGlobals.TokenType.keys():
		if YarnGlobals.TokenType[key] == type:
			return key					
	return string

#combine all the programs in the provided array
static func combine_programs(programs : Array = []):
	var YarnProgram = load("res://addons/kyper_gdyarn/core/program/program.gd")
	if programs.size() == 0:
		printerr("no programs to combine - you failure")
		return
	var p = YarnProgram.new()

	for program in programs:
		for nodeKey in program.yarnNodes.keys():
			if p.yarnNodes.has(nodeKey):
				printerr("Program with duplicate node names %s "% nodeKey)
				return
			p.yarnNodes[nodeKey] = program.yarnNodes[nodeKey]

	return p

