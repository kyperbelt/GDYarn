extends GutTest

const TokenType = YarnGlobals.TokenType

##########################
## TEST HEADER
##########################

var header_tags_params :Array[Array] = [
    ["title:Start",
    TokenType.Identifier, TokenType.Colon, TokenType.Text],
    ["pos:1",TokenType.Identifier, TokenType.Colon, TokenType.Text]
]

func test_header_tags(p=use_parameters(header_tags_params)):
    var lexer: YarnLexer = YarnLexer.new()
    lexer.__initialize()
    var tokens:=lexer.tokenize_line(p[0], 0)
    for token in tokens:
        gut.p("token:%s" % YarnGlobals.token_name(token.type))
    var correct_size :bool= tokens.size() == p.size()-1
    assert_eq(tokens.size(), p.size()-1)
    
    if!correct_size:
        return

    for i in range(1, p.size()):
        assert_eq(YarnGlobals.token_name(tokens[i-1].type), YarnGlobals.token_name(p[i]))

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
