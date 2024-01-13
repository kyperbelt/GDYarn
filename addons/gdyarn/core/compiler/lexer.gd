class_name YarnLexer
extends Object

enum LexerMode{
	Header,
	Body,
	None,
}

const TokenType := YarnGlobals.TokenType

const LINE_COMENT: String = "//"
const FORWARD_SLASH: String = "/"

const LINE_SEPARATOR: String = "\n"


# STATES 
const BASE: String = "base"
const HEADER_TAG: String = "header_tag"
const HEADER_TAG_VALUE :String= "header_tag_value"
const COMMAND: String = "command"
const SHORTCUT:= &"shortcut"
const TAG: String = "tag"
const EXPRESSION: String = "expression"
const INLINE_EXPRESSION: String = "inline-expression"
const ASSIGNMENT: String = "assignment"
const DESTINATION: String = "destination"
const FORMAT_FUNCTION: String = "format"
# const FORMAT_FUNCTION_EXPRESSION: String = "format-expression"
const SHORTCUT_OPTION: String = "shortcut-option"
const SHORTCUT_OPTION_TAG: String = "shortcut-option-tag"
const COMMAND_OR_EXPRESSION: String = "command-or-expression"
const FORMAT_EXPRESSION: String = "format-expression"

# MISC
const WHITESPACE: String = "\\s*"


var error = OK

# regex patterns mapped to tokenTypes
var patterns: Dictionary = {}

# mode states 
var _current_mode_states : Dictionary = {}
var _body_mode_states: Dictionary = {}
var _header_mode_states : Dictionary = {}

var _default_state_name: String

var _current_state: LexerState

var _indent_stack: Array = []
var _should_track_indent: bool = false

var _mode: LexerMode = LexerMode.Header


func _init():
	__create_patterns()
	__create_body_mode_states()
	__create_header_mode_states()

func __create_patterns():
	patterns= {}
	patterns[TokenType.Text] = ".*"
	patterns[TokenType.HeaderDelimiter] = "---[\\s]*$"
	patterns[TokenType.NodeDelimiter] = "===[\\s]*$"
	patterns[TokenType.Number] = "\\-?[0-9]+(\\.[0-9]+)?"
	patterns[TokenType.Str] = '"([^"\\\\]*(?:\\.[^"\\\\]*)*)"'
	patterns[TokenType.TagMarker] = "#"  #"(#[a-zA-Z]+:)"
	patterns[TokenType.LeftParen] = "\\("
	patterns[TokenType.RightParen] = "\\)"
	patterns[TokenType.EqualTo] = "(==|is(?!\\w)|eq(?!\\w))"
	patterns[TokenType.EqualToOrAssign] = "(=|to(?!\\w))"
	patterns[TokenType.NotEqualTo] = "(\\!=|neq(?!\\w))"
	patterns[TokenType.GreaterThanOrEqualTo] = "(\\>=|gte(?!\\w))"
	patterns[TokenType.GreaterThan] = "(\\>|gt(?!\\w))"
	patterns[TokenType.LessThanOrEqualTo] = "(\\<=|lte(?!\\w))"
	patterns[TokenType.LessThan] = "(\\<|lt(?!\\w))" 
	patterns[TokenType.AddAssign] = "\\+="
	patterns[TokenType.MinusAssign] = "\\-="
	patterns[TokenType.MultiplyAssign] = "\\*="
	patterns[TokenType.DivideAssign] = "\\/="
	patterns[TokenType.Add] = "\\+"
	patterns[TokenType.Minus] = "\\-"
	patterns[TokenType.Multiply] = "\\*"
	patterns[TokenType.Divide] = "\\/"
	patterns[TokenType.Modulo] = "\\%"
	patterns[TokenType.And] = "(\\&\\&|and(?!\\w))"
	patterns[TokenType.Or] = "(\\|\\||or(?!\\w))"
	patterns[TokenType.Xor] = "(\\^|xor(?!\\w))"
	patterns[TokenType.Not] = "(\\!|not(?!\\w))"
	patterns[TokenType.Variable] = "\\$([A-Za-z0-9_\\.])+"
	patterns[TokenType.Comma] = "\\,"
	patterns[TokenType.TrueToken] = "true(?!\\w)"
	patterns[TokenType.FalseToken] = "false(?!\\w)"
	patterns[TokenType.NullToken] = "null(?!\\w)"
	patterns[TokenType.ValueType] = "((String|Number|Bool)(?!\\w))"
	patterns[TokenType.BeginCommand] = "\\<\\<"
	patterns[TokenType.EndCommand] = "\\>\\>"
	patterns[TokenType.Colon] = "\\:"
	patterns[TokenType.Jump] = "jump(?!\\w)"
	patterns[TokenType.Declare] = "declare(?!\\w)"
	patterns[TokenType.ExplicitTypeAssignment] = "(\\:\\:|as(?!\\w))"
	patterns[TokenType.ExpressionFunctionStart] = "\\{"
	patterns[TokenType.ExpressionFunctionEnd] = "\\}"
	patterns[TokenType.FormatFunctionStart] = "(?<!\\[)\\[(?!\\[)"
	patterns[TokenType.FormatFunctionEnd] = "\\]"
	patterns[TokenType.Identifier] = "[a-zA-Z_][a-zA-Z0-9_]*"
	patterns[TokenType.IfToken] = "if(?!\\w)"
	patterns[TokenType.ElseToken] = "else(?!\\w)"
	patterns[TokenType.ElseIf] = "elseif(?!\\w)"
	patterns[TokenType.EndIf] = "endif(?!\\w)"
	patterns[TokenType.Set] = "set(?!\\w)"
	patterns[TokenType.ShortcutOption] = "\\-\\>\\s*"
	pass

