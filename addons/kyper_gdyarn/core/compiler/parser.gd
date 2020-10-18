extends Object

const YarnGlobals = preload("res://addons/kyper_gdyarn/autoloads/execution_states.gd")
const Lexer = preload("res://addons/kyper_gdyarn/core/compiler/lexer.gd")


var _tokens : Array = []#token

func _init(tokens):
	self._tokens = tokens
	
#how to handle operations
enum Associativity {
	Left,Right,None
}

func parse_node()->YarnNode:
	return YarnNode.new("Start",null,self)

func next_symbol_is(validTypes:Array)->bool:
	var type = self._tokens.front().type
	for validType in validTypes:
		if type == validType:
			return true
	return false

#look ahead for `<<` and `else`
func next_symbols_are(validTypes:Array)->bool:
	var temp = []+_tokens
	for type in validTypes:
		if temp.pop_front().type != type:
			return false
	return true

func expect_symbol(tokenTypes:Array = [])->Lexer.Token:
	var t = self._tokens.pop_front() as Lexer.Token
	var size = tokenTypes.size()
	
	if size == 0:
		if t.type == YarnGlobals.TokenType.EndOfInput:
			printerr("unexpected end of input")
			return null
		return t

	for type in tokenTypes:
		if t.type == type:
			return t
	
	printerr("unexpexted token: expected[ %s ] but got [ %s ]"% (tokenTypes+[t.type]))
	return null

static func tab(indentLevel : int , input : String,newLine : bool = true)->String:
	return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")]) 

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
		return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")]) 
		
	
	func set_parent(parent):
		self.parent = parent

#this is a Yarn Node - contains all the text
class YarnNode extends ParseNode:

	var name : String
	var source : String
	
	var editorNodeTags : Array =[]#tags defined in node header
	var statements : Array = []# Statement

	func _init(name:String,parent:ParseNode,parser).(parent,parser):

		self.name = name
		while (parser.tokens().size() > 0 && 
			  !parser.next_symbol_is([YarnGlobals.TokenType.Dedent,YarnGlobals.TokenType.EndOfInput])):
			statements.append(Statement.new(self,parser))
			#print(statements.size())

	func yarn_node():
		pass

	func tree_string(indentLevel : int)->String:
		
		var info : PoolStringArray = []

		for statement in statements:
			info.append(statement.tree_string(indentLevel +1))

		#print("printing TREEEEEEEEEEEEE")

		return info.join("")
	

class Header extends ParseNode:
	pass


