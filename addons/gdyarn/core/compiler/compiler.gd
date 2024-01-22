class_name YarnCompiler
# const YarnGlobals = preload("res://addons/gdyarn/autoloads/execution_states.gd")
const Result := ErrorUtils.Result
const ResultError := ErrorUtils.ResultError

# const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")
const LineInfo = preload("res://addons/gdyarn/core/program/yarn_line.gd")
const Instruction = preload("res://addons/gdyarn/core/program/instruction.gd")
const YarnProgram = preload("res://addons/gdyarn/core/program/program.gd")
const Operand = preload("res://addons/gdyarn/core/program/operand.gd")

#patterns
const INVALIDTITLENAME = "[\\[<>\\]{}\\|:\\s#\\$]"

#ERROR Codes
const NO_ERROR: int = 0x00
const LEXER_FAILURE: int = 0x01
const PARSER_FAILURE: int = 0x02
const INVALID_HEADER: int = 0x04
const DUPLICATE_NODES_IN_PROGRAM: int = 0x08
const ERR_COMPILATION_FAILED: int = 0x10

var error = OK

var _errors: int
var _last_error: int

#-----Class vars
var _current_node: CompiledYarnNode
var _raw_text: bool
var _program: YarnProgram
var _filename: String
var _contains_implicit_string_tags: bool
var _label_count: int = 0

#<String, LineInfo>
var _string_table: Dictionary = {}
var _string_count: int = 0

#<int, YarnGlobals.TokenType>
var _tokens: Dictionary = {}


static func compile_string(
	source: String,
	filename,
	program: YarnProgram,
	show_tokens: bool = false,
	print_tree: bool = false
) -> int:
	var Compiler = load("res://addons/gdyarn/core/compiler/compiler.gd")

	var compiler = Compiler.new()
	compiler._filename = filename

	var source_lines: Array = source.split("\n", true)

	# we want to sanatize the strings by removing any trailing whitespace on the 
	# end of each line while preserving the indentation on the left side
	for i in range(source_lines.size()):
		source_lines[i] = source_lines[i].strip_edges(false, true)

	# once we have removed the trailing whitespace we can join the lines back together
	var prepared_source_code := '\n'.join(source_lines)

	#---Begin lexing---
	var lexer := YarnLexer.new()
	var tokens := lexer.tokenize(prepared_source_code, 1)

	if lexer.error != OK:
		printerr("Failed to lex file: %s." % filename)
		return lexer.error

	if show_tokens:
		print_tokens(filename, tokens)

	#---Begin parsing---
	var parser := YarnParser.new(tokens)
	var parsed_nodes: Array[YarnParser.YarnNode] = parser.parse_nodes()

	if (parser.error != OK):
		printerr("Failed to parse file: %s." % filename)
		return parser.error

	if print_tree:
		print("Parsed nodes:")
		for i in range(parsed_nodes.size()):
			var node : YarnParser.YarnNode = parsed_nodes[i] 
			print(node.tree_string(0))
			print("====================================")
			


	#---Begin compiling---
	# compile nodes
	for node in parsed_nodes:
		compiler.compile_node(program, node)
		if compiler.error != OK:
			printerr("Failed to compile Node[%s] in file: %s." % [node.name, filename])
			return compiler.error

	# merge all the yarn strings gathered by thhe compilation into the program string table
	merge_dir(program.yarn_strings, compiler._string_table)

	return OK


static func merge_dir(target, patch):
	for key in patch.keys():
		target[key] = patch[key]