func __create_header_mode_states():
	_header_mode_states = {}	
	_header_mode_states[BASE] = LexerState.new(patterns)
	_header_mode_states[BASE].add_transition(TokenType.Identifier, HEADER_TAG)
	_header_mode_states[BASE].add_transition(TokenType.HeaderDelimiter).enter_lexer_mode(LexerMode.Body)

	_header_mode_states[HEADER_TAG] = LexerState.new(patterns)
	_header_mode_states[HEADER_TAG].add_transition(TokenType.Colon, HEADER_TAG_VALUE)

	_header_mode_states[HEADER_TAG_VALUE] = LexerState.new(patterns)
	_header_mode_states[HEADER_TAG_VALUE].add_transition(TokenType.Text, BASE)

	for state_key in _header_mode_states.keys():
		_header_mode_states[state_key].state_name = state_key

	pass



func __create_body_mode_states():


	#TODO: FIXME: Add transition from shortcut options and option links into inline expressions and format functions

	_body_mode_states = {}

	_body_mode_states[BASE] = LexerState.new(patterns)
	_body_mode_states[BASE].add_transition(TokenType.BeginCommand, COMMAND, true)
	_body_mode_states[BASE].add_transition(
		TokenType.ExpressionFunctionStart, INLINE_EXPRESSION, true
	)
	_body_mode_states[BASE].add_transition(TokenType.FormatFunctionStart, FORMAT_FUNCTION, true)
	_body_mode_states[BASE].add_transition(TokenType.ShortcutOption, SHORTCUT_OPTION)
	_body_mode_states[BASE].add_transition(TokenType.TagMarker, TAG)
	_body_mode_states[BASE].add_transition(TokenType.NodeDelimiter).enter_lexer_mode(LexerMode.Header)
	_body_mode_states[BASE].add_text_rule(TokenType.Text)

	#TODO: FIXME - Tags are not being proccessed properly this way. We must look for the format #{identifier}:{value}
	#              Possible solution is to add more transitions
	_body_mode_states[TAG] = LexerState.new(patterns)
	_body_mode_states[TAG].add_transition(TokenType.Identifier)
	_body_mode_states[TAG].add_transition(TokenType.Colon)

	_body_mode_states[SHORTCUT_OPTION] = LexerState.new(patterns)
	_body_mode_states[SHORTCUT_OPTION].track_indent = true
	_body_mode_states[SHORTCUT_OPTION].add_transition(TokenType.BeginCommand, EXPRESSION, true)
	_body_mode_states[SHORTCUT_OPTION].add_transition(
		TokenType.ExpressionFunctionStart, INLINE_EXPRESSION, true
	)
	_body_mode_states[SHORTCUT_OPTION].add_transition(
		TokenType.TagMarker, SHORTCUT_OPTION_TAG, true
	)
	_body_mode_states[SHORTCUT_OPTION].add_text_rule(TokenType.Text, BASE)

	_body_mode_states[SHORTCUT_OPTION_TAG] = LexerState.new(patterns)
	_body_mode_states[SHORTCUT_OPTION_TAG].add_transition(TokenType.Identifier, SHORTCUT_OPTION)

	_body_mode_states[COMMAND] = LexerState.new(patterns)
	_body_mode_states[COMMAND].add_transition(TokenType.IfToken, EXPRESSION)
	_body_mode_states[COMMAND].add_transition(TokenType.ElseToken)
	_body_mode_states[COMMAND].add_transition(TokenType.ElseIf, EXPRESSION)
	_body_mode_states[COMMAND].add_transition(TokenType.EndIf)
	_body_mode_states[COMMAND].add_transition(TokenType.Set, ASSIGNMENT)
	_body_mode_states[COMMAND].add_transition(TokenType.EndCommand, BASE, true)
	_body_mode_states[COMMAND].add_transition(TokenType.Identifier, COMMAND_OR_EXPRESSION)
	_body_mode_states[COMMAND].add_text_rule(TokenType.Text)

	_body_mode_states[COMMAND_OR_EXPRESSION] = LexerState.new(patterns)
	_body_mode_states[COMMAND_OR_EXPRESSION].add_transition(TokenType.LeftParen, EXPRESSION)
	_body_mode_states[COMMAND_OR_EXPRESSION].add_transition(TokenType.EndCommand, BASE, true)
	_body_mode_states[COMMAND_OR_EXPRESSION].add_text_rule(TokenType.Text)

	_body_mode_states[ASSIGNMENT] = LexerState.new(patterns)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.Variable)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.EqualToOrAssign, EXPRESSION)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.AddAssign, EXPRESSION)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.MinusAssign, EXPRESSION)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.MultiplyAssign, EXPRESSION)
	_body_mode_states[ASSIGNMENT].add_transition(TokenType.DivideAssign, EXPRESSION)

	_body_mode_states[FORMAT_FUNCTION] = LexerState.new(patterns)
	_body_mode_states[FORMAT_FUNCTION].add_transition(TokenType.FormatFunctionEnd, BASE, true)
	_body_mode_states[FORMAT_FUNCTION].add_transition(
		TokenType.ExpressionFunctionStart, FORMAT_EXPRESSION, true
	)
	_body_mode_states[FORMAT_FUNCTION].add_text_rule(TokenType.Text)

	_body_mode_states[FORMAT_EXPRESSION] = LexerState.new(patterns)
	_body_mode_states[FORMAT_EXPRESSION].add_transition(
		TokenType.ExpressionFunctionEnd, FORMAT_FUNCTION
	)
	form_expression_state(_body_mode_states[FORMAT_EXPRESSION])

	_body_mode_states[INLINE_EXPRESSION] = LexerState.new(patterns)
	_body_mode_states[INLINE_EXPRESSION].add_transition(TokenType.ExpressionFunctionEnd, BASE)
	form_expression_state(_body_mode_states[INLINE_EXPRESSION])

	_body_mode_states[EXPRESSION] = LexerState.new(patterns)
	_body_mode_states[EXPRESSION].add_transition(TokenType.EndCommand, BASE)
	# _body_mode_states[EXPRESSION].add_transition(TokenType.FormatFunctionEnd,BASE)
	form_expression_state(_body_mode_states[EXPRESSION])

	_default_state_name = BASE	

	for state_key in _body_mode_states.keys():
		_body_mode_states[state_key].state_name = state_key

	pass


