class_name YarnParser
# const YarnGlobals = preload("res://addons/gdyarn/autoloads/execution_states.gd")
# const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")

const Token := YarnLexer.Token
const TokenType := YarnGlobals.TokenType

var error := OK
var currentNodeName = "Start"

var _tokens: Array[Token] = []  #token


func _init(tokens):
	self._tokens = tokens


#how to handle operations
enum Associativity { Left, Right, None }

## parse the entire token stack collecting as many nodes as possible
func parse_nodes()->Array[YarnNode]:
	var nodes: Array[YarnNode] = []  #YarnNode
	while _tokens.size() > 0 && !next_symbol_is([TokenType.EndOfInput]):
		var yarn_node := parse_node()
		print("parsed node %s" % [yarn_node.name])
		if error != OK:
			printerr("error parsing node")
			break
		nodes.append(yarn_node)
		if next_symbol_is([TokenType.NodeDelimiter]):
			expect_symbol([TokenType.NodeDelimiter])
		else:
			var name_of_top_of_stack = YarnGlobals.token_name(_tokens.front().type)
			printerr("expected node delimiter")
			error = ERR_INVALID_DATA
			break
	return nodes

## parse a single node 
func parse_node() -> YarnNode:
	return YarnNode.new(null, self)



func next_symbol_is(validTypes: Array, line: int = -1) -> bool:
	if (self._tokens.size() == 0):
		return false
	var type = self._tokens.front().type
	for validType in validTypes:
		if type == validType && (line == -1 || line == self._tokens.front().line_number):
			return true
	return false


## look ahead for `<<` and `else`
## This looks at the next tokens without consuming them
## if they are not in the right order of the validTypes given
## then this will return false
func next_symbols_are(validTypes: Array, line: int = -1) -> bool:
	if self._tokens.size() < validTypes.size():
		return false
	var temp: Array[Token] = Array(self._tokens.duplicate())
	for type in validTypes:
		if temp.pop_front().type != type:
			return false
	return line == -1 || line == self._tokens.front().line_number


## Consume the next symbol and throw an error if it is not 
## of the expected type
func expect_symbol(token_types: Array = []) -> Token:
	var t := self._tokens.pop_front() as Token
	print("token consumed %s" % [t._to_string()])
	var size = token_types.size()

	if size == 0:
		if t.type == TokenType.EndOfInput:
			printerr("unexpected end of input")
			error = ERR_INVALID_DATA
			return null
		return t

	for type in token_types:
		if t.type == type:
			return t

	var expected_types: String = " "

	for token_type in token_types:
		expected_types += YarnGlobals.token_name(token_type) + " "

	# expectedTypes+= ""

	# TODO: Move this to Some type of Diagnostic system, do not print it in place
	printerr(
		(
			"unexpected token: Expexted [%s] but got [%s<%s>] @(%s,%s)"
			% [
				expected_types,
				YarnGlobals.token_name(t.type),
				t.value,
				t.line_number,
				t.column
			]
		)
	)
	error = ERR_INVALID_DATA
	return null


# static func tab(indentLevel : int , input : String,newLine : bool = true)->String:
# 	return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")])


func tokens() -> Array[Token]:
	return _tokens


class ParseNode:
	var parent: ParseNode
	var line_number: int
	var tags: Array[String]  #<String>

	func _init(parent: ParseNode, parser):
		self.parent = parent
		var tokens: Array = parser.tokens() as Array
		if tokens.size() > 0:
			line_number = tokens.front().line_number
		else:
			line_number = -1
		tags = []

	func tree_string(indentLevel: int) -> String:
		return "NotImplemented"

	func tags_to_string(indentLevel: int) -> String:
		var tags_packed := PackedStringArray(tags)
		return ", ".join(tags_packed)

	func get_node_parent() -> YarnNode:
		var node = self
		while node != null:
			if node.has_method("yarn_node"):
				return node as YarnNode
			node = node.parent
		return null

	func tab(indentLevel: int, input: String, newLine: bool = true) -> String:
		var tabPrecursor = ""
		var indentSpacing = 3
		for i in range(indentLevel):
			tabPrecursor += "|%*s" % [indentSpacing, ""]

		return "%*s %s%s" % [indentLevel, tabPrecursor, input, "" if !newLine else "\n"]

	func set_parent(parent):
		self.parent = parent


