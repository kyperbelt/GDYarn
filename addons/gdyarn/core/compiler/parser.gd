
# const YarnGlobals = preload("res://addons/gdyarn/autoloads/execution_states.gd")
const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")


var _tokens : Array = []#token
var error = OK
var currentNodeName = "Start"

func _init(tokens):
	self._tokens = tokens
	
#how to handle operations
enum Associativity {
	Left,Right,None
}

func parse_node(name : String = "Start")->YarnNode:
	currentNodeName = name
	return YarnNode.new(name,null,self)

func next_symbol_is(validTypes:Array, line : int = -1)->bool:
	var type = self._tokens.front().type
	for validType in validTypes:
		if type == validType && (line == -1 || line == self._tokens.front().lineNumber):
			return true
	return false

#look ahead for `<<` and `else`
func next_symbols_are(validTypes:Array,line : int = -1)->bool:
	var temp = []+_tokens
	for type in validTypes:
		if temp.pop_front().type != type:
			return false
	return (line == -1 || line == self._tokens.front().lineNumber)

func expect_symbol(tokenTypes:Array = [])->Lexer.Token:
	var t = self._tokens.pop_front() as Lexer.Token
	var size = tokenTypes.size()
	
	if size == 0:
		if t.type == YarnGlobals.TokenType.EndOfInput:
			printerr("unexpected end of input")
			error = ERR_INVALID_DATA
			return null
		return t

	for type in tokenTypes:
		if t.type == type:
			return t
	var expectedTypes:String = " "

	for tokenType in tokenTypes:
		expectedTypes+=YarnGlobals.get_script().token_type_name(tokenType) +" "
	# expectedTypes+= ""


	printerr("unexpected token: Expexted [%s] but got [ %s ] @(%s,%s)"% [expectedTypes,YarnGlobals.get_script().token_type_name(t.type),t.lineNumber,t.column])
	error = ERR_INVALID_DATA
	return null

# static func tab(indentLevel : int , input : String,newLine : bool = true)->String:
# 	return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")])

func tokens()->Array:
	return _tokens

class ParseNode:
	var parent : ParseNode
	var lineNumber : int
	var tags : Array#<String>

	func _init(parent:ParseNode,parser):
		self.parent = parent
		var tokens : Array = parser.tokens() as Array
		if tokens.size() > 0:
			lineNumber = tokens.front().lineNumber
		else:
			lineNumber = -1
		tags = []

	func tree_string(indentLevel : int)->String:
		return "NotImplemented"

	func tags_to_string(indentLevel : int)->String:
		return "%s" % "TAGS<tags_to_string>NOTIMPLEMENTED"

	func get_node_parent()->YarnNode:
		var node = self
		while node != null:
			if node.has_method("yarn_node"):
				return node as YarnNode
			node = node.parent
		return null

	func tab(indentLevel : int , input : String,newLine : bool = true)->String:
		var tabPrecursor = ""
		var indentSpacing= 3
		for i in range(indentLevel):
			tabPrecursor+="|%*s"%[indentSpacing,""]

		return ("%*s %s%s"% [+indentLevel,tabPrecursor,input,("" if !newLine else "\n")])
		
	
	func set_parent(parent):
		self.parent = parent

#this is a Yarn Node - contains all the text
class YarnNode extends ParseNode:

	var name : String
	var source : String
	
	var editorNodeTags : Array =[]#tags defined in node header
	var statements : Array = []# Statement
	var hasOptions := false

	func _init(name:String,parent:ParseNode,parser).(parent,parser):

		self.name = name
		while (parser.tokens().size() > 0 && 
			  !parser.next_symbol_is([YarnGlobals.TokenType.Dedent,YarnGlobals.TokenType.EndOfInput]) &&
			  parser.error == OK):
			statements.append(Statement.new(self,parser))
			#print(statements.size())

	# WARNING: DO NOT REMOVE SINCE THIS IS THE WAY WE CHECK CLASS
	func yarn_node():
		pass

	func tree_string(indentLevel : int)->String:
		
		var info : PoolStringArray = []

		for statement in statements:
			info.append(statement.tree_string(indentLevel +1))

		#print("printing TREEEEEEEEEEEEE")

		return info.join("")
	
# UNIMPLEMENTED .
# might be worth handling this through the parser instead as a pre-process step
# we handle header information before we beign parsing content
class Header extends ParseNode:
	pass

class InlineExpression extends ParseNode:
	var expression : ExpressionNode

	func _init(parent:ParseNode, parser).(parent,parser):
		parser.expect_symbol([YarnGlobals.TokenType.ExpressionFunctionStart])
		expression = ExpressionNode.parse(self,parser);
		parser.expect_symbol([YarnGlobals.TokenType.ExpressionFunctionEnd])

	static func can_parse(parser):
		return parser.next_symbol_is([YarnGlobals.TokenType.ExpressionFunctionStart])

	#TODO make tree string nicer
	#     with added information about the expression
	func tree_string(indentLevel : int)->String:
		return "InlineExpression:"