func form_expression_state(expression_state):
	expression_state.add_transition(TokenType.Number)
	expression_state.add_transition(TokenType.Str)
	expression_state.add_transition(TokenType.LeftParen)
	expression_state.add_transition(TokenType.RightParen)
	expression_state.add_transition(TokenType.EqualTo)
	expression_state.add_transition(TokenType.EqualToOrAssign)
	expression_state.add_transition(TokenType.NotEqualTo)
	expression_state.add_transition(TokenType.GreaterThanOrEqualTo)
	expression_state.add_transition(TokenType.GreaterThan)
	expression_state.add_transition(TokenType.LessThanOrEqualTo)
	expression_state.add_transition(TokenType.LessThan)
	expression_state.add_transition(TokenType.Add)
	expression_state.add_transition(TokenType.Minus)
	expression_state.add_transition(TokenType.Multiply)
	expression_state.add_transition(TokenType.Divide)
	expression_state.add_transition(TokenType.Modulo)
	expression_state.add_transition(TokenType.And)
	expression_state.add_transition(TokenType.Or)
	expression_state.add_transition(TokenType.Xor)
	expression_state.add_transition(TokenType.Not)
	expression_state.add_transition(TokenType.Variable)
	expression_state.add_transition(TokenType.Comma)
	expression_state.add_transition(TokenType.TrueToken)
	expression_state.add_transition(TokenType.FalseToken)
	expression_state.add_transition(TokenType.NullToken)
	expression_state.add_transition(TokenType.Identifier)