## this is a Yarn Node - contains all the meta data and statements
class YarnNode:
	extends ParseNode

	var name: String # the title in the header
	var source: String
	var meta_data : Dictionary = {} # information from the header that is not title or tags
	var statements: Array = []  # Statement
	var hasOptions := false

	func _init(parent: ParseNode, parser,check_headers: bool = true,title :String = ""):
		super(parent, parser)
		name = title
		# collect all header information and meta data 
		# this includes title and tags 
		# and any other information that is not a statement
		# TODO: 
		if check_headers:
			_parse_headers(parser)

		while (
			parser.tokens().size() > 0
			&& !parser.next_symbol_is(
				[TokenType.Dedent, TokenType.EndOfInput, TokenType.NodeDelimiter]
			)
			&& parser.error == OK
		):
			var statement := Statement.new(self, parser)
			if parser.error != OK:
				printerr("error parsing statement")
				break
			statements.append(statement)
			print("top_token=%s value=%s" % [YarnGlobals.token_name(parser.tokens().front().type), parser.tokens().front().value])
			#print(statements.size())

		print("top_token=%s" % [YarnGlobals.token_name(parser.tokens().front().type)])
		# if parser.next_symbol_is([TokenType.NodeDelimiter]):
		# 	parser.expect_symbol()

	func _parse_headers(parser:YarnParser)->void:
		while (parser.tokens().size() > 0 && !parser.next_symbol_is([TokenType.EndOfInput, TokenType.HeaderDelimiter])):
			# get title if title 
			# get tags split tags by comma
			# check for duplicate headers?
			var identifier:Token= parser.expect_symbol([TokenType.Identifier])
			parser.expect_symbol([TokenType.Colon]) 
			if parser.next_symbol_is([TokenType.Text]):
				var value :Token= parser.expect_symbol([TokenType.Text])

				if identifier.value == &"title" && (name == null || name.is_empty()): 
					name = value.value 
				elif identifier.value == &"tags": 
					var split_tags := value.value.split(',')
					for tag in split_tags:
						tags.append(tag.strip_edges(true, true))
				else:
					meta_data[identifier.value] = value.value	
			
		# Make sure that title is there for each node
		if name == null || name.is_empty():
			printerr("no title in header found")
			parser.error = ERR_INVALID_DATA
			
		if parser.next_symbol_is([TokenType.HeaderDelimiter]):
			print("header delimiter found")
			parser.expect_symbol([TokenType.HeaderDelimiter])
		else:
			printerr("no header delimiter found")
			parser.error = ERR_INVALID_DATA
		# parser.expect_symbol([TokenType.HeaderDelimiter])
		
		# parse statements in node body until you hit an end of node

	
	# WARNING: DO NOT REMOVE SINCE THIS IS THE WAY WE CHECK CLASS
	func yarn_node():
		pass

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []

		info.append(tab(indentLevel, "Node: %s" % name))
		info.append(tab(indentLevel + 1, "Tags: %s" % tags_to_string(indentLevel + 1)))
		if (meta_data.size() > 0):
			info.append(tab(indentLevel+1, "Meta Data:"))
			for key in meta_data.keys():
				info.append(tab(indentLevel + 2, "%s: %s" % [key, meta_data[key]]))
		for statement in statements:
			info.append(statement.tree_string(indentLevel + 1))

		return "".join(info)


# UNIMPLEMENTED .
# might be worth handling this through the parser instead as a pre-process step
# we handle header information before we beign parsing content
class Header:
	extends ParseNode
	pass


class InlineExpression:
	extends ParseNode
	var expression: ExpressionNode

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		parser.expect_symbol([TokenType.ExpressionFunctionStart])
		expression = ExpressionNode.parse_expressions(self, parser)
		parser.expect_symbol([TokenType.ExpressionFunctionEnd])

	static func can_parse(parser):
		return parser.next_symbol_is([TokenType.ExpressionFunctionStart])

	#TODO make tree string nicer
	#     with added information about the expression
	func tree_string(indentLevel: int) -> String:
		return "InlineExpression:"


class FormatFunction:
	extends ParseNode

	# returns a format_text string as [ name "{0}" key1="value1" key2="value2" ]
	var format_text: String = ""
	var expression_value: InlineExpression

	func _init(parent: ParseNode, parser, expressionCount: int):
		super(parent, parser)
		format_text = "["
		parser.expect_symbol([TokenType.FormatFunctionStart])

		while !parser.next_symbol_is([TokenType.FormatFunctionEnd]):
			if parser.next_symbol_is([TokenType.Text]):
				format_text += parser.expect_symbol().value

			if InlineExpression.can_parse(parser):
				expression_value = InlineExpression.new(self, parser)
				format_text += ' "{%d}" ' % expressionCount
		parser.expect_symbol()
		format_text += "]"

	static func can_parse(parser):
		return parser.next_symbol_is([TokenType.FormatFunctionStart])

	#TODO Make format prettier and add more information
	func tree_string(indentLevel: int) -> String:
		return "FormatFucntion"


