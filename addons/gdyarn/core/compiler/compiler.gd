# const YarnGlobals = preload("res://addons/gdyarn/autoloads/execution_states.gd")

const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")
const LineInfo = preload("res://addons/gdyarn/core/program/yarn_line.gd")
const YarnNode = preload("res://addons/gdyarn/core/program/yarn_node.gd")
const Instruction = preload("res://addons/gdyarn/core/program/instruction.gd")
const YarnProgram = preload("res://addons/gdyarn/core/program/program.gd")
const Operand = preload("res://addons/gdyarn/core/program/operand.gd")


#patterns
const INVALIDTITLENAME = "[\\[<>\\]{}\\|:\\s#\\$]"

#ERROR Codes
const NO_ERROR : int = 0x00
const LEXER_FAILURE : int = 0x01
const PARSER_FAILURE : int = 0x02
const INVALID_HEADER : int = 0x04
const DUPLICATE_NODES_IN_PROGRAM : int = 0x08
const ERR_COMPILATION_FAILED : int = 0x10

var _errors : int
var _lastError : int

#-----Class vars
var _currentNode : YarnNode
var _rawText : bool
var _program : YarnProgram
var _fileName : String
var _containsImplicitStringTags : bool
var _labelCount : int = 0

var error = OK

#<String, LineInfo>
var _stringTable : Dictionary = {}
var _stringCount : int = 0
#<int, YarnGlobals.TokenType>
var _tokens : Dictionary = {}

static func compile_string(source:String,filename,program:YarnProgram,showTokens:bool = false,printTree : bool = false)->int:
	
	var Parser = load("res://addons/gdyarn/core/compiler/parser.gd")
	var Compiler = load("res://addons/gdyarn/core/compiler/compiler.gd")

	var compiler = Compiler.new()
	compiler._fileName = filename


	#--------------Nodes
	var headerSep : RegEx = RegEx.new()
	headerSep.compile("---(\r\n|\r|\n)")
	var headerProperty : RegEx = RegEx.new()
	headerProperty.compile("(?<field>.*): *(?<value>.*)")


	#check for atleast one node start
	if !headerSep.search(source):
		printerr("Error parsing yarn input : No headers found")
		return ERR_FILE_UNRECOGNIZED

	var lineNumber: int = 0 
	
	var sourceLines : Array = source.split('\n',true)
	# printerr("source lines %s" % sourceLines.size())
	for i in range(sourceLines.size()):
		sourceLines[i] = sourceLines[i].strip_edges(false,true)

	var parsedNodes : Array = []
	
	# print("sourceLines:")
	# for line in sourceLines:
	# 	print(line)

	while lineNumber < sourceLines.size():
		
		var title : String 
		var body : String

		#get title
		while true:
			var line : String = sourceLines[lineNumber]
			# print(sourceLines[lineNumber])
			lineNumber+=1
			
			if !line.empty():
				var result = headerProperty.search(line)
				if result != null : 
					var field : String = result.get_string("field")
					var value : String = result.get_string("value")

					if field == "title":
						title = value

			if(lineNumber >= sourceLines.size() || sourceLines[lineNumber] == "---"):
				break

		
		lineNumber+=1
		#past header
		var bodyLines : PoolStringArray = []
		
		while lineNumber < sourceLines.size() && sourceLines[lineNumber]!="===":
			bodyLines.append(sourceLines[lineNumber])
			lineNumber+=1

		lineNumber+=1

		body = bodyLines.join('\n')
		var lexer = Lexer.new()

		var tokens : Array = lexer.tokenize(body,0)
		if lexer.error != OK:
			printerr("Failed to tokenize the Node[%s] in file: %s."%[title,filename])
			return lexer.error

		if showTokens:
			print_tokens(title,tokens)
		var parser = Parser.new(tokens)

		var parserNode = parser.parse_node(title)
		if parser.error != OK:
			printerr("Failed to parse Node[%s] in file: %s."%[title,filename])
			return parser.error

		if printTree:
			print(parserNode.tree_string(0))

		parsedNodes.append(parserNode)
		while lineNumber < sourceLines.size() && sourceLines[lineNumber].empty():
			lineNumber+=1

	#--- End parsing nodes---


	#compile nodes
	for node in parsedNodes:
		compiler.compile_node(program,node)
		if compiler.error != OK:
			printerr("Failed to compile Node[%s] in file: %s." %[node.name,filename])
			return compiler.error

	merge_dir(program.yarnStrings,compiler._stringTable)
			

	return OK


