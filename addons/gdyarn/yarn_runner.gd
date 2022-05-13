tool
extends Node

## SIGNALS

# emitted when dialogue has started
signal dialogue_started

# text lines
signal line_emitted(line)

# commands that need to be processed
signal command_emitted(command, arguments)

# options need to be handled by
signal options_emitted(options)

# dialogue has completed execution
signal dialogue_finished

signal resumed

# the node has changed
signal node_started(nodeName)
signal node_complete(nodeName)

## ##########3

const LineInfo = preload("res://addons/gdyarn/core/program/yarn_line.gd")
const Line = preload("res://addons/gdyarn/core/dialogue/line.gd")

export(String) var _startNode = "Start"

export(bool) var _autoStart = false

export(NodePath) var _variableStorage

# String is a path to a PNG file in the global filesystem.
export(Resource) var _compiledYarnProgram setget set_program

# show debug statements
# export(bool) #TODO removed debug from export to declutter the inspector. Maybe add this somewhere else.
var debug = false

#dialogue flow control
var next_line: String = ""  #extra line will be empty when there is no next line

var waiting: bool = false

var _stringTable: Dictionary = {}  #localization support to come

#dialogue
var _dialogue
var _dialogueStarted: bool = false


func _ready():
	if Engine.editor_hint:
		pass
	else:
		var YarnDialogue = load("res://addons/gdyarn/core/dialogue.gd")
		_dialogue = YarnDialogue.new(get_node(_variableStorage))
		_dialogue.get_vm().lineHandler = funcref(self, "_handle_line")
		_dialogue.get_vm().optionsHandler = funcref(self, "_handle_options")
		_dialogue.get_vm().commandHandler = funcref(self, "_handle_command")
		_dialogue.get_vm().nodeCompleteHandler = funcref(self, "_handle_node_complete")
		_dialogue.get_vm().dialogueCompleteHandler = funcref(self, "_handle_dialogue_complete")
		_dialogue.get_vm().nodeStartHandler = funcref(self, "_handle_node_start")

		var program = _compiledYarnProgram._load_compiled_program()
		if program:
			_stringTable = program.yarnStrings

			_dialogue.set_program(program)

			if _autoStart:
				start(_startNode)


func _process(delta):
	if !Engine.editor_hint:
		pass
		# var state = _dialogue.get_exec_state()

		# if (_dialogueStarted &&
		# 	state!=YarnGlobals.ExecutionState.WaitingForOption &&
		# 	state!=YarnGlobals.ExecutionState.Suspended):
		# 	_dialogue.resume()
		# else:
		# 	print(state)


# make an option selection and pass it to the dialogue
# if it is waiting for an option
func choose(optionIndex: int):
	match _dialogue.get_exec_state():
		YarnGlobals.ExecutionState.WaitingForOption:
			_dialogue.set_selected_option(optionIndex)
		_:
			printerr("_dialogue was not currently waiting for option to be selected")


func resume():
	emit_signal("resumed")
	if _dialogueStarted && !waiting:
		_dialogue.resume()


func get_dialogue():
	return _dialogue


func set_program(program):
	_compiledYarnProgram = program
	if program && !program.has_method("_load_program"):
		# if its the wrong type of resource then we
		# dont load anything
		_compiledYarnProgram = null
		printerr("Program Resource must be of type CompiledYarnProgram!")


func start(node: String = _startNode):
	if _dialogueStarted:
		return
	emit_signal("dialogue_started")
	_dialogueStarted = true
	_dialogue.set_node(node)


func stop():
	if _dialogueStarted:
		_dialogueStarted = false
		_dialogue.stop()
		emit_signal("dialogue_finished")


func _compile_programs(showTokens: bool, printTree: bool):
	if !_compiledYarnProgram:
		printerr("Unable to compile programs. Missing CompiledYarnProgram resource in YarnRunner.")
		return
	var program = _compiledYarnProgram._compile_programs(showTokens, printTree)
	_compiledYarnProgram._save_compiled_program(program)
	pass


func _handle_line(line):
	var text: String = (_stringTable.get(line.id) as LineInfo).text
	text = text.format(line.substitutions)
	if debug:
		print("line: %s" % text)

	emit_signal(
		"line_emitted", YarnGlobals.expand_format_functions(text, TranslationServer.get_locale())
	)

	return YarnGlobals.HandlerState.PauseExecution


## TODO : add a way to add commands that suspend the run state.
func _handle_command(command):
	if debug:
		print("command<%s> args: %s" % [command.command, command.args])

	# If this command is the wait command, we have already vertified that it
	# has a valid argument in the virtual machine, so all thats left do to is
	# to begin waiting only after the user has attempted to resume. We also emit
	# command once it is resumed in order to notify any other interfaces
	# that make use of the wait command
	if command.command == "wait":
		var time: float = float(command.args[0])
		waiting = true
		yield(self, "resumed")
		emit_signal("command_emitted", command.command, command.args)
		yield(get_tree().create_timer(time), "timeout")
		waiting = false
		resume()
	else:
		emit_signal("command_emitted", command.command, command.args)

	return YarnGlobals.HandlerState.ContinueExecution


func _handle_options(optionSet):
	if debug:
		print("options: %s" % optionSet.options.size())
		for option in optionSet.options:
			print(
				(
					"id[%s](%s) - destination[%s]"
					% [option.id, _stringTable[option.line.id].text, option.destination]
				)
			)

	var lineOptions: Array = []
	for optionIndex in range(optionSet.options.size()):
		lineOptions.append(
			YarnGlobals.expand_format_functions(
				_stringTable[optionSet.options[optionIndex].line.id].text.format(
					optionSet.options[optionIndex].line.substitutions
				),
				TranslationServer.get_locale()
			)
		)
	emit_signal("options_emitted", lineOptions)
	#_dialogue.set_selected_option(0)
	# if display != null:
	# 	display.feed_options(lineOptions)


func _handle_dialogue_complete():
	if debug:
		print("finished")
	# if display != null:
	# 	display.dialogue_finished()
	emit_signal("dialogue_finished")
	_dialogueStarted = false


func _handle_node_start(node: String):
	if !_dialogue._visitedNodeCount.has(node):
		_dialogue._visitedNodeCount[node] = 1
	else:
		_dialogue._visitedNodeCount[node] += 1

	emit_signal("node_started", node)


func _handle_node_complete(node: String):
	emit_signal("node_complete", node)

	return YarnGlobals.HandlerState.ContinueExecution