class LineNode:
	extends ParseNode
	var line_text: String
	#TODO: FIXME: right now we are putting the formatfunctions and inline expressions in the same
	#             list but if at some point we want to strongly type our sub list we need to make a new
	#             parse node that can have either an InlineExpression or a FunctionFormat
	#             .. This is a consideration for Godot4.x
	var substitutions: Array = []  # of type <InlineExpression |& FormatFunction>
	var lineid: String = ""
	var line_tags: PackedStringArray = []

	# NOTE: If format function an inline functions are both present
	# returns a line in the format "Some text {0} and some other {1}[format "{2}" key="value" key="value"]"

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		while parser.next_symbol_is(
			[
				TokenType.FormatFunctionStart,
				TokenType.ExpressionFunctionStart,
				TokenType.Text,
				TokenType.TagMarker
			]
		):
			if FormatFunction.can_parse(parser):
				var ff = FormatFunction.new(self, parser, substitutions.size())
				if ff.expression_value != null:
					substitutions.append(ff.expression_value)
				line_text += ff.format_text
			elif InlineExpression.can_parse(parser):
				var ie = InlineExpression.new(self, parser)
				line_text += "{%d}" % substitutions.size()
				substitutions.append(ie)
			elif parser.next_symbols_are(
				[TokenType.TagMarker, TokenType.Identifier]
			):
				parser.expect_symbol()
				var tagToken = parser.expect_symbol([TokenType.Identifier])
				if tagToken.value.begins_with("line:"):
					if lineid.is_empty():
						lineid = tagToken.value
					else:
						printerr(
							(
								"Too many line_tags @[%s:%d]"
								% [parser.currentNodeName, tagToken.line_number]
							)
						)
						return
				else:
					tags.append(tagToken.value)

			else:
				var tt = parser.expect_symbol()
				if tt.line_number == line_number && !(tt.type == TokenType.BeginCommand):
					line_text += tt.value
				else:
					parser._tokens.push_front(tt)
					break

	func tree_string(indentLevel: int) -> String:
		return "Line: (%s)[%d]" % [line_text, substitutions.size()]


class Statement:
	extends ParseNode
	var Type = YarnGlobals.StatementTypes

	var type: int
	var block: Block
	var ifStatement: IfStatement
	# var optionStatement: OptionStatement
	var assignment: Assignment
	var shortcutOptionGroup: ShortcutOptionGroup
	var customCommand: CustomCommand
	var line: LineNode

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		print("hello")
		if parser.error != OK:
			return

		if Block.can_parse(parser):
			printerr("parsing a block")
			block = Block.new(self, parser)
			type = Type.Block
		elif IfStatement.can_parse(parser):
			printerr("parsing if statement")
			ifStatement = IfStatement.new(self, parser)
			type = Type.IfStatement
		elif Assignment.can_parse(parser):
			printerr("parsing assignment")
			assignment = Assignment.new(self, parser)
			type = Type.AssignmentStatement
		elif ShortcutOptionGroup.can_parse(parser):
			# print("ST:%s[value=%s]" % [YarnGlobals.token_name(parser.tokens().front().type), parser.tokens().front().value])
			printerr("parsing shortcut option group")
			shortcutOptionGroup = ShortcutOptionGroup.new(self, parser)
			type = Type.ShortcutOptionGroup
		elif CustomCommand.can_parse(parser):
			printerr("parsing commands")
			customCommand = CustomCommand.new(self, parser)
			type = Type.CustomCommand
		elif parser.next_symbol_is([TokenType.Text]):
			printerr("parsing line")
			# line = parser.expect_symbol([TokenType.Text]).value
			# type = Type.Line
			line = LineNode.new(self, parser)
			type = Type.Line
			# parser.expect_symbol([TokenType.EndOfLine])
		else:

			printerr(
				(
					"expected a statement but got %s instead. (probably an inbalanced if statement)"
					% parser.tokens().front()._to_string()
				)
			)
			parser.error = ERR_PARSE_ERROR
			return


	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []

		match type:
			Type.Block:
				info.append(block.tree_string(indentLevel))
			Type.IfStatement:
				info.append(ifStatement.tree_string(indentLevel))
			Type.AssignmentStatement:
				info.append(assignment.tree_string(indentLevel))
			# Type.OptionStatement:
			# 	info.append(optionStatement.tree_string(indentLevel))
			Type.ShortcutOptionGroup:
				info.append(shortcutOptionGroup.tree_string(indentLevel))
			Type.CustomCommand:
				info.append(customCommand.tree_string(indentLevel))
			Type.Line:
				info.append(tab(indentLevel, line.tree_string(indentLevel)))
			_:
				printerr("cannot print statement")

		#print("statement --")

		return "".join(info)


