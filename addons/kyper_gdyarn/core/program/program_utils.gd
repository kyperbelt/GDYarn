extends Object

const PROGRAM_NAME    := "program_name"
const PROGRAM_STRINGS := "program_strings"
const PROGRAM_NODES   := "program_nodes"

const NODE_NAME 	    := "node_name"
const NODE_INSTRUCTIONS := "node_instructions"
const NODE_LABELS 		:= "node_labels"
const NODE_TAGS 		:= "node_tags"
const NODE_SOURCEID  	:= "node_source_id"

const INSTRUCTION_OP       := "instruction_op"
const INSTRUCTION_OPERANDS := "instruction_operands"

const OPERAND_TYPE   := "operand_type"
const OPERAND_VALUE  := "operand_value"

func _init():
	pass


func export_program(program):
	pass


func _serialize_program(program)->Dictionary:
	var result :={}
	result[PROGRAM_NAME] = program.programName
	result[PROGRAM_STRINGS] = program.yarnStrings
	result[PROGRAM_NODES] = _serialize_all_nodes(program.yarnNodes)

	return result

func _serialize_all_nodes(nodes)->Dictionary:
	var result := {}


	return result

func _serialize_node(node)->Dictionary:
	var result := {}

	# nodeName : String
	# instructions : Array = []
	# labels : Dictionary
	# tags: Array
	# sourceId : String

	result[NODE_NAME] = node.nodeName
	result[NODE_INSTRUCTIONS] = _serialize_all_instructions(node.instructions)
	result[NODE_LABELS] = node.labels
	result[NODE_TAGS] = node.tags
	result[NODE_SOURCEID] = node.sourceId


	return result

func _serialize_all_instructions(instructions)->Array:
	var result = []
	for instruction in instructions:
		result.append(_serialize_instruction(instruction))
	return result

func _serialize_instruction(instruction)->Dictionary:
	var result:= {}

# var operation : int #bytcode
# var operands : Array #Operands
	result[INSTRUCTION_OP] = instruction.operation
	result[INSTRUCTION_OPERANDS] = _serialize_all_operands(instruction.operands)

	return result

func _serialize_all_operands(operands)->Array:
	var result := []

	return result

func _serialize_operand(operand)->Dictionary:
	var result:= {}

	return result
