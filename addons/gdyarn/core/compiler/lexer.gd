const LINE_COMENT: String = "//"
const FORWARD_SLASH: String = "/"

const LINE_SEPARATOR: String = "\n"

const BASE: String = "base"
const COMMAND: String = "command"
const LINK: String = "link"
const SHORTCUT: String = "shortcut"
const TAG: String = "tag"
const EXPRESSION: String = "expression"
const ASSIGNMENT: String = "assignment"
const OPTION: String = "option"
const DESTINATION: String = "destination"
const FORMAT_FUNCTION: String = "format"
const WHITESPACE: String = "\\s*"

var error = OK

var _states: Dictionary = {}
var _defaultState: LexerState

var _currentState: LexerState

var _indentStack: Array = []
var _shouldTrackIndent: bool = false


func _init():
	create_states()


func create_states():
	var patterns: Dictionary = {}
	patterns[YarnGlobals.TokenType.Text] = ".*"

	patterns[YarnGlobals.TokenType.Number] = "\\-?[0-9]+(\\.[0-9]+)?"
	patterns[YarnGlobals.TokenType.Str] = '"([^"\\\\]*(?:\\.[^"\\\\]*)*)"'
	patterns[YarnGlobals.TokenType.TagMarker] = "#"  #"(#[a-zA-Z]+:)"
	patterns[YarnGlobals.TokenType.LeftParen] = "\\("
	patterns[YarnGlobals.TokenType.RightParen] = "\\)"
	patterns[YarnGlobals.TokenType.EqualTo] = "(==|is(?!\\w)|eq(?!\\w))"
	patterns[YarnGlobals.TokenType.EqualToOrAssign] = "(=|to(?!\\w))"
	patterns[YarnGlobals.TokenType.NotEqualTo] = "(\\!=|neq(?!\\w))"
	patterns[YarnGlobals.TokenType.GreaterThanOrEqualTo] = "(\\>=|gte(?!\\w))"
	patterns[YarnGlobals.TokenType.GreaterThan] = "(\\>|gt(?!\\w))"
	patterns[YarnGlobals.TokenType.LessThanOrEqualTo] = "(\\<=|lte(?!\\w))"
	patterns[YarnGlobals.TokenType.LessThan] = "(\\<|lt(?!\\w))"
	patterns[YarnGlobals.TokenType.AddAssign] = "\\+="
	patterns[YarnGlobals.TokenType.MinusAssign] = "\\-="
	patterns[YarnGlobals.TokenType.MultiplyAssign] = "\\*="
	patterns[YarnGlobals.TokenType.DivideAssign] = "\\/="
	patterns[YarnGlobals.TokenType.Add] = "\\+"
	patterns[YarnGlobals.TokenType.Minus] = "\\-"
	patterns[YarnGlobals.TokenType.Multiply] = "\\*"
	patterns[YarnGlobals.TokenType.Divide] = "\\/"
	patterns[YarnGlobals.TokenType.Modulo] = "\\%"
	patterns[YarnGlobals.TokenType.And] = "(\\&\\&|and(?!\\w))"
	patterns[YarnGlobals.TokenType.Or] = "(\\|\\||or(?!\\w))"
	patterns[YarnGlobals.TokenType.Xor] = "(\\^|xor(?!\\w))"
	patterns[YarnGlobals.TokenType.Not] = "(\\!|not(?!\\w))"
	patterns[YarnGlobals.TokenType.Variable] = "\\$([A-Za-z0-9_\\.])+"
	patterns[YarnGlobals.TokenType.Comma] = "\\,"
	patterns[YarnGlobals.TokenType.TrueToken] = "true(?!\\w)"
	patterns[YarnGlobals.TokenType.FalseToken] = "false(?!\\w)"
	patterns[YarnGlobals.TokenType.NullToken] = "null(?!\\w)"
	patterns[YarnGlobals.TokenType.BeginCommand] = "\\<\\<"
	patterns[YarnGlobals.TokenType.EndCommand] = "\\>\\>"
	patterns[YarnGlobals.TokenType.OptionStart] = "\\[\\["
	patterns[YarnGlobals.TokenType.OptionEnd] = "\\]\\]"
	patterns[YarnGlobals.TokenType.OptionDelimit] = "\\|"
	patterns[YarnGlobals.TokenType.ExpressionFunctionStart] = "\\{"
	patterns[YarnGlobals.TokenType.ExpressionFunctionEnd] = "\\}"
	patterns[YarnGlobals.TokenType.FormatFunctionStart] = "(?<!\\[)\\[(?!\\[)"
	patterns[YarnGlobals.TokenType.FormatFunctionEnd] = "\\]"
	patterns[YarnGlobals.TokenType.Identifier] = "[a-zA-Z0-9_:\\.]+"
	patterns[YarnGlobals.TokenType.IfToken] = "if(?!\\w)"
	patterns[YarnGlobals.TokenType.ElseToken] = "else(?!\\w)"
	patterns[YarnGlobals.TokenType.ElseIf] = "elseif(?!\\w)"
	patterns[YarnGlobals.TokenType.EndIf] = "endif(?!\\w)"
	patterns[YarnGlobals.TokenType.Set] = "set(?!\\w)"
	patterns[YarnGlobals.TokenType.ShortcutOption] = "\\-\\>\\s*"

	#compound states
	var shortcut_option: String = SHORTCUT + "-" + OPTION
	var shortcut_option_tag: String = shortcut_option + "-" + TAG
	var command_or_expression: String = COMMAND + "-" + "or" + "-" + EXPRESSION
	var link_destination: String = LINK + "-" + DESTINATION
	var format_expression: String = FORMAT_FUNCTION + "-" + EXPRESSION
	var inline_expression: String = "inline" + "-" + EXPRESSION

	#TODO: FIXME: Add transition from shortcut options and option links into inline expressions and format functions

	_states = {}

	_states[BASE] = LexerState.new(patterns)
	_states[BASE].add_transition(YarnGlobals.TokenType.BeginCommand, COMMAND, true)
	_states[BASE].add_transition(
		YarnGlobals.TokenType.ExpressionFunctionStart, inline_expression, true
	)
	_states[BASE].add_transition(YarnGlobals.TokenType.FormatFunctionStart, FORMAT_FUNCTION, true)
	_states[BASE].add_transition(YarnGlobals.TokenType.OptionStart, LINK, true)
	_states[BASE].add_transition(YarnGlobals.TokenType.ShortcutOption, shortcut_option)
	_states[BASE].add_transition(YarnGlobals.TokenType.TagMarker, TAG, true)
	_states[BASE].add_text_rule(YarnGlobals.TokenType.Text)

	#TODO: FIXME - Tags are not being proccessed properly this way. We must look for the format #{identifier}:{value}
	#              Possible solution is to add more transitions
	_states[TAG] = LexerState.new(patterns)
	_states[TAG].add_transition(YarnGlobals.TokenType.Identifier, BASE)

	_states[shortcut_option] = LexerState.new(patterns)
	_states[shortcut_option].track_indent = true
	_states[shortcut_option].add_transition(YarnGlobals.TokenType.BeginCommand, EXPRESSION, true)
	_states[shortcut_option].add_transition(
		YarnGlobals.TokenType.ExpressionFunctionStart, inline_expression, true
	)
	_states[shortcut_option].add_transition(
		YarnGlobals.TokenType.TagMarker, shortcut_option_tag, true
	)
	_states[shortcut_option].add_text_rule(YarnGlobals.TokenType.Text, BASE)

	_states[shortcut_option_tag] = LexerState.new(patterns)
	_states[shortcut_option_tag].add_transition(YarnGlobals.TokenType.Identifier, shortcut_option)

	_states[COMMAND] = LexerState.new(patterns)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.IfToken, EXPRESSION)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.ElseToken)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.ElseIf, EXPRESSION)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.EndIf)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.Set, ASSIGNMENT)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.EndCommand, BASE, true)
	_states[COMMAND].add_transition(YarnGlobals.TokenType.Identifier, command_or_expression)
	_states[COMMAND].add_text_rule(YarnGlobals.TokenType.Text)

	_states[command_or_expression] = LexerState.new(patterns)
	_states[command_or_expression].add_transition(YarnGlobals.TokenType.LeftParen, EXPRESSION)
	_states[command_or_expression].add_transition(YarnGlobals.TokenType.EndCommand, BASE, true)
	_states[command_or_expression].add_text_rule(YarnGlobals.TokenType.Text)

	_states[ASSIGNMENT] = LexerState.new(patterns)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.Variable)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.EqualToOrAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.AddAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.MinusAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.MultiplyAssign, EXPRESSION)
	_states[ASSIGNMENT].add_transition(YarnGlobals.TokenType.DivideAssign, EXPRESSION)

	_states[FORMAT_FUNCTION] = LexerState.new(patterns)
	_states[FORMAT_FUNCTION].add_transition(YarnGlobals.TokenType.FormatFunctionEnd, BASE, true)
	_states[FORMAT_FUNCTION].add_transition(
		YarnGlobals.TokenType.ExpressionFunctionStart, format_expression, true
	)
	_states[FORMAT_FUNCTION].add_text_rule(YarnGlobals.TokenType.Text)

	_states[format_expression] = LexerState.new(patterns)
	_states[format_expression].add_transition(
		YarnGlobals.TokenType.ExpressionFunctionEnd, FORMAT_FUNCTION
	)
	form_expression_state(_states[format_expression])

	_states[inline_expression] = LexerState.new(patterns)
	_states[inline_expression].add_transition(YarnGlobals.TokenType.ExpressionFunctionEnd, BASE)
	form_expression_state(_states[inline_expression])

	_states[EXPRESSION] = LexerState.new(patterns)
	_states[EXPRESSION].add_transition(YarnGlobals.TokenType.EndCommand, BASE)
	# _states[EXPRESSION].add_transition(YarnGlobals.TokenType.FormatFunctionEnd,BASE)
	form_expression_state(_states[EXPRESSION])

	_states[LINK] = LexerState.new(patterns)
	_states[LINK].add_transition(YarnGlobals.TokenType.OptionEnd, BASE, true)
	_states[LINK].add_transition(YarnGlobals.TokenType.ExpressionFunctionStart, "link-ee", true)
	_states[LINK].add_transition(YarnGlobals.TokenType.FormatFunctionStart, "link-ff", true)
	_states[LINK].add_transition(YarnGlobals.TokenType.FormatFunctionEnd, LINK, true)
	_states[LINK].add_transition(YarnGlobals.TokenType.OptionDelimit, link_destination, true)
	_states[LINK].add_text_rule(YarnGlobals.TokenType.Text)

	_states["link-ff"] = LexerState.new(patterns)
	_states["link-ff"].add_transition(YarnGlobals.TokenType.FormatFunctionEnd, LINK, true)
	_states["link-ff"].add_transition(
		YarnGlobals.TokenType.ExpressionFunctionStart, "link-ee", true
	)
	_states["link-ff"].add_text_rule(YarnGlobals.TokenType.Text)

	_states["link-ee"] = LexerState.new(patterns)
	_states["link-ee"].add_transition(YarnGlobals.TokenType.ExpressionFunctionEnd, LINK)
	form_expression_state(_states["link-ee"])

	_states[link_destination] = LexerState.new(patterns)
	_states[link_destination].add_transition(YarnGlobals.TokenType.Identifier)
	_states[link_destination].add_transition(YarnGlobals.TokenType.OptionEnd, BASE)

	_defaultState = _states[BASE]

	for stateKey in _states.keys():
		_states[stateKey].stateName = stateKey

	pass


