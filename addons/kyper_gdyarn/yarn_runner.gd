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


#programs
var programs : Array = []#YarnProgram

var _stringTable : Dictionary = {}#localization support to come


#dialogue
var _dialogue : YarnDialogue
var _dialogueStarted : bool = false

#display interface
var display : DisplayInterface

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

		if(_autoStart):
			start()
		pass


func _process(delta):
	if !Engine.editor_hint:

		if (_dialogueStarted && (
			_dialogue.get_exec_state()!=YarnGlobals.ExecutionState.WaitingForOption) &&
			 _dialogue.get_exec_state()!=YarnGlobals.ExecutionState.Suspended):
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


#get the change so we can load/unload
func _get_diff(newOne:Array,offset:int = 0)->int:
	for i in range(offset,_yarnFiles.size()):
		if _yarnFiles[i] != newOne[i]:
			return i
	return -1


func _load_program(source:String,fileName:String)->YarnProgram:
	var p : YarnProgram = YarnProgram.new()
	YarnCompiler.compile_string(source,fileName,p,_stringTable)
	return p

func _handle_line(line):
	var text : String =  _stringTable.get(line.id).text;
	print(text)
	return YarnGlobals.HandlerState.ContinueExecution 

func _handle_command(command):
	print("command: %s"%command.command)
	return YarnGlobals.HandlerState.ContinueExecution

func _handle_options(optionSet):
	# print("options: %s"%optionSet.options.size())
	# for option in optionSet.options:
	# 	print("id[%s] - destination[%s]"%[option.id,option.destination])
	# _dialogue.set_selected_option(0)
	if display != null:
		display.feed_options(optionSet.options)

func _handle_dialogue_complete():
	print("finished")
	_dialogueStarted = false

func _handle_node_start(node:String):
	print("nodeStarted: %s"%node)
	yield(get_tree().create_timer(1.0), "timeout")

func _handle_node_complete(node:String):
	print("nodeComplete: %s"%node)
	return YarnGlobals.HandlerState.ContinueExecution
	

func start(node : String = _startNode):
	if(_dialogueStarted):
		return 
	_dialogueStarted = true
	_dialogue.set_node(node)
	yield(get_tree().create_timer(1.0), "timeout")