class CustomCommand:
	extends ParseNode

	enum Type { Expression, ClientCommand }

	var type: int
	var expression: ExpressionNode
	var clientCommand: String

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		parser.expect_symbol([TokenType.BeginCommand])

		var commandTokens = []
		commandTokens.append(parser.expect_symbol())

		while !parser.next_symbol_is([TokenType.EndCommand]):
			var token:Token = parser.expect_symbol()
			print("token type %s" % [YarnGlobals.token_name(token.type)])
			commandTokens.append(token)

		parser.expect_symbol([TokenType.EndCommand])

		#if first token is identifier and second is leftt parenthesis
		#evaluate as function
		if (
			commandTokens.size() > 1
			&& commandTokens[0].type == TokenType.Identifier
			&& commandTokens[1].type == TokenType.LeftParen
		):
			var p = get_script().new(commandTokens, parser.library)
			var expression: ExpressionNode = ExpressionNode.parse_expressions(self, p)
			type = Type.Expression
			self.expression = expression
		else:
			#otherwise evaluuate command
			type = Type.ClientCommand
			self.clientCommand = commandTokens[0].value

	func tree_string(indentLevel: int) -> String:
		match type:
			Type.Expression:
				return tab(indentLevel, "Expression: %s" % expression.tree_string(indentLevel + 1))
			Type.ClientCommand:
				return tab(indentLevel, "Command: %s" % clientCommand)
		return ""

	static func can_parse(parser) -> bool:
		return (
			parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.Text]
			)
			|| parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.Identifier]
			)
		)


class ShortcutOptionGroup:
	extends ParseNode

	var options: Array = []  #ShortcutOptions

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		# parse options until there is no more
		# expect one otherwise invalid

		var s_index: int = 1
		options.append(ShortCutOption.new(s_index, self, parser))
		s_index += 1
		while parser.next_symbol_is([TokenType.ShortcutOption]):
			options.append(ShortCutOption.new(s_index, self, parser))
			s_index += 1
		var name_of_top_of_stack = YarnGlobals.token_name(parser._tokens.front().type)
		# printerr("eneded the shortcut group with a [%s] on top" % nameOfTopOfStack)

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []

		info.append(tab(indentLevel, "Shortcut Option Group{"))

		for option in options:
			info.append(option.tree_string(indentLevel + 1))

		info.append(tab(indentLevel, "}"))

		return "".join(info)

	static func can_parse(parser) -> bool:
		return parser.next_symbol_is([TokenType.ShortcutOption])

	pass


class ShortCutOption:
	extends ParseNode

	var line: LineNode
	var condition: ExpressionNode
	var node: YarnNode

	func _init(index: int, parent: ParseNode, parser):
		super(parent, parser)
		# printerr("starting shortcut option parse")
		parser.expect_symbol([TokenType.ShortcutOption])
		line = LineNode.new(self, parser)
		# printerr(" this is a line found in shortcutoption : ", line.line_text)
		# parse the conditional << if $x >> when it exists
		var tags: Array[String] = []  #string

		while (
			parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.IfToken]
			)
			|| parser.next_symbol_is([TokenType.TagMarker])
		):
			if parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.IfToken], line_number
			):
				parser.expect_symbol([TokenType.BeginCommand])
				parser.expect_symbol([TokenType.IfToken])
				condition = ExpressionNode.parse_expressions(self, parser)
				parser.expect_symbol([TokenType.EndCommand])
			elif parser.next_symbol_is([TokenType.TagMarker]):
				parser.expect_symbol([TokenType.TagMarker])
				var tag: String = parser.expect_symbol([TokenType.Identifier]).value
				tags.append(tag)
			else:
				# printerr("could not find if or tag on the same line")
				break

		self.tags = tags

		for tag in tags:
			if tag.begins_with("line:") && line.lineid.is_empty():
				line.lineid = tag

		# parse remaining statements

		if parser.next_symbol_is([TokenType.Indent]):
			parser.expect_symbol([TokenType.Indent])
			node = YarnNode.new(self, parser,false,"%s.%s" % [self.get_node_parent().name, index])
			parser.expect_symbol([TokenType.Dedent])

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []

		info.append(tab(indentLevel, 'Option "%s"' % line.tree_string(indentLevel)))

		if condition != null:
			info.append(tab(indentLevel + 1, "(when:"))
			info.append(condition.tree_string(indentLevel + 2))
			info.append(tab(indentLevel + 1, "),"))
		if node != null:
			info.append(tab(indentLevel, "{"))
			info.append(node.tree_string(indentLevel + 1))
			info.append(tab(indentLevel, "}"))

		return "".join(info)


