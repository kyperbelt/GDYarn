extends Node



#consts
const DEFAULT_START :String= "Start"

#future format function support
const FMF_PLACEHOLDER:String = "<VALUE PLACEHOLDER>"

#classes
const StandardLibrary = preload("res://addons/kyper_gdyarn/core/libraries/standard.gd")
const VirtualMachine = preload("res://addons/kyper_gdyarn/core/virtual_machine.gd")
const YarnLibrary = preload("res://addons/kyper_gdyarn/core/library.gd")
const YarnProgram = preload("res://addons/kyper_gdyarn/core/program/program.gd")

var _variableStorage 

var _debugLog : FuncRef
var _errLog : FuncRef

var _program : YarnProgram
var library : YarnLibrary

var _vm : VirtualMachine

var _visitedNodeCount : Dictionary = {}

var executionComplete : bool

func _init(variableStorage):
	_variableStorage = variableStorage
	_vm = VirtualMachine.new(self)
	library = YarnLibrary.new()
	_debugLog = funcref(self,"dlog")
	_errLog = funcref(self,"elog")
	executionComplete = false

	# import the standard library
	# this contains math constants, operations and checks
	library.import_library(StandardLibrary.new())#FIX
	
	#add a function to lib that checks if node is visited
	library.register_function("visited",-1,funcref(self,"is_node_visited"),true)
	
	#add function to lib that gets the node visit count
	library.register_function("visit_count",-1,funcref(self,"node_visit_count"),true)


func dlog(message:String):
	print("YARN_DEBUG : %s" % message)
	pass

func elog(message:String):
	print("YARN_ERROR : %s" % message)
	pass

func is_active()->bool:
	return get_exec_state() != YarnGlobals.ExecutionState.Stopped

#gets the current execution state of the virtual machine
func get_exec_state():
	return _vm.executionState

func set_selected_option(option:int):
	_vm.set_selected_option(option)

func set_node(name:String = DEFAULT_START):
	_vm.set_node(name)

func resume():
	if _vm.executionState == YarnGlobals.ExecutionState.Running:
		return 
	_vm.resume()

func stop():
	_vm.stop()
	pass

func get_all_nodes()->Array:
	return _program.yarnNodes.keys()

func current_node()->String:
	return _vm.get_current()

func get_node_id(name:String)->String:
	if _program.nodes.size() == 0:
		_errLog.call_func("No nodes loaded")
		return ""
	if _program.nodes.has(name):
		return "id:"+name
	else:
		_errLog.call_func("No node named [%s] exists" % name)
		return ""

func get_program_strings()->Dictionary:
	return _program.yarnStrings

func unloadAll(clear_visited:bool = true):
	if clear_visited :
		_visitedNodeCount.clear()
	_program = null

func dump()->String:
	return _program.dump(library)

func node_exists(name:String)->bool:
	return _program.nodes.has(name)

func set_program(program):
	_program = program
	_vm.set_program(_program)
	_vm.reset()

func get_program():
	return _program

func add_program(program):
	if _program == null:
		set_program(program)
	else:
		_program = YarnGlobals.combine_programs([_program,program])

func analyze(context):
	print("sike: not implemented")
	pass

func get_vm()->VirtualMachine:
	return _vm

func is_node_visited(node:String=_vm.current_node_name())->bool:
	return node_visit_count(node) > 0

func node_visit_count(node:String=_vm.current_node_name())->int:
	var visitCount : int = 0
	if _visitedNodeCount.has(node):
		visitCount = _visitedNodeCount[node]
	return visitCount

func get_visited_nodes():
	return _visitedNodeCount.keys()

func set_visited_nodes(visitedList):
	_visitedNodeCount.clear()
	for string in visitedList:
		_visitedNodeCount[string] = 1
