tool
extends Node


const YarnCompiler = preload("res://addons/gdyarn/core/compiler/compiler.gd")
const YarnProgram = YarnCompiler.YarnProgram
const YarnGlobals = YarnCompiler.YarnGlobals
const DisplayInterface = preload("res://addons/gdyarn/yarn_gui.gd")

const LineInfo = YarnCompiler.LineInfo
const Line = preload("res://addons/gdyarn/core/dialogue/line.gd")


# String is a path to a PNG file in the global filesystem.
export(Resource) var _compiledYarnProgram setget set_program

export(String) var _startNode = "Start"

export(bool) var _autoStart = false

export(NodePath) var _variableStorage

export(NodePath) var _displayInterface

export(bool) var _showTokens = false setget set_tokens
export(bool) var _printSyntaxTree = false setget set_ast
export(String) var locale = "en_US" setget set_locale

export(String, DIR) var filepath = "" setget set_filepath

var _stringTable : Dictionary = {}#localization support to come

signal path_changed(path)
signal locale_changed(locale)
signal debug_changed(tokens,ast)

#dialogue
var _dialogue
var _dialogueStarted : bool = false

#display interface
var display : DisplayInterface

#dialogue flow control
var next_line : String = ""#extra line will be empty when there is no next line
var commandHandlers :  Dictionary = {} #funcRef map for text commands


func _ready():
	if Engine.editor_hint:
		#connect("script_changed",self,"set_file")
		if filepath.empty():
			set_filepath(get_tree().edited_scene_root.filename.get_base_dir())
		pass 
	else:
		var YarnDialogue = load("res://addons/gdyarn/core/dialogue.gd")
		_dialogue = YarnDialogue.new(get_node(_variableStorage))
		_dialogue.get_vm().lineHandler = funcref(self,"_handle_line")
		_dialogue.get_vm().optionsHandler = funcref(self,"_handle_options")
		_dialogue.get_vm().commandHandler = funcref(self,"_handle_command")
		_dialogue.get_vm().nodeCompleteHandler = funcref(self,"_handle_node_complete")
		_dialogue.get_vm().dialogueCompleteHandler = funcref(self,"_handle_dialogue_complete")
		_dialogue.get_vm().nodeStartHandler = funcref(self,"_handle_node_start")

		var result : Array = _compiledYarnProgram._load_compiled_program()
		var program : YarnProgram = _compiledYarnProgram.program
		_stringTable = program.yarnStrings

		_dialogue.set_program(program)

		display = get_node(_displayInterface)

		display._dialogue = _dialogue
		display._dialogueRunner = self

		if(_autoStart):
			start()

func set_tokens(value):
	_showTokens = value
	emit_signal("debug_changed",_showTokens,_printSyntaxTree)

func set_ast(value):
	_printSyntaxTree = value
	emit_signal("debug_changed",_showTokens,_printSyntaxTree)

func set_locale(value):
	if value in TranslationServer.get_loaded_locales():
		locale = value
		emit_signal("locale_changed",value)
	else:
		printerr("[%s] is not a valid locale id.")

func set_filepath(path):
	filepath = path
	if _compiledYarnProgram:
		emit_signal("path_changed", path)

func set_program(program):
	_compiledYarnProgram = program
	if program && program.has_method("_load_program"):

		_compiledYarnProgram.showTokens = _showTokens
		_compiledYarnProgram.printSyntax = _printSyntaxTree
		_compiledYarnProgram.path = filepath
		_compiledYarnProgram.locale = locale
		_compiledYarnProgram.connect("debug_changed",_compiledYarnProgram,"_debug_changed",_showTokens,_printSyntaxTree)
		_compiledYarnProgram.connect("path_changed",_compiledYarnProgram,"_set_path",filepath)
		_compiledYarnProgram.connect("locale_changed",_compiledYarnProgram,"_set_locale",locale)
	elif program && !program.has_method("_load_program"):
		# if its the wrong type of resource then we
		# dont load anything
		_compiledYarnProgram = null

func _process(delta):
	if !Engine.editor_hint:
		var state = _dialogue.get_exec_state()
		if (_dialogueStarted && 
			state!=YarnGlobals.ExecutionState.WaitingForOption &&
			state!=YarnGlobals.ExecutionState.Suspended):
			_dialogue.resume()


func add_command_handler(command:String,handler:FuncRef):
	if(commandHandlers.has(command)):
		printerr("replacing existing command handler for %s"%command)
	commandHandlers[command] = handler


func _handle_line(line):
	print(_stringTable)
	var text : String =  (_stringTable.get(line.id) as LineInfo).text
	print(text)
	_pass_line(text)

	return YarnGlobals.HandlerState.PauseExecution

func consume_line():
	_pass_line(next_line)
	next_line = ""

func _pass_line(lineText:String):
	if display != null:
		if !display.feed_line(lineText):
			next_line = lineText

func _handle_command(command):
	print("command: %s"%command.command)
	return YarnGlobals.HandlerState.ContinueExecution

func _handle_options(optionSet):
	print("options: %s"%optionSet.options.size())
	for option in optionSet.options:
		print("id[%s](%s) - destination[%s]"%[option.id,_stringTable[option.line.id].text,option.destination])
	#_dialogue.set_selected_option(0)
	if display != null:
		var lineOptions : Array = []
		for optionIndex in range(optionSet.options.size()):
			lineOptions.append(_stringTable[optionSet.options[optionIndex].line.id].text)
		display.feed_options(lineOptions)

func _handle_dialogue_complete():
	print("finished")
	if display != null:
		display.dialogue_finished()
	_dialogueStarted = false

func _handle_node_start(node:String):
	if !_dialogue._visitedNodeCount.has(node):
		_dialogue._visitedNodeCount[node] = 1
	else:
		_dialogue._visitedNodeCount[node]+=1

func _handle_node_complete(node:String):
	
	return YarnGlobals.HandlerState.ContinueExecution
	

func start(node : String = _startNode):
	if(_dialogueStarted):
		return 
	_dialogueStarted = true
	_dialogue.set_node(node)