func compile_node(program: YarnProgram, parsed_node) -> void:
	if program.yarn_nodes.has(parsed_node.name):
		# emit_error(DUPLICATE_NODES_IN_PROGRAM)
		error = ERR_ALREADY_EXISTS
		printerr("Duplicate node in program: %s" % parsed_node.name)
	else:
		var nodeCompiled: CompiledYarnNode = CompiledYarnNode.new()

		nodeCompiled.node_name = parsed_node.name
		nodeCompiled.tags = parsed_node.tags


		#raw text
		if parsed_node.source != null && !parsed_node.source.is_empty():
			nodeCompiled.source_id = register_string(
				parsed_node.source, parsed_node.name, "line:" + parsed_node.name, 0, []
			)
		else:
			#compile node
			var startLabel: String = register_label()
			emit(YarnGlobals.ByteCode.Label, nodeCompiled, [Operand.new(startLabel)])

			for statement in parsed_node.statements:
				generate_statement(nodeCompiled, statement)

			#add options
			#todo: add parser flag

			# var hasOptions : bool = false

			# for instruction in nodeCompiled.instructions :
			# 	if instruction.operation == YarnGlobals.ByteCode.AddOption:
			# 		hasOptions = true
			# 	if instruction.operation == YarnGlobals.ByteCode.ShowOptions:
			# 		hasOptions = false

			#if no lingering options we stop
			if !parsed_node.hasOptions:
				# printerr("no options found")
				emit(YarnGlobals.ByteCode.Stop, nodeCompiled)
			else:
				# printerr("found options in node %s "% parsedNode.name)
				#otherwise show and jump to selected
				emit(YarnGlobals.ByteCode.ShowOptions, nodeCompiled)
				emit(YarnGlobals.ByteCode.RunNode, nodeCompiled)

		program.yarn_nodes[nodeCompiled.node_name] = nodeCompiled


func register_string(
	text: String,
	node_name: String,
	id: String = "",
	line_number: int = -1,
	tags: PackedStringArray = []
) -> String:
	var line_id_used: String

	var implicit: bool

	if id.is_empty():
		line_id_used = "%s-%s-%d" % [self._filename.get_file(), node_name, self._string_count]
		self._string_count += 1

		#use this when we generate implicit tags
		#they are not saved and are generated
		#aka dummy tags that change on each compilation
		_contains_implicit_string_tags = true

		implicit = true
	else:
		line_id_used = id
		implicit = false

	var stringInfo: LineInfo = LineInfo.new(
		text, node_name, line_number, _filename.get_file(), implicit, tags
	)
	#add to string table and return id
	self._string_table[line_id_used] = stringInfo

	return line_id_used


func register_label(comment: String = "") -> String:
	_label_count += 1
	return "L%s%s" % [_label_count, comment]


func emit(bytecode, node :CompiledYarnNode= _current_node, operands: Array = []):
	var instruction: Instruction = Instruction.new(null)
	instruction.operation = bytecode
	instruction.operands = operands
	# print("emitting instruction to %s"%node.node_name)

	if node == null:
		printerr("trying to emit to null node with byteCode: %s" % bytecode)
		error = ERR_INVALID_PARAMETER
		return
	node.instructions.append(instruction)
	if bytecode == YarnGlobals.ByteCode.Label:
		#add to label table
		node.labels[instruction.operands[0].value] = node.instructions.size() - 1
	pass


func get_string_tokens() -> Array:
	return []


#compile header
func generate_header():
	pass


#compile instructions for statements
#this will walk through all child branches
#of the parse tree
func generate_statement(node, statement):
	# print("generating statement")
	match statement.type:
		YarnGlobals.StatementTypes.CustomCommand:
			generate_custom_command(node, statement.customCommand)
		YarnGlobals.StatementTypes.ShortcutOptionGroup:
			generate_shortcut_group(node, statement.shortcutOptionGroup)
		YarnGlobals.StatementTypes.Block:
			generate_block(node, statement.block.statements)
		YarnGlobals.StatementTypes.IfStatement:
			generate_if(node, statement.ifStatement)
		YarnGlobals.StatementTypes.JumpStatement:
			generate_jump(node, statement.jumpStatement)
		YarnGlobals.StatementTypes.AssignmentStatement:
			generate_assignment(node, statement.assignment)
		YarnGlobals.StatementTypes.Line:
			generate_line(node, statement, statement.line)
		YarnGlobals.StatementTypes.DeclarationStatement:
			pass
		_:
			error = ERR_COMPILATION_FAILED
			printerr("illegal statement type [%s]- could not generate code" % YarnGlobals.get_statement_type_name(statement.type))

	pass


#compile instructions for custom commands
func generate_custom_command(node, command):
	#print("generating custom command")
	#can evaluate command
	if command.expression != null:
		generate_expression(node, command.expression)
	else:
		var commandString = command.clientCommand
		emit(YarnGlobals.ByteCode.RunCommand, node, [Operand.new(commandString)])


