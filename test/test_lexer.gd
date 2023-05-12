extends GutTest


##########################
## TEST HEADER
##########################

func test_header_tags():
	assert_eq(true, false)

func test_header_with_body_seperator(): 
	assert_eq(true, false)

##########################
## TEST COMMANDS 
##########################
func test_command_if():
	var lexer: YarnLexer = YarnLexer.new()
	lexer.__initialize()
	var tokens:=lexer.tokenize_line("<<if 3 > 1>>", 0)
	for token in tokens:
		gut.p("token:%s" % YarnGlobals.token_name(token.type))
	assert_eq(tokens.size(), 3)
	pass

func test_command_if_else():
	assert_eq(true, false)

func test_command_else():
	assert_eq(true, false)

func test_command_endif():
	assert_eq(true, false)

func test_command_set():
	assert_eq(true, false)

func test_command_declare():
	assert_eq(true, false)

func test_jump_command():
	assert_eq(true, false)

func test_command_stop():
	assert_eq(true, false)

##########################
## TEST EXPRESSIONS
##########################

func test_expressions():
	assert_eq(true, false)

func test_function_call():
	assert_eq(true, false)

func test_identifier():
	assert_eq(true, false)

##########################
## TEXT 
##########################

func test_tags():
	assert_eq(true, false)

func test_shortcut_options():
	assert_eq(true, false)

func test_format_function():
	assert_eq(true, false)

func test_line_text():
	var lexer: YarnLexer = YarnLexer.new()
	lexer.__initialize()
	var tokens:=lexer.tokenize_line("{$name}, you are a bold one.", 0)
	for token in tokens:
		gut.p("token:%s" % YarnGlobals.token_name(token.type))
	assert_eq(tokens.size(), 4)
