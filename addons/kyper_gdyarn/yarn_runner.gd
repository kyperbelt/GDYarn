tool
extends Node

const YarnGlobals = preload("res://addons/kyper_gdyarn/autoloads/execution_states.gd")

const YarnProgram = preload("res://addons/kyper_gdyarn/core/program/program.gd")
const YarnCompiler = preload("res://addons/kyper_gdyarn/core/compiler/compiler.gd")
const LineInfo = preload("res://addons/kyper_gdyarn/core/program/yarn_line.gd")
const Line = preload("res://addons/kyper_gdyarn/core/dialogue/line.gd")
const YarnDialogue = preload("res://addons/kyper_gdyarn/core/dialogue.gd")
const DisplayInterface = preload("res://addons/kyper_gdyarn/yarn_gui.gd")


# String is a path to a PNG file in the global filesystem.
export(Array,String, FILE, GLOBAL, "*.yarn") var _yarnFiles setget set_file

export(String) var _startNode = "Start"

export(bool) var _autoStart = false

export(NodePath) var _variableStorage

export(NodePath) var _displayInterface

export(bool) var _showTokens = false
export(bool) var _printSyntaxTree = false


#programs
var programs : Array = []#YarnProgram

var _stringTable : Dictionary = {}#localization support to come


#dialogue
var _dialogue : YarnDialogue
var _dialogueStarted : bool = false

#display interface
var display : DisplayInterface

#dialogue flow control
var next_line : String = ""#extra line will be empty when there is no next line
var commandHandlers :  Dictionary = {} #funcRef map for text commands


func _ready():
	if Engine.editor_hint:
		#connect("script_changed",self,"set_file")

		pass 
	else:
		#inside the editor
		_dialogue = YarnDialogue.new(get_node(_variableStorage))
		_dialogue.get_vm().lineHandler = funcref(self,"_handle_line")
		_dialogue.get_vm().optionsHandler = funcref(self,"_handle_options")
		_dialogue.get_vm().commandHandler = funcref(self,"_handle_command")
		_dialogue.get_vm().nodeCompleteHandler = funcref(self,"_handle_node_complete")
		_dialogue.get_vm().dialogueCompleteHandler = funcref(self,"_handle_dialogue_complete")
		_dialogue.get_vm().nodeStartHandler = funcref(self,"_handle_node_start")

		var program : YarnProgram = YarnGlobals.combine_programs(programs)

		_dialogue.set_program(program)

		display = get_node(_displayInterface)

		display._dialogue = _dialogue
		display._dialogueRunner = self

		if(_autoStart):
			start()
		pass


func _process(delta):
	if !Engine.editor_hint:
		var state = _dialogue.get_exec_state()
		if (_dialogueStarted && 
			state!=YarnGlobals.ExecutionState.WaitingForOption &&
			state!=YarnGlobals.ExecutionState.Suspended):
			_dialogue.resume()


func set_file(arr):
	if arr.size() != _yarnFiles.size():
		if arr.size() > _yarnFiles.size(): 
			#case where we added a new script
			#assume it was added at the end
			if (!arr.back().empty()):
				var f = File.new()
				f.open(arr.back(),File.READ)
				var source : String = f.get_as_text()
				f.close()
				programs.append(_load_program(source,arr.back()))

		else:
			#case where we removed a yarn script
			#we have to figure out which one is the
			#one we removed and also get rid of the program
			var index:int = -1
			for i in range(_yarnFiles.size()):
				if !(_yarnFiles[i] in arr):
					index = i
					break
			if index != -1:
				programs[index].free()
				programs.remove(index)
	else:
		var index:int = _get_diff(arr)
		#script was changed
		print("difference %s"%index)
		if index != -1:
			
			if (!arr[index].empty()):
				var f = File.new()
				f.open(arr[index],File.READ)
				var source : String = f.get_as_text()
				f.close()
				if programs.size() == arr.size():
					programs[index].free()
					programs[index] = _load_program(source,arr.back())
				else:
					programs.insert(index,_load_program(source,arr.back()))
				
	_yarnFiles=arr


func add_command_handler(command:String,handler:FuncRef):
	if(commandHandlers.has(command)):
		printerr("replacing existing command handler for %s"%command)
	commandHandlers[command] = handler;

#get the change so we can load/unload
func _get_diff(newOne:Array,offset:int = 0)->int:
	for i in range(offset,_yarnFiles.size()):
		if _yarnFiles[i] != newOne[i]:
			return i
	return -1


func _load_program(source:String,fileName:String)->YarnProgram:
	var p : YarnProgram = YarnProgram.new()
	YarnCompiler.compile_string(source,fileName,p,_stringTable,_showTokens,_printSyntaxTree)
	return p

func _handle_line(line):
	var text : String =  _stringTable.get(line.id).text;
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