static func merge_dir(target, patch):
		for key in patch.keys():
			target[key] = patch[key]

func compile_node(program:YarnProgram,parsedNode)->void:
	if program.yarnNodes.has(parsedNode.name):
		# emit_error(DUPLICATE_NODES_IN_PROGRAM)
		error = ERR_ALREADY_EXISTS
		printerr("Duplicate node in program: %s"%parsedNode.name)
	else:
		var nodeCompiled : YarnNode = YarnNode.new()

		nodeCompiled.nodeName = parsedNode.name
		nodeCompiled.tags = parsedNode.tags

		#raw text
		if parsedNode.source != null && !parsedNode.source.empty():
			nodeCompiled.sourceId = register_string(parsedNode.source,parsedNode.name,
			"line:"+parsedNode.name, 0, [])
		else:
			#compile node
			var startLabel : String = register_label()
			emit(YarnGlobals.ByteCode.Label,nodeCompiled,[Operand.new(startLabel)])

			for statement in parsedNode.statements:
				generate_statement(nodeCompiled,statement)

			
			#add options
			#todo: add parser flag

			# var hasOptions : bool = false

			# for instruction in nodeCompiled.instructions :
			# 	if instruction.operation == YarnGlobals.ByteCode.AddOption:
			# 		hasOptions = true
			# 	if instruction.operation == YarnGlobals.ByteCode.ShowOptions:
			# 		hasOptions = false

			#if no lingering options we stop
			if !parsedNode.hasOptions:
				# printerr("no options found")
				emit(YarnGlobals.ByteCode.Stop,nodeCompiled)
			else:

				# printerr("found options in node %s "% parsedNode.name)
				#otherwise show and jump to selected
				emit(YarnGlobals.ByteCode.ShowOptions,nodeCompiled)
				emit(YarnGlobals.ByteCode.RunNode,nodeCompiled)

			
		program.yarnNodes[nodeCompiled.nodeName] = nodeCompiled

		


func register_string(text:String,nodeName:String,id:String="",lineNumber:int=-1,tags:PoolStringArray=[])->String:
	var lineIdUsed : String

	var implicit : bool

	if id.empty():
		lineIdUsed = "%s-%s-%d" % [self._fileName.get_file(),nodeName,self._stringCount]
		self._stringCount+=1

		#use this when we generate implicit tags
		#they are not saved and are generated
		#aka dummy tags that change on each compilation
		_containsImplicitStringTags = true

		implicit = true
	else : 
		lineIdUsed = id
		implicit = false

	var stringInfo : LineInfo = LineInfo.new(text,nodeName,lineNumber,_fileName.get_file(),implicit,tags)
	#add to string table and return id
	self._stringTable[lineIdUsed] = stringInfo

	return lineIdUsed

func register_label(comment:String="")->String:
	_labelCount+=1
	return  "L%s%s" %[ _labelCount , comment]

func emit(bytecode,node:YarnNode=_currentNode,operands:Array=[]):
	var instruction : Instruction = Instruction.new(null)
	instruction.operation = bytecode
	instruction.operands = operands
	# print("emitting instruction to %s"%node.nodeName)

	if(node == null):
		printerr("trying to emit to null node with byteCode: %s"%bytecode)
		error = ERR_INVALID_PARAMETER
		return;
	node.instructions.append(instruction)
	if bytecode == YarnGlobals.ByteCode.Label : 
		#add to label table
		node.labels[instruction.operands[0].value] = node.instructions.size()-1
	pass


func get_string_tokens()->Array:
	return []

#compile header
func generate_header():
	pass

#compile instructions for statements
#this will walk through all child branches
#of the parse tree
func generate_statement(node,statement):
	# print("generating statement")
	match statement.type:
		YarnGlobals.StatementTypes.CustomCommand:
			generate_custom_command(node,statement.customCommand)
		YarnGlobals.StatementTypes.ShortcutOptionGroup:
			generate_shortcut_group(node,statement.shortcutOptionGroup)
		YarnGlobals.StatementTypes.Block:
			generate_block(node,statement.block.statements)
		YarnGlobals.StatementTypes.IfStatement:
			generate_if(node,statement.ifStatement)
		YarnGlobals.StatementTypes.OptionStatement:
			generate_option(node,statement.optionStatement)
		YarnGlobals.StatementTypes.AssignmentStatement:
			generate_assignment(node,statement.assignment)
		YarnGlobals.StatementTypes.Line:
			generate_line(node,statement,statement.line)
		_:
			error = ERR_COMPILATION_FAILED
			printerr("illegal statement type [%s]- could not generate code" % statement.type)

	pass