class FormatFunction extends ParseNode:

	# returns a format_text string as [ name "{0}" key1="value1" key2="value2" ]
	var format_text : String = ""
	var expression_value : InlineExpression

	func _init(parent:ParseNode, parser,expressionCount:int).(parent,parser):
		format_text="["
		parser.expect_symbol([YarnGlobals.TokenType.FormatFunctionStart])

		while !parser.next_symbol_is([YarnGlobals.TokenType.FormatFunctionEnd]):
			if parser.next_symbol_is([YarnGlobals.TokenType.Text]):
				format_text += parser.expect_symbol().value

			if InlineExpression.can_parse(parser):
				expression_value = InlineExpression.new(self, parser)
				format_text +=" \"{%d}\" " % expressionCount
		parser.expect_symbol()
		format_text+="]"

	static func can_parse(parser):
		return parser.next_symbol_is([YarnGlobals.TokenType.FormatFunctionStart])

	#TODO Make format prettier and add more information
	func tree_string(indentLevel : int)->String:
		return "FormatFucntion"

class LineNode extends ParseNode:
	var line_text : String
	#TODO: FIXME: right now we are putting the formatfunctions and inline expressions in the same
	#             list but if at some point we want to stronly type our sub list we need to make a new
	#             parse node that can have either an InlineExpression or a FunctionFormat
	#             .. This is a consideration for Godot4.x
	var substitutions : Array = [] # of type <InlineExpression |& FormatFunction>
	var lineid    : String = ""
	var lineTags  : PoolStringArray  = []

	# NOTE: If format function an inline functions are both present
	# returns a line in the format "Some text {0} and some other {1}[format "{2}" key="value" key="value"]"

	func _init(parent:ParseNode,parser).(parent,parser):

		while (parser.next_symbol_is([YarnGlobals.TokenType.FormatFunctionStart,YarnGlobals.TokenType.ExpressionFunctionStart,
			YarnGlobals.TokenType.Text, YarnGlobals.TokenType.TagMarker]) ):

			if FormatFunction.can_parse(parser):
				var ff = FormatFunction.new(self,parser,substitutions.size())
				if ff.expression_value != null:
					substitutions.append(ff.expression_value)
				line_text+=ff.format_text
			elif InlineExpression.can_parse(parser):
				var ie = InlineExpression.new(self,parser)
				line_text+="{%d}" % substitutions.size()
				substitutions.append(ie)
			elif parser.next_symbols_are([YarnGlobals.TokenType.TagMarker,YarnGlobals.TokenType.Identifier]):
				parser.expect_symbol()
				var tagToken = parser.expect_symbol([ YarnGlobals.TokenType.Identifier ])
				if tagToken.value.begins_with("line:"):
					if lineid.empty():
						lineid = tagToken.value
					else:
						printerr("Too many lineTags @[%s:%d]" %[parser.currentNodeName, tagToken.lineNumber])
						return
				else:
					tags.append(tagToken.value)


			else:

				var tt = parser.expect_symbol()
				if tt.lineNumber == lineNumber && !(tt.type == YarnGlobals.TokenType.BeginCommand):
					line_text += tt.value
				else:
					parser._tokens.push_front(tt)
					break


	func tree_string(indentLevel : int)->String:
		return "Line: (%s)[%d]" %[line_text,substitutions.size()]