func form_expression_state(expressionState):
	expressionState.add_transition(YarnGlobals.TokenType.Number)
	expressionState.add_transition(YarnGlobals.TokenType.Str)
	expressionState.add_transition(YarnGlobals.TokenType.LeftParen)
	expressionState.add_transition(YarnGlobals.TokenType.RightParen)
	expressionState.add_transition(YarnGlobals.TokenType.EqualTo)
	expressionState.add_transition(YarnGlobals.TokenType.EqualToOrAssign)
	expressionState.add_transition(YarnGlobals.TokenType.NotEqualTo)
	expressionState.add_transition(YarnGlobals.TokenType.GreaterThanOrEqualTo)
	expressionState.add_transition(YarnGlobals.TokenType.GreaterThan)
	expressionState.add_transition(YarnGlobals.TokenType.LessThanOrEqualTo)
	expressionState.add_transition(YarnGlobals.TokenType.LessThan)
	expressionState.add_transition(YarnGlobals.TokenType.Add)
	expressionState.add_transition(YarnGlobals.TokenType.Minus)
	expressionState.add_transition(YarnGlobals.TokenType.Multiply)
	expressionState.add_transition(YarnGlobals.TokenType.Divide)
	expressionState.add_transition(YarnGlobals.TokenType.Modulo)
	expressionState.add_transition(YarnGlobals.TokenType.And)
	expressionState.add_transition(YarnGlobals.TokenType.Or)
	expressionState.add_transition(YarnGlobals.TokenType.Xor)
	expressionState.add_transition(YarnGlobals.TokenType.Not)
	expressionState.add_transition(YarnGlobals.TokenType.Variable)
	expressionState.add_transition(YarnGlobals.TokenType.Comma)
	expressionState.add_transition(YarnGlobals.TokenType.TrueToken)
	expressionState.add_transition(YarnGlobals.TokenType.FalseToken)
	expressionState.add_transition(YarnGlobals.TokenType.NullToken)
	expressionState.add_transition(YarnGlobals.TokenType.Identifier)