#compile instructions for custom commands
func generate_custom_command(node,command):
	#print("generating custom command")
	#can evaluate command
	if command.expression != null:
		generate_expression(node,command.expression)
	else:
		var commandString = command.clientCommand
		emit(YarnGlobals.ByteCode.RunCommand,node,[Operand.new(commandString)])
		

#compile instructions for linetags and use them 
# \#line:number
func generate_line(node,statement,line):
	#giving me a LineNoda
	#              - line_text : String
	#              - substitutions (inline_Expressions) : Array

	var expressionCount = line.substitutions.size()

	while !line.substitutions.empty():
		var inlineExpression = line.substitutions.pop_back()
		generate_expression(node,inlineExpression.expression)
	
	var num : String = register_string(line.line_text,node.nodeName,line.lineid,statement.lineNumber,line.tags);
	emit(YarnGlobals.ByteCode.RunLine,node,[Operand.new(num),Operand.new(expressionCount)])


func generate_shortcut_group(node,shortcutGroup):
	# print("generating shortcutoptopn group")
	var end : String = register_label("group_end")

	var labels : Array = []#String

	var optionCount : int = 0

	for option in shortcutGroup.options:
		var opDestination : String = register_label("option_%s"%[optionCount+1])
		labels.append(opDestination)

		var endofClause : String = ""

		if option.condition != null :
			endofClause = register_label("conditional_%s"%optionCount)
			generate_expression(node,option.condition)
			emit(YarnGlobals.ByteCode.JumpIfFalse,node,[Operand.new(endofClause)])

		var expressionCount = option.line.substitutions.size()

		while !option.line.substitutions.empty():
			var inlineExpression = option.line.substitutions.pop_back()
			generate_expression(node,inlineExpression.expression)
		var labelLineId : String  = option.line.lineid
		var labelStringId : String = register_string(option.line.line_text,node.nodeName,
			labelLineId,option.lineNumber,node.tags)
		
		emit(YarnGlobals.ByteCode.AddOption,node,[Operand.new(labelStringId),Operand.new(opDestination), Operand.new(expressionCount)])

		if option.condition != null :
			emit(YarnGlobals.ByteCode.Label,node,[Operand.new(endofClause)])
			emit(YarnGlobals.ByteCode.Pop,node)

		optionCount+=1
	
	emit(YarnGlobals.ByteCode.ShowOptions,node)
	emit(YarnGlobals.ByteCode.Jump,node)

	optionCount = 0

	for option in shortcutGroup.options:
		emit(YarnGlobals.ByteCode.Label,node,[Operand.new(labels[optionCount])])

		if option.node != null :
			generate_block(node,option.node.statements)
		emit(YarnGlobals.ByteCode.JumpTo,node,[Operand.new(end)])
		optionCount+=1

	#end of option group
	emit(YarnGlobals.ByteCode.Label,node,[Operand.new(end)])
	#clean up
	emit(YarnGlobals.ByteCode.Pop,node)



#compile instructions for block
#blocks are just groups of statements
func generate_block(node,statements:Array=[]):
	# print("generating block")
	if !statements.empty():
		for statement in statements:
			generate_statement(node,statement) 
	

#compile if branching instructions
func generate_if(node,ifStatement):
	# print("generating if")
	#jump to label @ end of every clause
	var endif : String = register_label("endif")

	for clause in ifStatement.clauses:
		var endClause : String = register_label("skip_clause")

		if clause.expression!=null:	
			generate_expression(node,clause.expression)
			emit(YarnGlobals.ByteCode.JumpIfFalse,node,[Operand.new(endClause)])
		
		generate_block(node,clause.statements)
		emit(YarnGlobals.ByteCode.JumpTo,node,[Operand.new(endif)])

		if clause.expression!=null:
			emit(YarnGlobals.ByteCode.Label,node,[Operand.new(endClause)])

		if clause.expression!=null:
			emit(YarnGlobals.ByteCode.Pop,node)

		
	emit(YarnGlobals.ByteCode.Label,node,[Operand.new(endif)])