class Statement extends ParseNode:
	var Type = YarnGlobals.StatementTypes

	var type : int
	var block : Block
	var ifStatement : IfStatement
	var optionStatement : OptionStatement
	var assignment : Assignment 
	var shortcutOptionGroup : ShortcutOptionGroup
	var customCommand : CustomCommand
	var line : LineNode

	func _init(parent:ParseNode,parser).(parent,parser):
		if parser.error != OK:
			return

		if Block.can_parse(parser):
			# printerr("parsing a block")
			block  = Block.new(self,parser)
			type = Type.Block
		elif IfStatement.can_parse(parser):
			# printerr("parsing if statement")
			ifStatement = IfStatement.new(self,parser)
			type = Type.IfStatement
		elif OptionStatement.can_parse(parser):
			# printerr("parsing an option statemetn")
			optionStatement = OptionStatement.new(self,parser)
			type = Type.OptionStatement
		elif Assignment.can_parse(parser):
			assignment = Assignment.new(self,parser)
			type = Type.AssignmentStatement
		elif ShortcutOptionGroup.can_parse(parser):
			# printerr("parsing shortcut option group")
			shortcutOptionGroup = ShortcutOptionGroup.new(self,parser)
			type = Type.ShortcutOptionGroup
		elif CustomCommand.can_parse(parser):
			# printerr("parsing commands")
			customCommand = CustomCommand.new(self,parser)
			type = Type.CustomCommand
		elif parser.next_symbol_is([YarnGlobals.TokenType.Text]):
			# line = parser.expect_symbol([YarnGlobals.TokenType.Text]).value
			# type = Type.Line
			line = LineNode.new(self,parser)
			type = Type.Line
			# printerr("new line found == ", line.line_text)
			# parser.expect_symbol([YarnGlobals.TokenType.EndOfLine])
		else:
			printerr("expected a statement but got %s instead. (probably an inbalanced if statement)" % parser.tokens().front()._to_string())
			parser.error = ERR_PARSE_ERROR
			return
		
		var tags : Array = []

		# while parser.next_symbol_is([YarnGlobals.TokenType.TagMarker]):
		# 	parser.expect_symbol([YarnGlobals.TokenType.TagMarker])
		# 	var tag : String = parser.expect_symbol([YarnGlobals.TokenType.Identifier]).value
		# 	tags.append(tag)

		# if(tags.size()>0):
		# 	self.tags = tags

	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []

		match type : 
			Type.Block:
				info.append(block.tree_string(indentLevel))
			Type.IfStatement:
				info.append(ifStatement.tree_string(indentLevel))
			Type.AssignmentStatement:
				info.append(assignment.tree_string(indentLevel))
			Type.OptionStatement:
				info.append(optionStatement.tree_string(indentLevel))
			Type.ShortcutOptionGroup:
				info.append(shortcutOptionGroup.tree_string(indentLevel))
			Type.CustomCommand:
				info.append(customCommand.tree_string(indentLevel))
			Type.Line:
				info.append(tab(indentLevel,line.tree_string(indentLevel)))
			_:
				printerr("cannot print statement")

		#print("statement --")
		
		return info.join("")
		
	

class CustomCommand extends ParseNode:

	enum Type {
		Expression,ClientCommand
	}

	var type : int
	var expression : ExpressionNode
	var clientCommand : String

	func _init(parent:ParseNode,parser).(parent,parser):
		parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])

		var commandTokens = []
		commandTokens.append(parser.expect_symbol())

		while !parser.next_symbol_is([YarnGlobals.TokenType.EndCommand]):
			commandTokens.append(parser.expect_symbol())

		parser.expect_symbol([YarnGlobals.TokenType.EndCommand])
		
		#if first token is identifier and second is leftt parenthesis
		#evaluate as function
		if (commandTokens.size() > 1 && commandTokens[0].type == YarnGlobals.TokenType.Identifier 
			&& commandTokens[1].type == YarnGlobals.TokenType.LeftParen):
			var p = get_script().new(commandTokens,parser.library)
			var expression : ExpressionNode = ExpressionNode.parse(self,p)
			type = Type.Expression
			self.expression = expression
		else:
			#otherwise evaluuate command
			type = Type.ClientCommand
			self.clientCommand = commandTokens[0].value
	
	func tree_string(indentLevel : int)->String:
		match type:
			Type.Expression:
				return tab(indentLevel,"Expression: %s"% expression.tree_string(indentLevel+1))
			Type.ClientCommand:
				return tab(indentLevel,"Command: %s"%clientCommand)
		return ""
	
	static func can_parse(parser)->bool:
		return (parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.Text]) 
				|| parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.Identifier]))


	

		
class ShortcutOptionGroup extends ParseNode:
	
	var options : Array = []#ShortcutOptions

	func _init(parent:ParseNode,parser).(parent,parser):

		# parse options until there is no more
		# expect one otherwise invalid

		var sIndex : int = 1 
		options.append(ShortCutOption.new(sIndex, self, parser))
		sIndex+=1
		while parser.next_symbol_is([YarnGlobals.TokenType.ShortcutOption]):
			options.append(ShortCutOption.new(sIndex, self, parser))
			sIndex+=1
		var nameOfTopOfStack = YarnGlobals.get_script().token_type_name(parser._tokens.front().type)
		# printerr("eneded the shortcut group with a [%s] on top" % nameOfTopOfStack)

	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []

		info.append(tab(indentLevel,"Shortcut Option Group{"))

		for option in options:
			info.append(option.tree_string(indentLevel+1))

		info.append(tab(indentLevel,"}"))

		return info.join("")
	
	static func can_parse(parser)->bool:
		return parser.next_symbol_is([YarnGlobals.TokenType.ShortcutOption])
	pass