#Blocks are groups of statements with the same indent level
class Block:
	extends ParseNode

	var statements: Array = []

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		#read indent
		parser.expect_symbol([TokenType.Indent])

		#keep reading statements until we hit a dedent
		while !parser.next_symbol_is([TokenType.Dedent]):
			#parse all statements including nested blocks
			statements.append(Statement.new(self, parser))

		#clean up dedent
		parser.expect_symbol([TokenType.Dedent])

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []

		info.append(tab(indentLevel, "Block {"))

		for statement in statements:
			info.append(statement.tree_string(indentLevel + 1))

		info.append(tab(indentLevel, "}"))

		return "".join(info)

	static func can_parse(parser) -> bool:
		return parser.next_symbol_is([TokenType.Indent])



class IfStatement:
	extends ParseNode

	var clauses: Array = []  #Clauses

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		#<<if Expression>>
		var prime: Clause = Clause.new()

		parser.expect_symbol([TokenType.BeginCommand])
		parser.expect_symbol([TokenType.IfToken])
		prime.expression = ExpressionNode.parse_expressions(self, parser)
		parser.expect_symbol([TokenType.EndCommand])

		#read statements until 'endif' or 'else' or 'else if'
		var statements: Array = []  #statement
		while (
			!parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.EndIf]
			)
			&& !parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.ElseToken]
			)
			&& !parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.ElseIf]
			)
		):
			statements.append(Statement.new(self, parser))

			#ignore dedent
			while parser.next_symbol_is([TokenType.Dedent]):
				parser.expect_symbol([TokenType.Dedent])

		prime.statements = statements
		clauses.append(prime)

		#handle all else if
		while parser.next_symbols_are(
			[TokenType.BeginCommand, TokenType.ElseIf]
		):
			var clauseElif: Clause = Clause.new()

			#parse condition syntax
			parser.expect_symbol([TokenType.BeginCommand])
			parser.expect_symbol([TokenType.ElseIf])
			clauseElif.expression = ExpressionNode.parse_expressions(self, parser)
			parser.expect_symbol([TokenType.EndCommand])

			var elifStatements: Array = []  #statement
			while (
				!parser.next_symbols_are(
					[TokenType.BeginCommand, TokenType.EndIf]
				)
				&& !parser.next_symbols_are(
					[TokenType.BeginCommand, TokenType.ElseToken]
				)
				&& !parser.next_symbols_are(
					[TokenType.BeginCommand, TokenType.ElseIf]
				)
			):
				elifStatements.append(Statement.new(self, parser))

				#ignore dedent
				while parser.next_symbol_is([TokenType.Dedent]):
					parser.expect_symbol([TokenType.Dedent])

			clauseElif.statements = statements
			clauses.append(clauseElif)

		#handle else if exists
		if parser.next_symbols_are(
			[
				TokenType.BeginCommand,
				TokenType.ElseToken,
				TokenType.EndCommand
			]
		):
			#expect no expression - just <<else>>
			parser.expect_symbol([TokenType.BeginCommand])
			parser.expect_symbol([TokenType.ElseToken])
			parser.expect_symbol([TokenType.EndCommand])

			#parse until hit endif
			var clauseElse: Clause = Clause.new()
			var elStatements: Array = []  #statement
			while !parser.next_symbols_are(
				[TokenType.BeginCommand, TokenType.EndIf]
			):
				elStatements.append(Statement.new(self, parser))

			clauseElse.statements = elStatements
			clauses.append(clauseElse)

			#ignore dedent
			while parser.next_symbol_is([TokenType.Dedent]):
				parser.expect_symbol([TokenType.Dedent])

		#finish
		parser.expect_symbol([TokenType.BeginCommand])
		parser.expect_symbol([TokenType.EndIf])
		parser.expect_symbol([TokenType.EndCommand])

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []
		var first: bool = true

		for clause in clauses:
			if first:
				info.append(tab(indentLevel, "if:", true))
			elif clause.expression != null:
				info.append(tab(indentLevel, "Else If", true))
			else:
				info.append(tab(indentLevel, "Else:", true))

			info.append(clause.tree_string(indentLevel))

		return "".join(info)

	static func can_parse(parser) -> bool:
		return parser.next_symbols_are(
			[TokenType.BeginCommand, TokenType.IfToken]
		)

	pass