func tokenize(text: String, lineNumber) -> Array:
	_indentStack.clear()
	_indentStack.push_front(IntBoolPair.new(0, false))
	_shouldTrackIndent = false

	var tokens: Array = []

	_currentState = _defaultState

	var lines: PoolStringArray = text.split(LINE_SEPARATOR)
	lines.append("")

	# var lineNumber : int = 1

	for line in lines:
		if error != OK:
			break
		tokens += tokenize_line(line, lineNumber)
		lineNumber += 1

	var endOfInput: Token = Token.new(
		YarnGlobals.TokenType.EndOfInput, _currentState, lineNumber, 0
	)
	tokens.append(endOfInput)

	return tokens


func tokenize_line(line: String, lineNumber: int) -> Array:
	var tokenStack: Array = []

	var freshLine = line.replace("\t", "    ").replace("\r", "")

	#record indentation
	var indentation = line_indentation(freshLine)
	# printerr("line indentation of ((%s)) is %d !!!!!%s" %[freshLine, indentation,str(_shouldTrackIndent)])
	var prevIndentation: IntBoolPair = _indentStack.front()

	if _shouldTrackIndent && indentation > prevIndentation.key:
		#we add an indenation token to record indent level
		_indentStack.push_front(IntBoolPair.new(indentation, true))

		var indent: Token = Token.new(
			YarnGlobals.TokenType.Indent, _currentState, lineNumber, prevIndentation.key
		)
		indent.value = "%*s" % [indentation - prevIndentation.key, "0"]

		_shouldTrackIndent = false
		tokenStack.push_front(indent)

	elif indentation < prevIndentation.key:
		#de-indent and then emit indentaiton token

		while indentation < _indentStack.front().key:
			var top: IntBoolPair = _indentStack.pop_front()
			if top.value:
				var deIndent: Token = Token.new(
					YarnGlobals.TokenType.Dedent, _currentState, lineNumber, 0
				)
				tokenStack.push_front(deIndent)

	var column: int = indentation

	var whitespace: RegEx = RegEx.new()
	var _ok = whitespace.compile(WHITESPACE)
	if _ok != OK:
		printerr("unable to compile regex WHITESPACE")
		error = ERR_COMPILATION_FAILED
		return []

	while column < freshLine.length():
		if freshLine.substr(column).begins_with(LINE_COMENT):
			break

		var matched: bool = false

		for rule in _currentState.rules:
			var found: RegExMatch = rule.regex.search(freshLine, column)

			if !found:
				continue

			var tokenText: String

			if rule.tokenType == YarnGlobals.TokenType.Text:
				#if this is text then we back up to the most recent
				#delimiting token and treat everything from there as text.

				var startIndex: int = indentation

				if tokenStack.size() > 0:
					while tokenStack.front().type == YarnGlobals.TokenType.Identifier:
						var t = tokenStack.pop_front()
						# if t.type == YarnGlobals.TokenType.Indent:
						# printerr("popedOfff some indentation")

					var startDelimitToken: Token = tokenStack.front()
					startIndex = startDelimitToken.column

					if startDelimitToken.type == YarnGlobals.TokenType.Indent:
						startIndex += startDelimitToken.value.length()
					if startDelimitToken.type == YarnGlobals.TokenType.Dedent:
						startIndex = indentation
				#

				column = startIndex
				var endIndex: int = found.get_start() + found.get_string().length()

				tokenText = freshLine.substr(startIndex, endIndex - startIndex)

			else:
				tokenText = found.get_string()

			column += tokenText.length()

			#pre-proccess string
			if rule.tokenType == YarnGlobals.TokenType.Str:
				tokenText = tokenText.substr(1, tokenText.length() - 2)
				tokenText = tokenText.replace("\\\\", "\\")
				tokenText = tokenText.replace('\\"', '"')

			var token: Token = Token.new(
				rule.tokenType, _currentState, lineNumber, column, tokenText
			)
			token.delimitsText = rule.delimitsText

			tokenStack.push_front(token)

			if rule.enterState != null && rule.enterState.length() > 0:
				if !_states.has(rule.enterState):
					printerr(
						(
							"Tried to enter unknown State[%s] - line(%s) col(%s)"
							% [rule.enterState, lineNumber, column]
						)
					)
					error = ERR_DOES_NOT_EXIST
					return []

				enter_state(_states[rule.enterState])

				if _shouldTrackIndent:
					if _indentStack.front().key < indentation:
						_indentStack.append(IntBoolPair.new(indentation, false))

			matched = true
			break

		if !matched:
			printerr(
				(
					"expectedTokens [%s] - line(%s) col(%s)"
					% [_currentState.expected_tokens_string(), lineNumber, column]
				)
			)
			error = ERR_INVALID_DATA
			return []

		var lastWhiteSpace: RegExMatch = whitespace.search(freshLine, column)
		if lastWhiteSpace:
			column += lastWhiteSpace.get_string().length()

	# if tokenStack.size() >= 1 && (tokenStack.front().type == YarnGlobals.TokenType.Text || tokenStack.front().type == YarnGlobals.TokenType.Identifier):
	# 	tokenStack.push_front(Token.new(YarnGlobals.TokenType.EndOfLine,_currentState,lineNumber,column,"break"))
	tokenStack.invert()

	return tokenStack


