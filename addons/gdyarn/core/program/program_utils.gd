class_name ProgramUtils

# TODO: make code naming conventions more consistent
const PROGRAM_NAME := "program_name"
const PROGRAM_LINE_INFO := "program_line_info"
const PROGRAM_NODES := "program_nodes"

const NODE_NAME := "node_name"
const NODE_INSTRUCTIONS := "node_instructions"
const NODE_LABELS := "node_labels"
const NODE_TAGS := "node_tags"
const NODE_SOURCEID := "node_source_id"

const INSTRUCTION_OP := "instruction_op"
const INSTRUCTION_OPERANDS := "instruction_operands"

const OPERAND_TYPE := "operand_type"
const OPERAND_VALUE := "operand_value"

const STRINGS_DELIMITER := "\t"

# const YarnGlobals = preload("res://addons/gdyarn/autoloads/execution_states.gd")
const Operand = preload("res://addons/gdyarn/core/program/operand.gd")
const YarnProgram = preload("res://addons/gdyarn/core/program/program.gd")
const Instruction = preload("res://addons/gdyarn/core/program/instruction.gd")
const YarnNode = preload("res://addons/gdyarn/core/program/yarn_node.gd")
const LineInfo = preload("res://addons/gdyarn/core/program/yarn_line.gd")

const STRINGS_EXTENSION := "tsv"
const DEFAULT_STRINGS_FORMAT = "%s-strings.%s"
const LOCALISED_STRINGS_FORMAT = "%s-%s-strings.%s"


func _init():
	pass


# export the program and save it to disk to the specified filepath
# in dictionary format
static func export_program(program, filePath):

	var stringsPath = DEFAULT_STRINGS_FORMAT % [filePath.get_basename(), STRINGS_EXTENSION]
	var lineInfos = program.yarn_strings
	var result: PackedStringArray = _serialize_lines(lineInfos)
	var strings: String = "\n".join(result)  #

	var file := FileAccess.open(stringsPath, FileAccess.WRITE)

	file.store_line(strings)

	file.close()

	var otherfile := FileAccess.open(filePath, FileAccess.WRITE)
	var prog = YarnProgram.new() if program == null else program
	var serialized_program := _serialize_program(prog)
	otherfile.store_line(var_to_str(serialized_program))
	otherfile.close()

	pass


#combine all the programs in the provided array
static func combine_programs(programs: Array = []):
	if programs.is_empty():
		printerr("no programs to combine - you failure")
		return null

	var YarnProgram = load("res://addons/gdyarn/core/program/program.gd")
	var p = YarnProgram.new()
	for program in programs:
		for nodeKey in program.yarn_nodes.keys():
			if p.has_yarn_node(nodeKey):
				printerr("Program with duplicate node names %s " % nodeKey)
				return null
			p.yarn_nodes[nodeKey] = program.yarnNodes[nodeKey]

			YarnGlobals.merge_dir(p.yarn_strings, program.yarnStrings)

	return p


static func _serialize_program(program) -> Dictionary:
	var result := {}
	result[PROGRAM_NAME] = program.program_name
	# result[PROGRAM_LINE_INFO] = program._lineInfos
	result[PROGRAM_NODES] = _serialize_all_nodes(program.yarn_nodes)

	return result


static func _serialize_all_nodes(nodes) -> Array:
	var result := []

	for node in nodes.values():
		var nodeData := {}
		# nodeName : String
		# instructions : Array = []
		# labels : Dictionary
		# tags: Array
		# sourceId : String

		nodeData[NODE_NAME] = node.node_name
		nodeData[NODE_INSTRUCTIONS] = _serialize_all_instructions(node.instructions)
		nodeData[NODE_LABELS] = node.labels
		nodeData[NODE_TAGS] = node.tags
		nodeData[NODE_SOURCEID] = node.source_id

		result.append(nodeData)

	return result


# return an array
static func _serialize_lines(lines) -> PackedStringArray:
	var lineTexts: PackedStringArray = []
	var headers := PackedStringArray(["id", "text", "file", "node", "lineNumber", "implicit", "tags"])
	lineTexts.append(STRINGS_DELIMITER.join(headers))
	for lineKey in lines.keys():
		var line = lines[lineKey]
		var lineInfo: PackedStringArray = []
		lineInfo.append(lineKey)
		lineInfo.append(line.text)
		lineInfo.append(line.file_name)
		lineInfo.append(line.node_name)
		lineInfo.append(line.line_number)
		lineInfo.append(line.implicit)
		lineInfo.append(" ".join(line.meta))

		lineTexts.append(STRINGS_DELIMITER.join(lineInfo))

	return lineTexts