class ShortCutOption extends ParseNode:

	var line : LineNode
	var condition : ExpressionNode
	var node : YarnNode

	func _init(index:int, parent:ParseNode, parser).(parent,parser):
		# printerr("starting shortcut option parse")
		parser.expect_symbol([YarnGlobals.TokenType.ShortcutOption])
		line = LineNode.new(self,parser)
		# printerr(" this is a line found in shortcutoption : ", line.line_text)
		# parse the conditional << if $x >> when it exists
		var tags : Array = []#string


		while( parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.IfToken]) 
			|| parser.next_symbol_is([YarnGlobals.TokenType.TagMarker])):


			if parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.IfToken],lineNumber):


				parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
				parser.expect_symbol([YarnGlobals.TokenType.IfToken])
				condition = ExpressionNode.parse(self,parser)
				parser.expect_symbol([YarnGlobals.TokenType.EndCommand])
			elif parser.next_symbol_is([YarnGlobals.TokenType.TagMarker]):
				parser.expect_symbol([YarnGlobals.TokenType.TagMarker])
				var tag : String = parser.expect_symbol([YarnGlobals.TokenType.Identifier]).value;
				tags.append(tag)
			else:
				# printerr("could not find if or tag on the same line")
				break


		
		self.tags = tags

		for tag in tags:
			if tag.begins_with("line:") && line.lineid.empty():
				line.lineid = tag

		# parse remaining statements

		if parser.next_symbol_is([YarnGlobals.TokenType.Indent]):
			parser.expect_symbol([YarnGlobals.TokenType.Indent])
			node = YarnNode.new("%s.%s" %[self.get_node_parent().name ,index], self,parser)
			parser.expect_symbol([YarnGlobals.TokenType.Dedent])


	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []

		info.append(tab(indentLevel,"Option \"%s\""%line.tree_string(indentLevel)))

		if condition != null : 
			info.append(tab(indentLevel+1,"(when:"))
			info.append(condition.tree_string(indentLevel+2))
			info.append(tab(indentLevel+1,"),"))
		if node != null:
			info.append(tab(indentLevel, "{"))
			info.append(node.tree_string(indentLevel + 1));
			info.append(tab(indentLevel, "}"));

		return info.join("")

	
	
#Blocks are groups of statements with the same indent level
class Block extends ParseNode:
	
	var statements : Array = []

	func _init(parent:ParseNode, parser).(parent,parser):
		#read indent
		parser.expect_symbol([YarnGlobals.TokenType.Indent])

		#keep reading statements until we hit a dedent
		while !parser.next_symbol_is([YarnGlobals.TokenType.Dedent]):
			#parse all statements including nested blocks
			statements.append(Statement.new(self,parser))

		#clean up dedent
		parser.expect_symbol([YarnGlobals.TokenType.Dedent])
	
		
	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []

		info.append(tab(indentLevel,"Block {"))

		for statement in statements:
			info.append(statement.tree_string(indentLevel+1))

		info.append(tab(indentLevel,"}"))

		return info.join("")

	static func can_parse(parser)->bool:
		return parser.next_symbol_is([YarnGlobals.TokenType.Indent])

#Option Statements are links to other nodes
class OptionStatement extends ParseNode:
	
	var destination : String = ""
	var line : LineNode = null

	func _init(parent:ParseNode, parser).(parent,parser):

		# var strings : Array = []#string

		#parse [[LABEL
		parser.expect_symbol([YarnGlobals.TokenType.OptionStart])

		line = LineNode.new(self,parser)

		# printerr("option line[", line.line_text, "] has ", line.substitutions.size(), " subs")
		# printerr("line inside the statement : ",line.line_text)
		# var tokens := []

		# tokens.append(parser.expect_symbol([YarnGlobals.TokenType.Text]))

		#if there is a | get the next string
		if parser.next_symbol_is([YarnGlobals.TokenType.OptionDelimit]):
			parser.expect_symbol([YarnGlobals.TokenType.OptionDelimit])
			var t = parser.expect_symbol([YarnGlobals.TokenType.Text,YarnGlobals.TokenType.Identifier])
			destination = t.value
		
		if destination.empty():
			destination = line.line_text
			line = null
		else:
			get_node_parent().hasOptions = true

		parser.expect_symbol([YarnGlobals.TokenType.OptionEnd])

		if parser.next_symbol_is([YarnGlobals.TokenType.TagMarker], lineNumber):
			# TODO FIXME : give an error if there are too many line tags
			parser.expect_symbol()
			var id = parser.expect_symbol([YarnGlobals.TokenType.Identifier]).value
			if line:
				line.lineid = id

	func tree_string(indentLevel : int)->String:
		if line != null:
			return tab(indentLevel,"Option: [%s] -> %s"%[line.tree_string(0),destination])
		else:
			return tab(indentLevel,"Option: -> %s"%destination)

	static func can_parse(parser)->bool:
		return parser.next_symbol_is([YarnGlobals.TokenType.OptionStart])