#compile instructions for linetags and use them
# \#line:number
func generate_line(node, statement, line):
	#giving me a LineNoda
	#              - line_text : String
	#              - substitutions (inline_Expressions) : Array

	var expressionCount = line.substitutions.size()

	while !line.substitutions.is_empty():
		var inlineExpression = line.substitutions.pop_back()
		generate_expression(node, inlineExpression.expression)

	var num: String = register_string(
		line.line_text, node.node_name, line.lineid, statement.line_number, line.tags
	)
	emit(YarnGlobals.ByteCode.RunLine, node, [Operand.new(num), Operand.new(expressionCount)])


func generate_shortcut_group(node, shortcutGroup):
	# print("generating shortcutoptopn group")
	var end: String = register_label("group_end")

	var labels: Array = []  #String

	var optionCount: int = 0

	for option in shortcutGroup.options:
		var opDestination: String = register_label("option_%s" % [optionCount + 1])
		labels.append(opDestination)

		var endofClause: String = ""

		if option.condition != null:
			endofClause = register_label("conditional_%s" % optionCount)
			generate_expression(node, option.condition)
			emit(YarnGlobals.ByteCode.JumpIfFalse, node, [Operand.new(endofClause)])

		var expressionCount = option.line.substitutions.size()

		while !option.line.substitutions.is_empty():
			var inlineExpression = option.line.substitutions.pop_back()
			generate_expression(node, inlineExpression.expression)
		var labelLineId: String = option.line.lineid
		var labelStringId: String = register_string(
			option.line.line_text, node.node_name, labelLineId, option.line_number, node.tags
		)

		emit(
			YarnGlobals.ByteCode.AddOption,
			node,
			[Operand.new(labelStringId), Operand.new(opDestination), Operand.new(expressionCount)]
		)

		if option.condition != null:
			emit(YarnGlobals.ByteCode.Label, node, [Operand.new(endofClause)])
			emit(YarnGlobals.ByteCode.Pop, node)

		optionCount += 1

	emit(YarnGlobals.ByteCode.ShowOptions, node)
	emit(YarnGlobals.ByteCode.Jump, node)

	optionCount = 0

	for option in shortcutGroup.options:
		emit(YarnGlobals.ByteCode.Label, node, [Operand.new(labels[optionCount])])

		if option.node != null:
			generate_block(node, option.node.statements)
		emit(YarnGlobals.ByteCode.JumpTo, node, [Operand.new(end)])
		optionCount += 1

	#end of option group
	emit(YarnGlobals.ByteCode.Label, node, [Operand.new(end)])
	#clean up
	emit(YarnGlobals.ByteCode.Pop, node)


#compile instructions for block
#blocks are just groups of statements
func generate_block(node, statements: Array = []):
	# print("generating block")
	if !statements.is_empty():
		for statement in statements:
			generate_statement(node, statement)


#compile if branching instructions
func generate_if(node, ifStatement):
	# print("generating if")
	#jump to label @ end of every clause
	var endif: String = register_label("endif")

	for clause in ifStatement.clauses:
		var endClause: String = register_label("skip_clause")

		if clause.expression != null:
			generate_expression(node, clause.expression)
			emit(YarnGlobals.ByteCode.JumpIfFalse, node, [Operand.new(endClause)])

		generate_block(node, clause.statements)
		emit(YarnGlobals.ByteCode.JumpTo, node, [Operand.new(endif)])

		if clause.expression != null:
			emit(YarnGlobals.ByteCode.Label, node, [Operand.new(endClause)])

		if clause.expression != null:
			emit(YarnGlobals.ByteCode.Pop, node)

	emit(YarnGlobals.ByteCode.Label, node, [Operand.new(endif)])


#compile instructions for options
func generate_jump(node, jump_statement: YarnParser.JumpStatement):
	# print("generating option")

	if (jump_statement.destination_expression != null):
		generate_expression(node, jump_statement.destination_expression)
		emit(YarnGlobals.ByteCode.RunNode, node) 
	else:
		var destination: String = jump_statement.destination
		emit(YarnGlobals.ByteCode.RunNode, node, [Operand.new(destination)])