#compile instructions for options
func generate_option(node,option):
	# print("generating option")
	var destination : String = option.destination

	if !option.line:
		#jump to another node
		emit(YarnGlobals.ByteCode.RunNode,node,[Operand.new(destination)])
	else : 
		var lineID : String = option.line.lineid
		var stringID = register_string(option.line.line_text,node.nodeName,lineID,option.lineNumber,option.line.tags)

		var expressionCount = option.line.substitutions.size()

		while !option.line.substitutions.empty():
			var inLineExpression = option.line.substitutions.pop_back()
			generate_expression(node,inLineExpression.expression)

		emit(YarnGlobals.ByteCode.AddOption,node,[Operand.new(stringID),Operand.new(destination), Operand.new(expressionCount)])


#compile instructions for assigning values
func generate_assignment(node,assignment):
	# print("generating assign")
	#assignment
	if assignment.operation == YarnGlobals.TokenType.EqualToOrAssign:
		#evaluate the expression to a value for the stack
		generate_expression(node,assignment.value)
	else : 
		#this is combined op
		#get value of var
		emit(YarnGlobals.ByteCode.PushVariable,node,[assignment.destination])

		#evaluate the expression and push value to stack
		generate_expression(node,assignment.value)

		#stack contains oldvalue and result

		match assignment.operation:
			YarnGlobals.TokenType.AddAssign:
				emit(YarnGlobals.ByteCode.CallFunc,node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.Add))])
			YarnGlobals.TokenType.MinusAssign:
				emit(YarnGlobals.ByteCode.CallFunc,node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.Minus))])
			YarnGlobals.TokenType.MultiplyAssign:
				emit(YarnGlobals.ByteCode.CallFunc,node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.MultiplyAssign))])
			YarnGlobals.TokenType.DivideAssign:
				emit(YarnGlobals.ByteCode.CallFunc,node,
					[Operand.new(YarnGlobals.token_name(YarnGlobals.TokenType.DivideAssign))])
			_:
				printerr("Invalid assignment operator.") #FIXME add more error information
				error = ERR_INVALID_DATA

	#stack contains destination value
	#store the top of the stack in variable
	emit(YarnGlobals.ByteCode.StoreVariable,node,[Operand.new(assignment.destination)])

	#clean stack
	emit(YarnGlobals.ByteCode.Pop,node)


#compile expression instructions
func generate_expression(node,expression):
	# print("generating expression")
	#expression = value || func call
	match expression.type:
		YarnGlobals.ExpressionType.Value:
			generate_value(node,expression.value)
		YarnGlobals.ExpressionType.FunctionCall:
			#eval all parameters
			for param in expression.params:
				generate_expression(node,param)
			
			#put the num of of params to stack
			emit(YarnGlobals.ByteCode.PushNumber,node,[Operand.new(expression.params.size())])

			#call function
			emit(YarnGlobals.ByteCode.CallFunc,node,[Operand.new(expression.function)])
		_:
			printerr("Unable to generate expression while compiling")
			error = ERR_INVALID_DATA

			
	pass

#compile value instructions
func generate_value(node,value):
	# print("generating value")
	#push value to stack
	match value.value.type:
		YarnGlobals.ValueType.Number:
			emit(YarnGlobals.ByteCode.PushNumber,node,[Operand.new(value.value.as_number())])
		YarnGlobals.ValueType.Str:
			var id : String = register_string(value.value.as_string(),
				node.nodeName,"",value.lineNumber,[])
			emit(YarnGlobals.ByteCode.PushString,node,[Operand.new(id)])
		YarnGlobals.ValueType.Boolean:
			emit(YarnGlobals.ByteCode.PushBool,node,[Operand.new(value.value.as_bool())])
		YarnGlobals.ValueType.Variable:
			emit(YarnGlobals.ByteCode.PushVariable,node,[Operand.new(value.value.variable)])
		YarnGlobals.ValueType.Nullean:
			emit(YarnGlobals.ByteCode.PushNull,node)
		_:
			printerr("Unrecognized valuenode type: %s" % value.value.type)
			error = ERR_INVALID_DATA


#get the error flags
func get_errors()->int:
	return _errors

#get the last error code reported
func get_last_error()->int:
	return _lastError

func clear_errors()->void:
	_errors = NO_ERROR
	_lastError = NO_ERROR

# func emit_error(error : int)->void:
# 	_lastError = error
# 	_errors |= _lastError


static func print_tokens(nodeName : String,tokens:Array=[]):
	var list : PoolStringArray = []
	for token in tokens:
		list.append("\t [%14s] %s (%s line %s)\n"%[token.lexerState,YarnGlobals.get_script().token_type_name(token.type),token.value,token.lineNumber])
	print("Node[%s] Tokens:" % nodeName)
	print(list.join("")) 