func __initialize():
	_indent_stack.clear()
	_indent_stack.push_front(IntBoolPair.new(0, false))
	error = OK
	_should_track_indent = false
	set_mode(LexerMode.Header)
	# _current_state = _current_mode_states[_default_state_name]


func set_mode(mode: LexerMode):
	if (mode == LexerMode.None): # do nothing/continue same mode
		return

	print("entering mode %s" % LexerMode.keys()[mode])
	self._mode = mode
	if (mode == LexerMode.Header):
		_current_mode_states = _header_mode_states
		_default_state_name = BASE
	else:
		_current_mode_states = _body_mode_states
		_default_state_name = BASE

	_current_state = _current_mode_states[_default_state_name]


func tokenize(text: String, line_number:int=0) -> Array[Token]:
	__initialize()

	var tokens: Array[Token] = []

	var lines: PackedStringArray = text.split(LINE_SEPARATOR)
	lines.append("")

	# var lineNumber : int = 1

	for line in lines:
		if error != OK:
			break
		tokens += tokenize_line(line, line_number)
		line_number += 1

	var endOfInput: Token = Token.new(
		TokenType.EndOfInput, _current_state, line_number, 0
	)
	tokens.append(endOfInput)

	return tokens


func tokenize_line(line: String, line_number: int) -> Array[Token]:
	enter_state(_current_mode_states[_default_state_name])
	var token_stack: Array[Token] = []

	var fresh_line = line.replace("\t", "    ").replace("\r", "")

	#record indentation
	var indentation = line_indentation(fresh_line)
	# printerr("line indentation of ((%s)) is %d !!!!!%s" %[freshLine, indentation,str(_should_track_indent)])
	var prev_indentation: IntBoolPair = _indent_stack.front()

	if _should_track_indent && indentation > prev_indentation.key:
		#we add an indenation token to record indent level
		_indent_stack.push_front(IntBoolPair.new(indentation, true))

		var indent: Token = Token.new(
			TokenType.Indent, _current_state, line_number, prev_indentation.key
		)
		indent.value = "%*s" % [indentation - prev_indentation.key, "0"]

		_should_track_indent = false
		token_stack.push_front(indent)

	elif indentation < prev_indentation.key:
		#de-indent and then emit indentaiton token

		while indentation < _indent_stack.front().key:
			var top: IntBoolPair = _indent_stack.pop_front()
			if top.value:
				var deIndent: Token = Token.new(
					TokenType.Dedent, _current_state, line_number, 0
				)
				token_stack.push_front(deIndent)

	var column: int = indentation

	var whitespace: RegEx = RegEx.new()
	var _ok = whitespace.compile(WHITESPACE)
	if _ok != OK:
		printerr("unable to compile regex WHITESPACE")
		error = ERR_COMPILATION_FAILED
		return []


	while column < fresh_line.length():
		if fresh_line.substr(column).begins_with(LINE_COMENT):
			break

		var matched: bool = false


		for rule in _current_state.rules:
			var found: RegExMatch = rule.regex.search(fresh_line, column)

			if !found:
				continue

			var token_text: String

			if rule.token_type == TokenType.Text:
				#if this is text then we back up to the most recent
				#delimiting token and treat everything from there as text.

				var start_index: int = indentation

				if token_stack.size() > 0:
					while token_stack.front().type == TokenType.Identifier:
						var t = token_stack.pop_front()
						# if t.type == TokenType.Indent:
						# printerr("popedOfff some indentation")

					var start_delimit_token: Token = token_stack.front()
					start_index = start_delimit_token.column

					if start_delimit_token.type == TokenType.Indent:
						start_index += start_delimit_token.value.length()
					if start_delimit_token.type == TokenType.Dedent:
						start_index = indentation
				#

				column = start_index
				var end_index: int = found.get_start() + found.get_string().length()

				token_text = fresh_line.substr(start_index, end_index - start_index)

			else:
				token_text = found.get_string()

			column += token_text.length()

			#pre-proccess string
			if rule.token_type== TokenType.Str:
				token_text = token_text.substr(1, token_text.length() - 2)
				token_text = token_text.replace("\\\\", "\\")
				token_text = token_text.replace('\\"', '"')

			var token: Token = Token.new(
				rule.token_type, _current_state, line_number, column, token_text
			)
			token.delimits_text= rule.delimits_text

			token_stack.push_front(token)

			set_mode(rule.enter_mode)

			if rule.enter_state != null && rule.enter_state.length() > 0:
				if !_current_mode_states.has(rule.enter_state):
					printerr(
						(
							"Tried to enter unknown State[%s] - line(%s) col(%s)"
							% [rule.enter_state, line_number, column]
						)
					)
					error = ERR_DOES_NOT_EXIST
					return []

				enter_state(_current_mode_states[rule.enter_state])

				if _should_track_indent:
					if _indent_stack.front().key < indentation:
						_indent_stack.append(IntBoolPair.new(indentation, false))
			else:
				printerr(
					(
						"Rule[%s] did not specify a state to enter - line(%s) col(%s)"
						% [YarnGlobals.token_name(rule.token_type), line_number, column]
					)
				)

			matched = true
			break

		if !matched:
			printerr(
				(
					"<<%s::%s>> expectedTokens [%s] - line(%s) col(%s) for text(%s)"
					% [get_mode_name(),_current_state.state_name, _current_state.expected_tokens_string(), line_number, column, fresh_line]
				)
			)
			error = ERR_INVALID_DATA
			return []

		var lastWhiteSpace: RegExMatch = whitespace.search(fresh_line, column)
		if lastWhiteSpace:
			column += lastWhiteSpace.get_string().length()

	# if tokenStack.size() >= 1 && (tokenStack.front().type == TokenType.Text || tokenStack.front().type == YarnGlobals.TokenType.Identifier):
	# 	tokenStack.push_front(Token.new(TokenType.EndOfLine,_current_state,lineNumber,column,"break"))
	token_stack.reverse()

	return token_stack