class ValueNode:
	extends ParseNode
	const Value = preload("res://addons/gdyarn/core/value.gd")
	const Lexer = preload("res://addons/gdyarn/core/compiler/lexer.gd")
	var value: Value

	func _init(parent: ParseNode, parser, token: Token = null):
		super(parent, parser)
		var t: Token = token
		if t == null:
			parser.expect_symbol(
				[
					TokenType.Number,
					TokenType.Variable,
					TokenType.Str
				]
			)

		use_token(t, parser)

	#store value depedning on type
	func use_token(t: Token, parser):
		match t.type:
			TokenType.Number:
				value = Value.new(float(t.value))
			TokenType.Str:
				value = Value.new(t.value)
			TokenType.FalseToken:
				value = Value.new(false)
			TokenType.TrueToken:
				value = Value.new(true)
			TokenType.Variable:
				value = Value.new(null)
				value.type = YarnGlobals.ValueType.Variable
				value.variable = t.value
			TokenType.NullToken:
				value = Value.new(null)
			_:
				printerr(
					(
						"%s, Invalid token type @[l%4d:c%4d]"
						% [YarnGlobals.token_name(t.type), t.line_number, t.column]
					)
				)
				parser.error = ERR_INVALID_DATA

	func tree_string(indentLevel: int, newline: bool = true) -> String:
		return tab(
			indentLevel,
			"<%s>%s" % [YarnGlobals.get_value_type_name(value.type), value.value()],
			newline
		)