class IfStatement extends ParseNode:
	
	var clauses : Array = []#Clauses

	func _init(parent:ParseNode, parser).(parent,parser):
		
		#<<if Expression>> 
		var prime : Clause = Clause.new()

		parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
		parser.expect_symbol([YarnGlobals.TokenType.IfToken])
		prime.expression = ExpressionNode.parse(self,parser)
		parser.expect_symbol([YarnGlobals.TokenType.EndCommand])

		#read statements until 'endif' or 'else' or 'else if'
		var statements : Array = []#statement
		while (!parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.EndIf])
			&& !parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.ElseToken])
			&& !parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.ElseIf])):
			
			statements.append(Statement.new(self,parser))

			#ignore dedent
			while parser.next_symbol_is([YarnGlobals.TokenType.Dedent]):
				parser.expect_symbol([YarnGlobals.TokenType.Dedent])
		
		
		prime.statements = statements
		clauses.append(prime)

		#handle all else if
		while parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.ElseIf]):
			var clauseElif : Clause = Clause.new()

			#parse condition syntax
			parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
			parser.expect_symbol([YarnGlobals.TokenType.ElseIf])
			clauseElif.expression = ExpressionNode.parse(self,parser)
			parser.expect_symbol([YarnGlobals.TokenType.EndCommand])


			var elifStatements : Array = []#statement
			while (!parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.EndIf])
				&& !parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.ElseToken])
				&& !parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.ElseIf])):
				
				elifStatements.append(Statement.new(self,parser))

				#ignore dedent
				while parser.next_symbol_is([YarnGlobals.TokenType.Dedent]):
					parser.expect_symbol([YarnGlobals.TokenType.Dedent])
			
			
			clauseElif.statements = statements
			clauses.append(clauseElif)
		
		#handle else if exists
		if (parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,
			YarnGlobals.TokenType.ElseToken,YarnGlobals.TokenType.EndCommand])):

			#expect no expression - just <<else>>
			parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
			parser.expect_symbol([YarnGlobals.TokenType.ElseToken])
			parser.expect_symbol([YarnGlobals.TokenType.EndCommand])

			#parse until hit endif
			var clauseElse : Clause = Clause.new()
			var elStatements : Array = []#statement
			while !parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.EndIf]):
				elStatements.append(Statement.new(self,parser))

			clauseElse.statements = elStatements
			clauses.append(clauseElse)

			#ignore dedent
			while parser.next_symbol_is([YarnGlobals.TokenType.Dedent]):
				parser.expect_symbol([YarnGlobals.TokenType.Dedent])

		
		#finish 
		parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
		parser.expect_symbol([YarnGlobals.TokenType.EndIf])
		parser.expect_symbol([YarnGlobals.TokenType.EndCommand])


	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []
		var first : bool = true

		for clause in clauses:
			if first:
				info.append(tab(indentLevel,"if:",true))
			elif clause.expression!=null:
				info.append(tab(indentLevel,"Else If",true))
			else:
				info.append(tab(indentLevel,"Else:",true))

			info.append(clause.tree_string(indentLevel))

		return info.join("")

	static func can_parse(parser)->bool:

		return parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.IfToken])
	pass

class ValueNode extends ParseNode:
	const Value = preload("res://addons/gdyarn/core/value.gd")
	const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")
	var value : Value

	func _init(parent:ParseNode, parser, token: Lexer.Token = null).(parent,parser):

		var t : Lexer.Token = token
		if t == null :
			parser.expect_symbol([YarnGlobals.TokenType.Number,
		YarnGlobals.TokenType.Variable,YarnGlobals.TokenType.Str]) 

		use_token(t,parser)


	#store value depedning on type
	func use_token(t:Lexer.Token,parser):

		match t.type:
			YarnGlobals.TokenType.Number:
				value = Value.new(float(t.value))
			YarnGlobals.TokenType.Str:
				value = Value.new(t.value)
			YarnGlobals.TokenType.FalseToken:
				value = Value.new(false)
			YarnGlobals.TokenType.TrueToken:
				value = Value.new(true)
			YarnGlobals.TokenType.Variable:
				value = Value.new(null)
				value.type = YarnGlobals.ValueType.Variable
				value.variable = t.value
			YarnGlobals.TokenType.NullToken:
				value = Value.new(null)
			_:
				printerr("%s, Invalid token type @[l%4d:c%4d]" % [YarnGlobals.get_script().token_type_name(t.type),t.lineNumber,t.column])
				parser.error = ERR_INVALID_DATA


	func tree_string(indentLevel : int,newline : bool = true)->String:
		return tab(indentLevel,"<%s>%s"%[YarnGlobals.get_script().get_value_type_name(value.type),value.value()],newline)

		