func line_indentation(line: String) -> int:
	var indentRegex: RegEx = RegEx.new()
	indentRegex.compile("^(?:\\s*)")

	var found: RegExMatch = indentRegex.search(line)

	if !found || found.get_string().length() <= 0:
		return 0

	return found.get_string().length()


func enter_state(state: LexerState):
	_current_state = state
	_should_track_indent = true if _current_state.track_indent else _should_track_indent


class Token:
	var type: TokenType
	var value: String

	var line_number: int
	var column: int

	var delimits_text: bool = false
	var param_count: int
	var lexer_state: String

	func _init(
		type: TokenType, state: LexerState, line_number: int = -1, column: int = -1, value: String = ""
	):
		self.type = type
		self.lexer_state = state.state_name
		self.line_number = line_number
		self.column = column
		self.value = value

	func _to_string():
		return (
			"%s (%s) at %s:%s (state: %s)"
			% [YarnGlobals.token_name(type), value, line_number, column, lexer_state]
		)


class LexerState:
	var state_name: String
	var patterns: Dictionary
	var rules: Array[Rule] = []
	var track_indent: bool = false

	func _init(patterns):
		self.patterns = patterns

	func add_transition(type: int, state: String = "", delimit_text: bool = false) -> Rule:
		var pattern = "\\G%s" % patterns[type]
		# print("pattern = %s" % pattern)
		var rule = Rule.new(type, pattern, state, delimit_text)
		rules.append(rule)
		return rule

	func add_text_rule(type: int, state: String = "") -> Rule:
		if contains_text_rule():
			printerr("State already contains Text rule")
			return null

		var delimiters: Array[String] = []
		for rule in rules:
			if rule.delimits_text:
				delimiters.append("%s" % rule.regex.get_pattern().substr(2))

		var pattern = "\\G((?!%s).)*" % ["|".join(PackedStringArray(delimiters))]
		var rule: Rule = add_transition(type, state)
		rule.regex = RegEx.new()
		rule.regex.compile(pattern)
		rule.is_text_rule = true
		return rule

	func expected_tokens_string() -> String:
		var result = " "
		for rule in rules:
			result += YarnGlobals.token_name(rule.token_type) + " "
		return result

	func contains_text_rule() -> bool:
		for rule in rules:
			if rule.is_text_rule:
				return true
		return false


class Rule:
	var regex: RegEx

	var enter_state: String
	var enter_mode: LexerMode = LexerMode.None
	var token_type: TokenType 
	var is_text_rule: bool
	var delimits_text: bool

	func _init(type: TokenType, regex: String, enter_state: String, delimits_text: bool):
		self.token_type = type
		self.regex = RegEx.new()
		self.regex.compile(regex)
		self.enter_state = enter_state
		self.delimits_text = delimits_text

	func enter_lexer_mode(mode: LexerMode)->void:
		enter_mode = mode
		
	func _to_string() -> String:
		return "[Rule : %s - %s]" % [YarnGlobals.token_name(token_type), regex]


class IntBoolPair:
	var key: int
	var value: bool

	func _init(key: int, value: bool):
		self.key = key
		self.value = value

func get_mode_name()->String:
	return LexerMode.keys()[_mode]