#Expressions encompass a wide range of things like:
# math (1 + 2 - 5 * 3 / 10 % 2)
# Identifiers
# Values
class ExpressionNode:
	extends ParseNode

	var type
	var value: ValueNode
	var function: String
	var params: Array = []  #ExpressionNode

	func _init(
		parent: ParseNode, parser, value: ValueNode, function: String = "", params: Array = []
	):
		super(parent, parser)
		#no function - means value
		if value != null:
			self.type = YarnGlobals.ExpressionType.Value
			self.value = value
		else:  #function
			self.type = YarnGlobals.ExpressionType.FunctionCall
			self.function = function
			self.params = params

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []
		match type:
			YarnGlobals.ExpressionType.Value:
				return value.tree_string(indentLevel)
			YarnGlobals.ExpressionType.FunctionCall:
				info.append(tab(indentLevel, "Func[%s - params(%s)]:{" % [function, params.size()]))
				for param in params:
					#print("----> %s paramSize:%s"%[(function) , params.size()])
					info.append(param.tree_string(indentLevel + 1))
				info.append(tab(indentLevel, "}"))

		return "".join(info)

	#using Djikstra's shunting-yard algorithm to convert
	#stream of expresions into postfix notaion, then
	#build a tree of expressions
	static func parse_expressions(parent: ParseNode, parser) -> ExpressionNode:
		var rpn: Array[TokenType] = []  #token
		var opStack: Array[TokenType] = []  #token

		#track params
		var funcStack: Array = []  #token

		var validTypes: Array = [
			TokenType.Number,
			TokenType.Variable,
			TokenType.Str,
			TokenType.LeftParen,
			TokenType.RightParen,
			TokenType.Identifier,
			TokenType.Comma,
			TokenType.TrueToken,
			TokenType.FalseToken,
			TokenType.NullToken
		]
		validTypes += Operator.op_types()
		validTypes.reverse()

		var last  #Token

		#read expression content
		while parser.tokens().size() > 0 && parser.next_symbol_is(validTypes):
			var next = parser.expect_symbol(validTypes)  #lexer.Token

			if (
				next.type == TokenType.Variable
				|| next.type == TokenType.Number
				|| next.type == TokenType.Str
				|| next.type == TokenType.TrueToken
				|| next.type == TokenType.FalseToken
				|| next.type == TokenType.NullToken
			):
				#output primitives
				rpn.append(next)
			elif next.type == TokenType.Identifier:
				opStack.push_back(next)
				funcStack.push_back(next)

				#next token is parent - left
				next = parser.expect_symbol([TokenType.LeftParen])
				opStack.push_back(next)
			elif next.type == TokenType.Comma:
				#resolve sub expression before moving on
				while opStack.back().type != TokenType.LeftParen:
					var p = opStack.pop_back()
					if p == null:
						printerr("unbalanced parenthesis %s " % next.name)
						parser.error = ERR_INVALID_DATA
						return null
						break
					rpn.append(p)

				#next token in opStack left paren
				# next parser token not allowed to be right paren or comma
				if parser.next_symbol_is(
					[TokenType.RightParen, TokenType.Comma]
				):
					printerr("Expected Expression : %s" % parser.tokens().front().name)
					parser.error = ERR_INVALID_DATA
					return null

				#find the closest function on stack
				#increment parameters
				funcStack.back().paramCount += 1

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

				if next.type == TokenType.Minus:
					if (
						last == null
						|| last.type == TokenType.LeftParen
						|| Operator.is_op(last.type)
					):
						#unary minus
						next.type = TokenType.UnaryMinus

				#cannot assign inside expression
				# x = a is the same as x == a
				if next.type == TokenType.EqualToOrAssign:
					next.type = TokenType.EqualTo

				#operator precedence
				while ExpressionNode.is_apply_precedence(next.type, opStack):
					var op = opStack.pop_back()
					rpn.append(op)

				opStack.push_back(next)

			elif next.type == TokenType.LeftParen:
				#entered parenthesis sub expression
				opStack.push_back(next)

			elif next.type == TokenType.RightParen:
				#leaving sub expression
				# resolve order of operations
				while opStack.back().type != TokenType.LeftParen:
					rpn.append(opStack.pop_back())
					if opStack.back() == null:
						printerr("Unbalanced parenthasis #RightParen. Parser.ExpressionNode")
						parser.error = ERR_INVALID_DATA
						return null

				opStack.pop_back()  # pop left parenthesis
				if !opStack.is_empty() && opStack.back().type == TokenType.Identifier:
					#function call
					#last token == left paren this == no params
					#else
					#we have more than 1 param
					if last.type != TokenType.LeftParen:
						funcStack.back().paramCount += 1

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
		var eval_stack: Array[ExpressionNode] = []  #ExpressionNode

		while rpn.size() > 0:
			var next = rpn.pop_front()
			if Operator.is_op(next.type):
				#operation
				var info: OperatorInfo = Operator.op_info(next.type)

				if eval_stack.size() < info.arguments:
					printerr(
						(
							"Error parsing : Not enough arguments for %s [ got %s expected - was %s]"
							% [
								YarnGlobals.token_name(next.type),
								eval_stack.size(),
								info.arguments
							]
						)
					)

				var params: Array[ExpressionNode] = []  #ExpressionNode
				for i in range(info.arguments):
					params.append(eval_stack.pop_back())

				params.reverse()

				var function: String = get_func_name(next.type)

				var expression: ExpressionNode = ExpressionNode.new(
					parent, parser, null, function, params
				)

				eval_stack.append(expression)

			elif next.type == TokenType.Identifier:
				#function call

				var function: String = next.value

				var params: Array = []  #ExpressionNode
				for i in range(next.paramCount):
					params.append(eval_stack.pop_back())

				params.reverse()

				var expression: ExpressionNode = ExpressionNode.new(
					parent, parser, null, function, params
				)

				eval_stack.append(expression)
			else:  #raw value
				var value: ValueNode = ValueNode.new(parent, parser, next)
				var expression: ExpressionNode = ExpressionNode.new(parent, parser, value)
				eval_stack.append(expression)

		#we should have a single root expression left
		#if more then we failed ---- NANI
		if eval_stack.size() != 1:
			printerr(
				(
					"Error parsing expression (stack did not reduce correctly ) @[l%4d,c%4d]"
					% [first.line_number, first.column]
				)
			)

		return eval_stack.pop_back()

	# static func can_parse(parser)->bool:
	# 	return false

	static func get_func_name(type) -> String:
		var string: String = ""

		for key in TokenType.keys():
			if TokenType[key] == type:
				return key
		return string

	static func is_apply_precedence(type, operatorStack: Array) -> bool:
		if operatorStack.size() == 0:
			return false

		if !Operator.is_op(type):
			printerr("Unable to parse_expressions expression!")
			return false

		var second = operatorStack.back().type

		if !Operator.is_op(second):
			return false

		var firstInfo: OperatorInfo = Operator.op_info(type)
		var secondInfo: OperatorInfo = Operator.op_info(second)

		if (
			firstInfo.associativity == Associativity.Left
			&& firstInfo.precedence <= secondInfo.precedence
		):
			return true

		if (
			firstInfo.associativity == Associativity.Right
			&& firstInfo.precedence < secondInfo.precedence
		):
			return true

		return false