#Expressions encompass a wide range of things like:
# math (1 + 2 - 5 * 3 / 10 % 2)
# Identifiers
# Values
class ExpressionNode extends ParseNode:

	var type 
	var value : ValueNode
	var function : String
	var params : Array = []#ExpressionNode

	func _init(parent:ParseNode,parser,value:ValueNode,function:String="",params:Array=[]).(parent,parser):

		#no function - means value
		if value!=null:
			self.type = YarnGlobals.ExpressionType.Value
			self.value = value
		else:#function

			self.type = YarnGlobals.ExpressionType.FunctionCall
			self.function = function
			self.params = params
	
	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []
		match type:
			YarnGlobals.ExpressionType.Value:
				return value.tree_string(indentLevel)
			YarnGlobals.ExpressionType.FunctionCall:
				info.append(tab(indentLevel,"Func[%s - params(%s)]:{"%[function,params.size()]))
				for param in params:
					#print("----> %s paramSize:%s"%[(function) , params.size()])
					info.append(param.tree_string(indentLevel+1))
				info.append(tab(indentLevel,"}"))

		return info.join("")

	#using Djikstra's shunting-yard algorithm to convert
	#stream of expresions into postfix notaion, then 
	#build a tree of expressions
	static func parse(parent:ParseNode,parser)->ExpressionNode:
	

		var rpn : Array = []#token
		var opStack : Array = []#token
			
		#track params
		var funcStack : Array = []#token 
		
		var validTypes : Array = [
			YarnGlobals.TokenType.Number,
			YarnGlobals.TokenType.Variable,
			YarnGlobals.TokenType.Str,
			YarnGlobals.TokenType.LeftParen,
			YarnGlobals.TokenType.RightParen,
			YarnGlobals.TokenType.Identifier,
			YarnGlobals.TokenType.Comma,
			YarnGlobals.TokenType.TrueToken,
			YarnGlobals.TokenType.FalseToken,
			YarnGlobals.TokenType.NullToken
		]
		validTypes+=Operator.op_types()
		validTypes.invert()

		var last #Token

		#read expression content
		while parser.tokens().size() > 0 && parser.next_symbol_is(validTypes):
			var next = parser.expect_symbol(validTypes) #lexer.Token

			if(	next.type == YarnGlobals.TokenType.Variable || 
				next.type == YarnGlobals.TokenType.Number || 
				next.type == YarnGlobals.TokenType.Str || 
				next.type == YarnGlobals.TokenType.TrueToken || 
				next.type == YarnGlobals.TokenType.FalseToken || 
				next.type == YarnGlobals.TokenType.NullToken ):
				
				#output primitives
				rpn.append(next)
			elif next.type == YarnGlobals.TokenType.Identifier:
				opStack.push_back(next)
				funcStack.push_back(next)

				#next token is parent - left
				next = parser.expect_symbol([YarnGlobals.TokenType.LeftParen])
				opStack.push_back(next)
			elif next.type == YarnGlobals.TokenType.Comma:

				#resolve sub expression before moving on
				while opStack.back().type != YarnGlobals.TokenType.LeftParen:
					var p = opStack.pop_back()
					if p == null:
						printerr("unbalanced parenthesis %s " % next.name)
						parser.error = ERR_INVALID_DATA
						return null
						break
					rpn.append(p)

				
				#next token in opStack left paren
				# next parser token not allowed to be right paren or comma
				if parser.next_symbol_is([YarnGlobals.TokenType.RightParen,
					YarnGlobals.TokenType.Comma]):
					printerr("Expected Expression : %s" % parser.tokens().front().name)
					parser.error = ERR_INVALID_DATA
					return null
				
				#find the closest function on stack
				#increment parameters
				funcStack.back().paramCount+=1
				
			elif Operator.is_op(next.type):
				#this is an operator

				#if this is a minus, we need to determine if it is a
				#unary minus or a binary minus.
				#unary minus looks like this : -1
				#binary minus looks like this 2 - 3
				#thins get complex when we say stuff like: 1 + -1
				#but its easier when we realize that a minus
				#is only unary when the last token was a left paren,
				#an operator, or its the first token.

				if (next.type == YarnGlobals.TokenType.Minus):
					if (last == null ||
						 last.type == YarnGlobals.TokenType.LeftParen ||
						 Operator.is_op(last.type)):
						#unary minus
						next.type = YarnGlobals.TokenType.UnaryMinus
				
				#cannot assign inside expression
				# x = a is the same as x == a
				if next.type == YarnGlobals.TokenType.EqualToOrAssign:
					next.type = YarnGlobals.TokenType.EqualTo

				
				#operator precedence
				while (ExpressionNode.is_apply_precedence(next.type,opStack)):
					var op = opStack.pop_back()
					rpn.append(op)

				opStack.push_back(next)
			
			elif next.type == YarnGlobals.TokenType.LeftParen:
				#entered parenthesis sub expression
				opStack.push_back(next)

			elif next.type == YarnGlobals.TokenType.RightParen:
				#leaving sub expression
				# resolve order of operations
				while opStack.back().type != YarnGlobals.TokenType.LeftParen:
					rpn.append(opStack.pop_back())
					if opStack.back() == null:
						printerr("Unbalanced parenthasis #RightParen. Parser.ExpressionNode")
						parser.error = ERR_INVALID_DATA
						return null
				
				
				opStack.pop_back() # pop left parenthesis
				if !opStack.empty() && opStack.back().type == YarnGlobals.TokenType.Identifier:
					#function call
					#last token == left paren this == no params
					#else 
					#we have more than 1 param
					if last.type != YarnGlobals.TokenType.LeftParen:
						funcStack.back().paramCount+=1
					
					rpn.append(opStack.pop_back())
					funcStack.pop_back()

			#record last token used
			last = next

		#no more tokens : pop operators to output
		while opStack.size() > 0:
			rpn.append(opStack.pop_back())

		#if rpn is empty then this is not expression
		if rpn.size() == 0:
			printerr("Error parsing expression: Expression not found!")

		#build expression tree
		var first = rpn.front()
		var evalStack : Array = []#ExpressionNode

		while rpn.size() > 0:
			
			var next = rpn.pop_front()
			if Operator.is_op(next.type):
				#operation
				var info : OperatorInfo = Operator.op_info(next.type)

				if evalStack.size() < info.arguments:
					printerr("Error parsing : Not enough arguments for %s [ got %s expected - was %s]"%[YarnGlobals.get_script().token_type_name(next.type),evalStack.size(),info.arguments])

				var params : Array = []#ExpressionNode
				for i in range(info.arguments):
					params.append(evalStack.pop_back())

				params.invert()

				var function : String = get_func_name(next.type)

				var expression : ExpressionNode = ExpressionNode.new(parent,parser,null,function,params)
				
				evalStack.append(expression)

			elif next.type == YarnGlobals.TokenType.Identifier:
				#function call

				var function : String = next.value

				var params : Array = []#ExpressionNode
				for i in range(next.paramCount):
					
					params.append(evalStack.pop_back())
				
				params.invert()

				var expression : ExpressionNode = ExpressionNode.new(parent,parser,null,function,params)
	
				evalStack.append(expression)
			else: #raw value
				var value : ValueNode = ValueNode.new(parent,parser,next)
				var expression : ExpressionNode = ExpressionNode.new(parent,parser,value)
				evalStack.append(expression)

		
		#we should have a single root expression left
		#if more then we failed ---- NANI
		if evalStack.size() != 1:
			printerr("Error parsing expression (stack did not reduce correctly ) @[l%4d,c%4d]"%[first.lineNumber,first.column])

		

		return evalStack.pop_back()

	# static func can_parse(parser)->bool:
	# 	return false

	static func get_func_name(type)->String:
		var string : String = ""
		
		for key in YarnGlobals.TokenType.keys():
			if YarnGlobals.TokenType[key] == type:
				return key					
		return string

	static func is_apply_precedence(type,operatorStack:Array)->bool:
		if operatorStack.size() == 0:
			return false
		
		if !Operator.is_op(type):
			printerr("Unable to parse expression!")
			return false
		
		var second = operatorStack.back().type

		if !Operator.is_op(second):
			return false
		
		var firstInfo : OperatorInfo = Operator.op_info(type)
		var secondInfo : OperatorInfo = Operator.op_info(second)

		if (firstInfo.associativity == Associativity.Left && 
			firstInfo.precedence <= secondInfo.precedence):
			return true
		
		if (firstInfo.associativity == Associativity.Right && 
			firstInfo.precedence < secondInfo.precedence):
			return true

		return false

