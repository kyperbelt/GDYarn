extends Object

signal resumed
# var YarnGlobals = load("res://addons/gdyarn/autoloads/execution_states.gd")

var FunctionInfo = load("res://addons/gdyarn/core/function_info.gd")
var Value = load("res://addons/gdyarn/core/value.gd")
var YarnProgram = load("res://addons/gdyarn/core/program/program.gd")
var YarnNode = load("res://addons/gdyarn/core/program/yarn_node.gd")
var Instruction = load("res://addons/gdyarn/core/program/instruction.gd")
var Line = load("res://addons/gdyarn/core/dialogue/line.gd")
var Command = load("res://addons/gdyarn/core/dialogue/command.gd")
var Option = load("res://addons/gdyarn/core/dialogue/option.gd")
var OptionSet = load("res://addons/gdyarn/core/dialogue/option_set.gd")

const EXECUTION_COMPLETE : String = "execution_complete_command"

var NULL_VALUE = Value.new(null)


var lineHandler: FuncRef
var optionsHandler:FuncRef
var commandHandler:FuncRef
var nodeStartHandler:FuncRef
var nodeCompleteHandler:FuncRef
var dialogueCompleteHandler:FuncRef

var _dialogue 
var _program 
var _state 

var waiting : bool = false

var _currentNode 

var executionState = YarnGlobals.ExecutionState.Stopped

func _init(dialogue):
	self._dialogue = dialogue
	_state = VmState.new()


func set_program(program):
	_program = program

#set the node to run
#return true if successeful false if no node
#of that name found
func set_node(name:String)->bool:
	if _program == null || _program.yarnNodes.size() == 0:
		printerr("Could not load %s : no nodes loaded" % name)
		return false
	
	if !_program.yarnNodes.has(name):
		executionState = YarnGlobals.ExecutionState.Stopped
		reset()
		printerr("No node named %s has been loaded" % name)
		return false

	_dialogue.dlog("Running node %s"+name)

	_currentNode = _program.yarnNodes[name]
	reset()
	_state.currentNodeName = name
	nodeStartHandler.call_func(name)
	return true


func current_node_name()->String:
	return _currentNode.nodeName

func current_node():
	return _currentNode

#stop exectuion
func stop():
	executionState = YarnGlobals.ExecutionState.Stopped
	reset()
	_currentNode = null

#set the currently selected option and 
#resume execution if waiting for result
#return false if error
func set_selected_option(id:int)->bool:

	if executionState != YarnGlobals.ExecutionState.WaitingForOption:
		printerr("Unable to select option when dialogue not waitinf for option")
		return false

	if id < 0 || id >= _state.currentOptions.size():
		printerr("%d is not a valid option "%id)
		return false

	var destination : String = _state.currentOptions[id].value
	_state.push_value(destination)
	_state.currentOptions.clear()

	#no longer waiting for option 
	executionState = YarnGlobals.ExecutionState.Suspended
	
	return true


# check if there is currently any options that require resolution
func has_options()->bool:
	return _state.currentOptions.size()>0

func reset():
	_state = VmState.new()

#continue execution
func resume()->bool:

	if _currentNode == null :
		printerr("Cannot run dialogue with no node selected")
		return false
	if executionState == YarnGlobals.ExecutionState.WaitingForOption:
		printerr("Cannot run while waiting for option")
		return false
	
	if lineHandler == null :
		printerr("Cannot run without a lineHandler")
		return false
	
	if optionsHandler == null :
		printerr("Cannot run withour an optionsHandler")	
		return false

	if commandHandler == null :
		printerr("Cannot run withour an commandHandler")	
		return false
	if nodeStartHandler == null :
		printerr("Cannot run withour a nodeStartHandler")	
		return false
	if nodeCompleteHandler == null :
		printerr("Cannot run withour an nodeCompleteHandler")	
		return false


	emit_signal("resumed")
	if waiting:
		return false

	executionState = YarnGlobals.ExecutionState.Running
	
	#execute instruction until something cool happens
	while executionState == YarnGlobals.ExecutionState.Running:
		#print(_currentNode.nodeName)
		var currentInstruction = _currentNode.instructions[_state.programCounter]

		run_instruction(currentInstruction)
		_state.programCounter+=1

		if _state.programCounter >= _currentNode.instructions.size():
			nodeCompleteHandler.call_func(_currentNode.nodeName)
			executionState = YarnGlobals.ExecutionState.Stopped
			reset()
			dialogueCompleteHandler.call_func()
			_dialogue.dlog("Run Complete")

	return true