class Assignment:
	extends ParseNode

	var destination: String
	var value: ExpressionNode
	var operation

	func _init(parent: ParseNode, parser):
		super(parent, parser)
		parser.expect_symbol([TokenType.BeginCommand])
		parser.expect_symbol([TokenType.Set])
		destination = parser.expect_symbol([TokenType.Variable]).value
		operation = parser.expect_symbol(Assignment.valid_ops()).type
		value = ExpressionNode.parse_expressions(self, parser)
		parser.expect_symbol([TokenType.EndCommand])

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []
		info.append(tab(indentLevel, "set:"))
		info.append(tab(indentLevel + 1, destination))
		info.append(tab(indentLevel + 1, YarnGlobals.token_name(operation)))
		info.append(value.tree_string(indentLevel + 1))
		return "".join(info)

	static func can_parse(parser) -> bool:
		return parser.next_symbols_are(
			[TokenType.BeginCommand, TokenType.Set]
		)

	static func valid_ops() -> Array:
		return [
			TokenType.EqualToOrAssign,
			TokenType.AddAssign,
			TokenType.MinusAssign,
			TokenType.DivideAssign,
			TokenType.MultiplyAssign
		]


class Operator:
	extends ParseNode

	var opType

	func _init(parent: ParseNode, parser, opType = null):
		super(parent, parser)
		if opType == null:
			self.opType = parser.expect_symbol(Operator.op_types()).type
		else:
			self.opType = opType

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []
		info.append(tab(indentLevel, opType))
		return "".join(info)

	static func op_info(op) -> OperatorInfo:
		if !Operator.is_op(op):
			printerr("%s is not a valid operator" % op.name)
			return null

		#determine associativity and operands
		# each operand has
		var TokenType = TokenType

		match op:
			TokenType.Not, TokenType.UnaryMinus:
				return OperatorInfo.new(Associativity.Right, 30, 1)
			TokenType.Multiply, TokenType.Divide, TokenType.Modulo:
				return OperatorInfo.new(Associativity.Left, 20, 2)
			TokenType.Add, TokenType.Minus:
				return OperatorInfo.new(Associativity.Left, 15, 2)
			TokenType.GreaterThan, TokenType.LessThan, TokenType.GreaterThanOrEqualTo, TokenType.LessThanOrEqualTo:
				return OperatorInfo.new(Associativity.Left, 10, 2)
			TokenType.EqualTo, TokenType.EqualToOrAssign, TokenType.NotEqualTo:
				return OperatorInfo.new(Associativity.Left, 5, 2)
			TokenType.And:
				return OperatorInfo.new(Associativity.Left, 4, 2)
			TokenType.Or:
				return OperatorInfo.new(Associativity.Left, 3, 2)
			TokenType.Xor:
				return OperatorInfo.new(Associativity.Left, 2, 2)
			_:
				printerr("Unknown operator: %s" % op.name)

		return null

	static func is_op(type) -> bool:
		return type in op_types()

	static func op_types() -> Array:
		return [
			TokenType.Not,
			TokenType.UnaryMinus,
			TokenType.Add,
			TokenType.Minus,
			TokenType.Divide,
			TokenType.Multiply,
			TokenType.Modulo,
			TokenType.EqualToOrAssign,
			TokenType.EqualTo,
			TokenType.GreaterThan,
			TokenType.GreaterThanOrEqualTo,
			TokenType.LessThan,
			TokenType.LessThanOrEqualTo,
			TokenType.NotEqualTo,
			TokenType.And,
			TokenType.Or,
			TokenType.Xor
		]


class OperatorInfo:
	var associativity
	var precedence: int
	var arguments: int

	func _init(associativity, precedence: int, arguments: int):
		self.associativity = associativity
		self.precedence = precedence
		self.arguments = arguments


class Clause:
	var expression: ExpressionNode
	var statements: Array = []  #Statement

	func _init(expression: ExpressionNode = null, statements: Array = []):
		self.expression = expression
		self.statements = statements

	func tree_string(indentLevel: int) -> String:
		var info: PackedStringArray = []
		if expression != null:
			info.append(expression.tree_string(indentLevel))
		info.append(tab(indentLevel, "{"))
		for statement in statements:
			info.append(statement.tree_string(indentLevel + 1))

		info.append(tab(indentLevel, "}"))
		return "".join(info)

	func tab(indentLevel: int, input: String, newLine: bool = true) -> String:
		var tabPrecursor = ""
		var indentSpacing = 3
		for i in range(indentLevel):
			tabPrecursor += "|%*s" % [indentSpacing, ""]

		return "%*s %s%s" % [indentLevel, tabPrecursor, input, "" if !newLine else "\n"]
	# func tab(indentLevel : int , input : String,newLine : bool = true)->String:
	# 	return ("%*s| %s%s"% [indentLevel*2,"",input,("" if !newLine else "\n")])