#compile instructions for assigning values
func generate_assignment(node, assignment):
	# print("generating assign")
	#assignment
	if assignment.operation == YarnGlobals.TokenType.EqualToOrAssign:
		#evaluate the expression to a value for the stack
		generate_expression(node, assignment.value)
	else:
		#this is combined op
		#get value of var
		emit(YarnGlobals.ByteCode.PushVariable, node, [assignment.destination])

		#evaluate the expression and push value to stack
		generate_expression(node, assignment.value)

		#stack contains oldvalue and result

		match assignment.operation:
			YarnGlobals.TokenType.AddAssign:
				emit(
					YarnGlobals.ByteCode.CallFunc,
					node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.Add))]
				)
			YarnGlobals.TokenType.MinusAssign:
				emit(
					YarnGlobals.ByteCode.CallFunc,
					node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.Minus))]
				)
			YarnGlobals.TokenType.MultiplyAssign:
				emit(
					YarnGlobals.ByteCode.CallFunc,
					node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.MultiplyAssign))]
				)
			YarnGlobals.TokenType.DivideAssign:
				emit(
					YarnGlobals.ByteCode.CallFunc,
					node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.DivideAssign))]
				)
			_:
				printerr("Invalid assignment operator.")  #FIXME add more error information
				error = ERR_INVALID_DATA

	#stack contains destination value
	#store the top of the stack in variable
	emit(YarnGlobals.ByteCode.StoreVariable, node, [Operand.new(assignment.destination)])

	#clean stack
	emit(YarnGlobals.ByteCode.Pop, node)


#compile expression instructions
func generate_expression(node, expression):
	# print("generating expression")
	#expression = value || func call
	match expression.type:
		YarnGlobals.ExpressionType.Value:
			generate_value(node, expression.value)
		YarnGlobals.ExpressionType.FunctionCall:
			#eval all parameters
			for param in expression.params:
				generate_expression(node, param)

			#put the num of of params to stack
			emit(YarnGlobals.ByteCode.PushNumber, node, [Operand.new(expression.params.size())])

			#call function
			emit(YarnGlobals.ByteCode.CallFunc, node, [Operand.new(expression.function)])
		_:
			printerr("Unable to generate expression while compiling")
			error = ERR_INVALID_DATA

	pass


#compile value instructions
func generate_value(node, value):
	# print("generating value")
	#push value to stack
	match value.value.type:
		YarnGlobals.ValueType.Number:
			emit(YarnGlobals.ByteCode.PushNumber, node, [Operand.new(value.value.as_number())])
		YarnGlobals.ValueType.Str:
			var id: String = register_string(
				value.value.as_string(), node.node_name, "", value.lineNumber, []
			)
			emit(YarnGlobals.ByteCode.PushString, node, [Operand.new(id)])
		YarnGlobals.ValueType.Boolean:
			emit(YarnGlobals.ByteCode.PushBool, node, [Operand.new(value.value.as_bool())])
		YarnGlobals.ValueType.Variable:
			emit(YarnGlobals.ByteCode.PushVariable, node, [Operand.new(value.value.variable)])
		YarnGlobals.ValueType.Nullean:
			emit(YarnGlobals.ByteCode.PushNull, node)
		_:
			printerr("Unrecognized valuenode type: %s" % value.value.type)
			error = ERR_INVALID_DATA


#get the error flags
func get_errors() -> int:
	return _errors


#get the last error code reported
func get_last_error() -> int:
	return _last_error


func clear_errors() -> void:
	_errors = NO_ERROR
	_last_error = NO_ERROR


# func emit_error(error : int)->void:
# 	_last_error = error
# 	_errors |= _last_error


static func print_tokens(node_name: String, tokens: Array = []):
	var list: PackedStringArray = []
	for token in tokens:
		list.append(
			(
				"\t [%14s] %s (%s l:%s c:%s)\n"
				% [
					token.lexer_state,
					YarnGlobals.token_name(token.type),
					token.value,
					token.line_number, 
					token.column 
				]
			)
		)
	print("Node[%s] Tokens:" % node_name)
	print("".join(list))