func find_label_instruction(label:String)->int:
	if !_currentNode.labels.has(label):
		printerr("Unknown label:"+label)
		return -1
	return _currentNode.labels[label]

func run_instruction(instruction)->bool:

	match instruction.operation:
		YarnGlobals.ByteCode.Label:
			#do nothing woooo!
			pass
		YarnGlobals.ByteCode.JumpTo:
			#jump to named label
			_state .programCounter = find_label_instruction(instruction.operands[0].value)-1
		YarnGlobals.ByteCode.RunLine:
			#look up string from string table
			#pass it to client as line
			var key : String = instruction.operands[0].value

			var line = Line.new(key)

			#the second operand is the expression count 
			# of format function
			if instruction.operands.size() > 1:
				var expressionCount = int(instruction.operands[1].value)

				while expressionCount >0:
					line.substitutions.append(_state.pop_value().as_string())
					expressionCount-=1

				pass#add format function support

			var pause : int = lineHandler.call_func(line)
			

			if pause == YarnGlobals.HandlerState.PauseExecution:
				executionState = YarnGlobals.ExecutionState.Suspended
			

		YarnGlobals.ByteCode.RunCommand:
				var commandText : String = instruction.operands[0].value

				# TODO: allow for inline expressions and format functions in commands
				if instruction.operands.size() > 1:
					pass#add format function 


				var command = Command.new(commandText)

				## here we handle built in commands like wait
				if command.command == "wait":
					if command.args.size() >= 1:
						var time : float = float(command.args[0])
						if time > 0:
							waiting = true
							var pause = commandHandler.call_func(command)
							if pause is GDScriptFunctionState || pause == YarnGlobals.HandlerState.PauseExecution:
								executionState = YarnGlobals.ExecutionState.Suspended
							yield(self, "resumed")
							waiting = false
				else:
					var pause = commandHandler.call_func(command)
					if pause is GDScriptFunctionState || pause == YarnGlobals.HandlerState.PauseExecution:
						executionState = YarnGlobals.ExecutionState.Suspended

				
		YarnGlobals.ByteCode.PushString:
			#push String var to stack
			_state.push_value(instruction.operands[0].value)
		YarnGlobals.ByteCode.PushNumber:
			#push number to stack

			_state.push_value(instruction.operands[0].value)
		YarnGlobals.ByteCode.PushBool:
			#push boolean to stack
			_state.push_value(instruction.operands[0].value)

		YarnGlobals.ByteCode.PushNull:
			#push null t
			_state.push_value(NULL_VALUE)

		YarnGlobals.ByteCode.JumpIfFalse:
			#jump to named label if value of stack top is false
			if !_state.peek_value().as_bool():
				_state.programCounter = find_label_instruction(instruction.operands[0].value)-1
				
		YarnGlobals.ByteCode.Jump:
			#jump to label whose name is on the stack
			var dest : String = _state.peek_value().as_string()
			_state.programCounter = find_label_instruction(dest)-1
		YarnGlobals.ByteCode.Pop:
			#pop value from stack
			_state.pop_value()
		YarnGlobals.ByteCode.CallFunc:
			#call function with params on stack
			#push any return value to stack
			var functionName : String = instruction.operands[0].value

			var function = _dialogue.library.get_function(functionName)

			var expectedParamCount : int = function.paramCount
			var actualParamCount : int = _state.pop_value().as_number()

			#if function takes in -1 params disregard
			#expect the compiler to have placed the number of params
			#at the top of the stack
			if expectedParamCount == -1:
				expectedParamCount = actualParamCount

			if expectedParamCount != actualParamCount:
				printerr("Function %s expected %d parameters but got %d instead" %[functionName,
				expectedParamCount,actualParamCount])
				return false

			var result

			if actualParamCount == 0:
				result = function.invoke()
			else:
				var params : Array = []#value
				for i in range(actualParamCount):
					params.push_front(_state.pop_value())

				result = function.invoke(params)
				# print("function[%s] result[%s]" %[functionName, result._to_string()])

			if function.returnsValue:
				_state.push_value(result)

			pass
		YarnGlobals.ByteCode.PushVariable:
			#get content of variable and push to stack
			var name : String = instruction.operands[0].value
			var loaded = _dialogue._variableStorage._get_value_(name)
			_state.push_value(loaded)
		YarnGlobals.ByteCode.StoreVariable:
			#store top stack value to variable
			var top = _state.peek_value()
			var destination : String = instruction.operands[0].value
			_dialogue._variableStorage._set_value_(destination,top)
				
		YarnGlobals.ByteCode.Stop:
			#stop execution and repost it
			nodeCompleteHandler.call_func(_currentNode.nodeName)
			dialogueCompleteHandler.call_func()
			executionState = YarnGlobals.ExecutionState.Stopped
			reset()

		YarnGlobals.ByteCode.RunNode:
			#run a node 
			var name : String 

			if (instruction.operands.size() == 0 || instruction.operands[0].value.empty()):
				#get string from stack and jump to node with that name
				name = _state.peek_value().value()
			else : 
				name = instruction.operands[0].value

			var pause = nodeCompleteHandler.call_func(_currentNode.nodeName)
			set_node(name)
			_state.programCounter-=1
			if pause == YarnGlobals.HandlerState.PauseExecution:
				executionState = YarnGlobals.ExecutionState.Suspended

		YarnGlobals.ByteCode.AddOption:
			# add an option to current state
			var line  = Line.new(instruction.operands[0].value)

			if instruction.operands.size() > 2:
				var expressionCount = int(instruction.operands[2].value)

				while expressionCount >0:
					line.substitutions.append(_state.pop_value().as_string())
					expressionCount-=1


			# line to show and node name
			_state.currentOptions.append(SimpleEntry.new(line,instruction.operands[1].value))
		YarnGlobals.ByteCode.ShowOptions:
			#show options - stop if none
			if _state.currentOptions.size() == 0:
				executionState = YarnGlobals.ExecutionState.Stopped
				reset()
				dialogueCompleteHandler.call_func()
				return false

			#present list of options
			var choices : Array = []#Option
			for optionIndex in range(_state.currentOptions.size()):
				var option : SimpleEntry = _state.currentOptions[optionIndex]
				choices.append(Option.new(option.key,optionIndex,option.value))

			#we cant continue until option chosen
			executionState = YarnGlobals.ExecutionState.WaitingForOption

			#pass the options to the client
			#delegate for them to call 
			#when user makes selection

			optionsHandler.call_func(OptionSet.new(choices))
			pass
		_:
			#bytecode messed up woopsise
			executionState = YarnGlobals.ExecutionState.Stopped
			reset()
			printerr("Unknown Bytecode %s "%instruction.operation)
			return false

	return true


class VmState:
	var Value = load("res://addons/gdyarn/core/value.gd")

	var currentNodeName : String 
	var programCounter : int = 0
	var currentOptions : Array = []#SimpleEntry
	var stack : Array = [] #Value

	func push_value(value)->void:
		if value is Value:
			stack.push_back(value)
		else:
			stack.push_back(Value.new(value))


	func pop_value():
		return stack.pop_back()

	func peek_value():
		return stack.back()

	func clear_stack():
		stack.clear()

class SimpleEntry:
	var key 
	var value : String

	func _init(key,value:String):
		self.key = key
		self.value = value 