class Assignment extends ParseNode:

	var destination : String
	var value : ExpressionNode
	var operation 

	func _init(parent:ParseNode,parser).(parent,parser):
		parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
		parser.expect_symbol([YarnGlobals.TokenType.Set])
		destination = parser.expect_symbol([YarnGlobals.TokenType.Variable]).value
		operation = parser.expect_symbol(Assignment.valid_ops()).type
		value = ExpressionNode.parse(self,parser)
		parser.expect_symbol([YarnGlobals.TokenType.EndCommand])

	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []
		info.append(tab(indentLevel,"set:"))
		info.append(tab(indentLevel+1,destination))
		info.append(tab(indentLevel+1,YarnGlobals.get_script().token_type_name(operation)))
		info.append(value.tree_string(indentLevel+1))
		return info.join("")

		
	static func can_parse(parser)->bool:
		return parser.next_symbols_are([
			YarnGlobals.TokenType.BeginCommand,
			YarnGlobals.TokenType.Set
		])

	static func valid_ops()->Array:
		return [
			YarnGlobals.TokenType.EqualToOrAssign,
			YarnGlobals.TokenType.AddAssign,
			YarnGlobals.TokenType.MinusAssign,
			YarnGlobals.TokenType.DivideAssign,
			YarnGlobals.TokenType.MultiplyAssign
		]