func line_indentation(line: String) -> int:
	var indentRegex: RegEx = RegEx.new()
	indentRegex.compile("^(?:\\s*)")

	var found: RegExMatch = indentRegex.search(line)

	if !found || found.get_string().length() <= 0:
		return 0

	return found.get_string().length()


func enter_state(state: LexerState):
	_currentState = state
	_shouldTrackIndent = true if _currentState.track_indent else _shouldTrackIndent


class Token:
	var type: int
	var value: String

	var lineNumber: int
	var column: int
	var text: String

	var delimitsText: bool = false
	var paramCount: int
	var lexerState: String

	func _init(
		type: int, state: LexerState, lineNumber: int = -1, column: int = -1, value: String = ""
	):
		self.type = type
		self.lexerState = state.stateName
		self.lineNumber = lineNumber
		self.column = column
		self.value = value

	func _to_string():
		return (
			"%s (%s) at %s:%s (state: %s)"
			% [YarnGlobals.token_name(type), value, lineNumber, column, lexerState]
		)


class LexerState:
	var stateName: String
	var patterns: Dictionary
	var rules: Array = []
	var track_indent: bool = false

	func _init(patterns):
		self.patterns = patterns

	func add_transition(type: int, state: String = "", delimitText: bool = false) -> Rule:
		var pattern = "\\G%s" % patterns[type]
		# print("pattern = %s" % pattern)
		var rule = Rule.new(type, pattern, state, delimitText)
		rules.append(rule)
		return rule

	func add_text_rule(type: int, state: String = "") -> Rule:
		if contains_text_rule():
			printerr("State already contains Text rule")
			return null

		var delimiters: Array = []
		for rule in rules:
			if rule.delimitsText:
				delimiters.append("%s" % rule.regex.get_pattern().substr(2))

		var pattern = "\\G((?!%s).)*" % [PoolStringArray(delimiters).join("|")]
		var rule: Rule = add_transition(type, state)
		rule.regex = RegEx.new()
		rule.regex.compile(pattern)
		rule.isTextRule = true
		return rule

	func expexted_tokens_string() -> String:
		var result = ""
		for rule in rules:
			result += "" + YarnGlobals.token_name(rule.tokenType)
		return result

	func contains_text_rule() -> bool:
		for rule in rules:
			if rule.isTextRule:
				return true
		return false


class Rule:
	var regex: RegEx

	var enterState: String
	var tokenType: int
	var isTextRule: bool
	var delimitsText: bool

	func _init(type: int, regex: String, enterState: String, delimitsText: bool):
		self.tokenType = type
		self.regex = RegEx.new()
		self.regex.compile(regex)
		self.enterState = enterState
		self.delimitsText = delimitsText

	func _to_string():
		return "[Rule : %s - %s]" % [YarnGlobals.token_name(tokenType), regex]


class IntBoolPair:
	var key: int
	var value: bool

	func _init(key: int, value: bool):
		self.key = key
		self.value = value
