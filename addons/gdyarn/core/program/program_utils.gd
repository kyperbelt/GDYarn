extends Object

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
	var file := File.new()

	var stringsPath = DEFAULT_STRINGS_FORMAT % [filePath.get_basename(), STRINGS_EXTENSION]
	var lineInfos = program.yarnStrings
	var result: PoolStringArray = _serialize_lines(lineInfos)
	var strings: String = result.join("\n")  #

	file.open(stringsPath, File.WRITE)

	file.store_line(strings)

	file.close()

	var otherfile = File.new()

	otherfile.open(filePath, File.WRITE)
	var prog = YarnProgram.new() if program == null else program
	var serialized_program = _serialize_program(prog)
	otherfile.store_line(var2str(serialized_program))
	otherfile.close()

	pass


#combine all the programs in the provided array
static func combine_programs(programs: Array = []):
	if programs.empty():
		printerr("no programs to combine - you failure")
		return null

	var YarnProgram = load("res://addons/gdyarn/core/program/program.gd")
	var p = YarnProgram.new()
	for program in programs:
		for nodeKey in program.yarnNodes.keys():
			if p.has_yarn_node(nodeKey):
				printerr("Program with duplicate node names %s " % nodeKey)
				return null
			p.yarnNodes[nodeKey] = program.yarnNodes[nodeKey]

			YarnGlobals.get_script().merge_dir(p.yarnStrings, program.yarnStrings)

	return p


static func _serialize_program(program) -> Dictionary:
	var result := {}
	result[PROGRAM_NAME] = program.programName
	# result[PROGRAM_LINE_INFO] = program._lineInfos
	result[PROGRAM_NODES] = _serialize_all_nodes(program.yarnNodes)

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

		nodeData[NODE_NAME] = node.nodeName
		nodeData[NODE_INSTRUCTIONS] = _serialize_all_instructions(node.instructions)
		nodeData[NODE_LABELS] = node.labels
		nodeData[NODE_TAGS] = node.tags
		nodeData[NODE_SOURCEID] = node.sourceId

		result.append(nodeData)

	return result


# return an array
static func _serialize_lines(lines) -> PoolStringArray:
	var lineTexts: PoolStringArray = []
	var headers := PoolStringArray(["id", "text", "file", "node", "lineNumber", "implicit", "tags"])
	lineTexts.append(headers.join(STRINGS_DELIMITER))
	for lineKey in lines.keys():
		var line = lines[lineKey]
		var lineInfo: PoolStringArray = []
		lineInfo.append(lineKey)
		lineInfo.append(line.text)
		lineInfo.append(line.fileName)
		lineInfo.append(line.nodeName)
		lineInfo.append(line.lineNumber)
		lineInfo.append(line.implicit)
		lineInfo.append(line.meta.join(" "))

		lineTexts.append(lineInfo.join(STRINGS_DELIMITER))

	return lineTexts


static func _load_lines(lineData: PoolStringArray) -> Dictionary:
	var result := {}
	for line in lineData:
		if line.empty():
			continue
		var proccessedLine = line.split(STRINGS_DELIMITER)
		var lineKey = proccessedLine[0]

		var text = proccessedLine[1].strip_escapes()
		var fileName = proccessedLine[2]
		var nodeName = proccessedLine[3]
		var lineNumber = int(proccessedLine[4])
		var implicit = bool(proccessedLine[5])
		var meta = proccessedLine[6].split(" ")

		var info = LineInfo.new(text, nodeName, lineNumber, fileName, implicit, meta)
		result[lineKey] = info

	return result


static func _serialize_all_instructions(instructions) -> Array:
	var result = []
	for instruction in instructions:
		var instructionData := {}

		# var operation : int #bytcode
		# var operands : Array #Operands
		instructionData[INSTRUCTION_OP] = instruction.operation
		instructionData[INSTRUCTION_OPERANDS] = _serialize_all_operands(instruction.operands)
		result.append(instructionData)
	return result


static func _serialize_all_operands(operands) -> Array:
	var result := []

	for operand in operands:
		var operandData := {}

		operandData[OPERAND_TYPE] = operand.type
		operandData[OPERAND_VALUE] = operand.value

		result.append(operandData)

	return result


# import the program at the otherfile destination
# return null if no file exitst
static func _import_program(filePath) -> YarnProgram:
	var file := File.new()

	var stringsPath = DEFAULT_STRINGS_FORMAT % [filePath.get_basename(), STRINGS_EXTENSION]
	var localizedStringsPath = (
		"%s-strings-%s.ots"
		% [filePath.get_basename(), TranslationServer.get_locale()]
	)
	var strings: PoolStringArray

	if file.file_exists(localizedStringsPath):
		file.open(localizedStringsPath, File.READ)
	elif file.file_exists(stringsPath):
		file.open(stringsPath, File.READ)
	else:
		printerr(
			(
				"%s file found for this program[%s], make one or recompile the program."
				% [stringsPath, filePath.get_basename()]
			)
		)

	strings = file.get_as_text().split("\n")
	file.close()

	strings.remove(0)
	file = File.new()

	file.open(filePath, File.READ)
	var data: Dictionary = str2var(file.get_as_text())
	var stringsTable = _load_lines(strings)
	file.close()

	var program = _load_program(data)
	program.yarnStrings = stringsTable

	return program


static func _load_program(data: Dictionary) -> YarnProgram:
	var program = YarnProgram.new()

	program.programName = data[PROGRAM_NAME]
	# program.yarnStrings = data[PROGRAM_LINE_INFO]
	program.yarnNodes = _load_nodes(data[PROGRAM_NODES])

	return program


static func _load_nodes(nodes: Array) -> Dictionary:
	var result := {}
	for node in nodes:
		var yarn_node = _load_node(node)
		result[yarn_node.nodeName] = yarn_node
	return result


static func _load_node(node):
	var yarn_node := YarnNode.new()

	yarn_node.nodeName = node[NODE_NAME]
	yarn_node.labels = node[NODE_LABELS]
	yarn_node.tags = node[NODE_TAGS]
	yarn_node.sourceId = node[NODE_SOURCEID]
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