static func _load_lines(line_data: PackedStringArray) -> Dictionary:
	var result := {}
	for line in line_data:
		if line.is_empty():
			continue
		var proccessed_line := line.split(STRINGS_DELIMITER)
		var lineKey := proccessed_line[0]

		var text := proccessed_line[1].strip_escapes()
		var file_name := proccessed_line[2]
		var node_name := proccessed_line[3]
		var line_number := int(proccessed_line[4])
		var implicit := proccessed_line[5].nocasecmp_to("true")
		var meta := proccessed_line[6].split(" ")

		var info = LineInfo.new(text, node_name, line_number, file_name, implicit, meta)
		result[lineKey] = info

	return result


static func _serialize_all_instructions(instructions) -> Array:
	var result = []
	for instruction in instructions:
		var instruction_data := {}

		# var operation : int #bytcode
		# var operands : Array #Operands
		instruction_data[INSTRUCTION_OP] = instruction.operation
		instruction_data[INSTRUCTION_OPERANDS] = _serialize_all_operands(instruction.operands)
		result.append(instruction_data)
	return result


static func _serialize_all_operands(operands) -> Array:
	var result := []

	for operand in operands:
		var operand_data := {}

		operand_data[OPERAND_TYPE] = operand.type
		operand_data[OPERAND_VALUE] = operand.value

		result.append(operand_data)

	return result


# import the program at the otherfile destination
# return null if no file exitst
static func _import_program(filePath) -> YarnProgram:

	var strings_path = DEFAULT_STRINGS_FORMAT % [filePath.get_basename(), STRINGS_EXTENSION]
	var localized_strings_path = (
		"%s-strings-%s.ots"
		% [filePath.get_basename(), TranslationServer.get_locale()]
	)
	var strings: PackedStringArray

	var file : FileAccess
	if FileAccess.file_exists(localized_strings_path):
		file = FileAccess.open(localized_strings_path, FileAccess.READ)
	elif FileAccess.file_exists(strings_path):
		file = FileAccess.open(strings_path, FileAccess.READ)
	else:
		printerr(
			(
				"%s file found for this program[%s], make one or recompile the program."
				% [strings_path, filePath.get_basename()]
			)
		)

	strings = file.get_as_text().split("\n")
	file.close()

	strings.remove_at(0)
	var strings_table = _load_lines(strings)

	file = FileAccess.open(filePath, FileAccess.READ)
	var data: Dictionary = str_to_var(file.get_as_text())
	file.close()

	var program = _load_program(data)
	program.yarn_strings = strings_table
	# FIXME: We should use yarn projects instead of programs for this

	return program


static func _load_program(data: Dictionary) -> YarnProgram:
	var program = YarnProgram.new()

	program.program_name = data[PROGRAM_NAME]
	# program.yarn_strings = data[PROGRAM_LINE_INFO]
	program.yarn_nodes = _load_nodes(data[PROGRAM_NODES])

	return program


static func _load_nodes(nodes: Array) -> Dictionary:
	var result := {}
	for node in nodes:
		var yarn_node = _load_node(node)
		result[yarn_node.node_name] = yarn_node
	return result


static func _load_node(node):
	var yarn_node := YarnNode.new()

	yarn_node.node_name = node[NODE_NAME]
	yarn_node.labels = node[NODE_LABELS]
	yarn_node.tags = node[NODE_TAGS]
	yarn_node.source_id = node[NODE_SOURCEID]
	yarn_node.instructions = _load_instructions(node[NODE_INSTRUCTIONS])

	return yarn_node


static func _load_instructions(instructions: Array):
	var result := []

	for instruction in instructions:
		result.append(_load_instruction(instruction))

	return result


static func _load_instruction(instruction):
	var operation: int = instruction[INSTRUCTION_OP]
	var operands: Array = _load_operands(instruction[INSTRUCTION_OPERANDS])

	var loaded_instruction := Instruction.new()

	loaded_instruction.operation = operation
	loaded_instruction.operands = operands

	return loaded_instruction


static func _load_operands(operands: Array):
	var result = []
	for operand in operands:
		result.append(_load_operand(operand))

	return result


static func _load_operand(operand):
	var value = operand[OPERAND_VALUE]

	var type: int = operand[OPERAND_TYPE]
	match type:
		Operand.ValueType.StringValue, Operand.ValueType.None:
			pass
		Operand.ValueType.FloatValue:
			value = float(value)
		Operand.ValueType.BooleanValue:
			value = bool(value)

	var op = Operand.new(value)

	return op