class Statement extends ParseNode:
	var Type = YarnGlobals.StatementTypes

	var type : int
	var block : Block
	var ifStatement : IfStatement
	var optionStatement : OptionStatement
	var assignment : Assignment 
	var shortcutOptionGroup : ShortcutOptionGroup
	var customCommand : CustomCommand
	var line : String

	func _init(parent:ParseNode,parser).(parent,parser):

		if Block.can_parse(parser):
			block  = Block.new(self,parser)
			type = Type.Block
		elif IfStatement.can_parse(parser):
			ifStatement = IfStatement.new(self,parser)
			type = Type.IfStatement
		elif OptionStatement.can_parse(parser):
			optionStatement = OptionStatement.new(self,parser)
			type = Type.OptionStatement
		elif Assignment.can_parse(parser):
			assignment = Assignment.new(self,parser)
			type = Type.AssignmentStatement
		elif ShortcutOptionGroup.can_parse(parser):
			shortcutOptionGroup = ShortcutOptionGroup.new(self,parser)
			type = Type.ShortcutOptionGroup
		elif CustomCommand.can_parse(parser):
			customCommand = CustomCommand.new(self,parser)
			type = Type.CustomCommand
		elif parser.next_symbol_is([YarnGlobals.TokenType.Text]):
			line = parser.expect_symbol([YarnGlobals.TokenType.Text]).value
			type = Type.Line
		else:
			printerr("expected a statement but got %s instead. (probably an inbalanced if statement)" % parser.tokens().front()._to_string())
		
		
		var tags : Array = []

		while parser.next_symbol_is([YarnGlobals.TokenType.TagMarker]):
			parser.expect_symbol([YarnGlobals.TokenType.TagMarker])
			var tag : String = parser.expect_symbol([YarnGlobals.TokenType.Identifier]).value
			tags.append(tag)

		if(tags.size()>0):
			self.tags = tags

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
				info.append(tab(indentLevel,"Line: %s"%line))
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

	var label : String
	var condition : ExpressionNode
	var node : YarnNode

	func _init(index:int, parent:ParseNode, parser).(parent,parser):
		parser.expect_symbol([YarnGlobals.TokenType.ShortcutOption])
		label = parser.expect_symbol([YarnGlobals.TokenType.Text]).value

		# parse the conditional << if $x >> when it exists

		var tags : Array = []#string
		while( parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.IfToken]) 
			|| parser.next_symbol_is([YarnGlobals.TokenType.TagMarker])):
			
			if parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand, YarnGlobals.TokenType.IfToken]):
				parser.expect_symbol([YarnGlobals.TokenType.BeginCommand])
				parser.expect_symbol([YarnGlobals.TokenType.IfToken])
				condition = ExpressionNode.parse(self,parser)
				parser.expect_symbol([YarnGlobals.TokenType.EndCommand])
			elif parser.next_symbol_is([YarnGlobals.TokenType.TagMarker]):
				parser.expect_symbol([YarnGlobals.TokenType.TagMarker])
				var tag : String = parser.expect_symbol([YarnGlobals.TokenType.Identifier]).value;
				tags.append(tag)

		
		self.tags = tags
		# parse remaining statements

		if parser.next_symbol_is([YarnGlobals.TokenType.Indent]):
			parser.expect_symbol([YarnGlobals.TokenType.Indent])
			node = YarnNode.new("%s.%s" %[self.get_node_parent().name ,index], self,parser)
			parser.expect_symbol([YarnGlobals.TokenType.Dedent])


	func tree_string(indentLevel : int)->String:
		var info : PoolStringArray = []

		info.append(tab(indentLevel,"Option \"%s\""%label))

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
	
	var destination : String 
	var label : String

	func _init(parent:ParseNode, parser).(parent,parser):

		var strings : Array = []#string

		#parse [[LABEL
		parser.expect_symbol([YarnGlobals.TokenType.OptionStart])
		strings.append(parser.expect_symbol([YarnGlobals.TokenType.Text]).value)

		#if there is a | get the next string
		if parser.next_symbol_is([YarnGlobals.TokenType.OptionDelimit]):
			parser.expect_symbol([YarnGlobals.TokenType.OptionDelimit])
			var t = parser.expect_symbol([YarnGlobals.TokenType.Text,YarnGlobals.TokenType.Identifier])
			#print("Token %s"%t.value)
			strings.append(t.value as String)
		
		label = strings[0] if strings.size() > 1 else ""
		destination = strings[1] if strings.size() > 1 else strings[0]

		parser.expect_symbol([YarnGlobals.TokenType.OptionEnd])

	func tree_string(indentLevel : int)->String:
		if label != null:
			return tab(indentLevel,"Option: %s -> %s"%[label,destination])
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
				info.append(tab(indentLevel,"if:"))
			elif clause.expression!=null:
				info.append(tab(indentLevel,"Else If"))
			else:
				info.append(tab(indentLevel,"Else:"))

			info.append(clause.tree_string(indentLevel +1))

		return info.join("")

	static func can_parse(parser)->bool:
		return parser.next_symbols_are([YarnGlobals.TokenType.BeginCommand,YarnGlobals.TokenType.IfToken])
	pass

class ValueNode extends ParseNode:
	const Value = preload("res://addons/kyper_gdyarn/core/value.gd")
	const Lexer = preload("res://addons/kyper_gdyarn/core/compiler/lexer.gd")
	var value : Value

	func _init(parent:ParseNode, parser, token: Lexer.Token = null).(parent,parser):

		var t : Lexer.Token = token
		if t == null :
			parser.expect_symbol([YarnGlobals.TokenType.Number,
		YarnGlobals.TokenType.Variable,YarnGlobals.TokenType.Str]) 
		use_token(t)


	#store value depedning on type
	func use_token(t:Lexer.Token):

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
				printerr("%s, Invalid token type" % t.name)

	func tree_string(indentLevel : int)->String:
		return tab(indentLevel, "%s"%value.value())

		
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
						break
					rpn.append(p)

				
				#next token in opStack left paren
				# next parser token not allowed to be right paren or comma
				if parser.next_symbol_is([YarnGlobals.TokenType.RightParen,
					YarnGlobals.TokenType.Comma]):
					printerr("Expected Expression : %s" % parser.tokens().front().name)
				
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
				
				
				opStack.pop_back()
				if opStack.back().type == YarnGlobals.TokenType.Identifier:
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
					printerr("Error parsing : Not enough arguments for %s [ got %s expected - was %s]"%[YarnGlobals.token_type_name(next.type),evalStack.size(),info.arguments])

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
			printerr("[%s] Error parsing expression (stack did not reduce correctly )"%first.name)

		

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
		info.append(tab(indentLevel+1,YarnGlobals.token_type_name(operation)))
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
		return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")]) 