class Operator extends ParseNode:

	var opType

	func _init(parent:ParseNode,parser,opType=null).(parent,parser):

		if opType == null :
			self.opType = parser.expect_symbol(Operator.op_types()).type
		else:
			self.opType = opType

	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []
		info.append(tab(indentLevel,opType))
		return info.join("")

	static func op_info(op)->OperatorInfo:
		if !Operator.is_op(op) : 
			printerr("%s is not a valid operator" % op.name)
			return null


		#determine associativity and operands 
		# each operand has
		var TokenType = YarnGlobals.TokenType

		match op:
			TokenType.Not, TokenType.UnaryMinus:
				return OperatorInfo.new(Associativity.Right,30,1)
			TokenType.Multiply,TokenType.Divide,TokenType.Modulo:
				return OperatorInfo.new(Associativity.Left,20,2)
			TokenType.Add,TokenType.Minus:
				return OperatorInfo.new(Associativity.Left,15,2)
			TokenType.GreaterThan,TokenType.LessThan,TokenType.GreaterThanOrEqualTo,TokenType.LessThanOrEqualTo:
				return OperatorInfo.new(Associativity.Left,10,2)
			TokenType.EqualTo,TokenType.EqualToOrAssign,TokenType.NotEqualTo:
				return OperatorInfo.new(Associativity.Left,5,2)
			TokenType.And:
				return OperatorInfo.new(Associativity.Left,4,2)
			TokenType.Or:
				return OperatorInfo.new(Associativity.Left,3,2)
			TokenType.Xor:
				return OperatorInfo.new(Associativity.Left,2,2)
			_:
				printerr("Unknown operator: %s" % op.name)

		return null

	static func is_op(type)->bool:
		return type in op_types()

	static func op_types()->Array:
		return [
			YarnGlobals.TokenType.Not,
			YarnGlobals.TokenType.UnaryMinus,

			YarnGlobals.TokenType.Add,
			YarnGlobals.TokenType.Minus,
			YarnGlobals.TokenType.Divide,
			YarnGlobals.TokenType.Multiply,
			YarnGlobals.TokenType.Modulo,

			YarnGlobals.TokenType.EqualToOrAssign,
			YarnGlobals.TokenType.EqualTo,
			YarnGlobals.TokenType.GreaterThan,
			YarnGlobals.TokenType.GreaterThanOrEqualTo,
			YarnGlobals.TokenType.LessThan,
			YarnGlobals.TokenType.LessThanOrEqualTo,
			YarnGlobals.TokenType.NotEqualTo,

			YarnGlobals.TokenType.And,
			YarnGlobals.TokenType.Or,

			YarnGlobals.TokenType.Xor
		]


class OperatorInfo:
	var associativity
	var precedence : int
	var arguments : int

	func _init(associativity,precedence:int,arguments:int):
		self.associativity = associativity
		self.precedence = precedence
		self.arguments = arguments


class Clause:
	var expression : ExpressionNode
	var statements : Array = [] #Statement

	func _init(expression:ExpressionNode = null, statements : Array = []):
		self.expression = expression
		self.statements = statements

	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []
		if expression!=null:
			info.append(expression.tree_string(indentLevel))
		info.append(tab(indentLevel,"{"))
		for statement in statements:
			info.append(statement.tree_string(indentLevel+1))

		info.append(tab(indentLevel,"}"))
		return info.join("")

	func tab(indentLevel : int , input : String,newLine : bool = true)->String:
		var tabPrecursor = ""
		var indentSpacing= 3
		for i in range(indentLevel):
			tabPrecursor+="|%*s"%[indentSpacing,""]

		return ("%*s %s%s"% [+indentLevel,tabPrecursor,input,("" if !newLine else "\n")])
	# func tab(indentLevel : int , input : String,newLine : bool = true)->String:
	# 	return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")])
