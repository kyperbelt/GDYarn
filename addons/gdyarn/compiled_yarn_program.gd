tool
extends Resource

class_name CompiledYarnProgram

const ProgramUtils = preload("res://addons/gdyarn/core/program/program_utils.gd")
const YarnProgram = ProgramUtils.YarnProgram
const EXTENSION := "cyarn"

export(String) var _programName = "compiled_yarn_program" setget set_program_name
export(String, DIR) var _directory = "res://" setget set_dir
export(Array, String, FILE, "*.yarn") var _yarnPrograms = []

func _init():
	pass

func _load_program(source:String,fileName:String,showTokens: bool , printSyntax : bool)->YarnProgram:
	var p : YarnProgram = YarnProgram.new()
	var YarnCompiler = load("res://addons/gdyarn/core/compiler/compiler.gd")
	YarnCompiler.compile_string(source,fileName,p,showTokens,printSyntax)
	return p

func set_dir(value):
	if value.begins_with("res://"):
		var dirCheck = Directory.new()
		if dirCheck.dir_exists(value):
			_directory = value
		else:
			printerr("Directory does not exist : %s" % value)

		

func set_program_name(value):
	_programName = value

# compile all the program files into a singular program
func _compile_programs(showTokens : bool, printSyntax : bool):
	var programs := []

	# go through each file and create a program from it
	for file in _yarnPrograms:
		# ignore empty files
		if file.empty():
			continue

		var f := File.new()
		f.open(file,File.READ)
		var source := f.get_as_text()
		var p = _load_program(source,file,showTokens,printSyntax)
		programs.append(p)
		f.close()

		# combine all the programs into a single one
		return  ProgramUtils.combine_programs([]+programs)

# func set_files(arr):
# 	if !Engine.editor_hint:
# 		return
# 	if arr.size() > _yarnPrograms.size():
# 		# added new program file
# 		if !arr.back().empty() && !_yarnPrograms.has(arr.back()):
# 			var f = File.new()
# 			f.open(arr.back(),File.READ)
# 			var source : String = f.get_as_text()
# 			f.close()
# 			var p = _load_program(source,arr.back())
# 			program = p if !program else ProgramUtils.combine_programs([program,p])
# 		_yarnPrograms = arr

# 	elif arr.size() < _yarnPrograms.size():
# 		# removed program
# 		_reload_all_programs(arr)
# 		_yarnPrograms = arr
# 	else:
# 		# we did not remove any program but we updated
# 		# one of the current entries
# 		var index = _get_diff(arr)
# 		if index != -1 && !_yarnPrograms.has(arr[index]):
# 			_reload_all_programs(arr)
# 			_yarnPrograms = arr

#get the change so we can load/unload
# func _get_diff(newOne:Array,offset:int = 0)->int:
# 	for i in range(offset,_yarnPrograms.size()):
# 		if _yarnPrograms[i] != newOne[i]:
# 			return i
# 	return -1


func _load_compiled_program():
	var filepath = "%s%s.%s" %[_directory,_programName,EXTENSION]
	if File.new().file_exists(filepath):
		var program = ProgramUtils._import_program(filepath)
		program.programName = _programName
		return  program
	else:
		printerr("unable to load program : could not find File[%s] " % filepath)
		return null

func _save_compiled_program(program):
	var filepath = "%s%s.%s" %[_directory,_programName,EXTENSION]
	ProgramUtils.export_program(YarnProgram.new() if program==null else program,filepath)


# func set_file(arr):
# 	if arr.size() != _yarnPrograms.size():
# 		if arr.size() > _yarnPrograms.size():
# 			#case where we added a new script
# 			#assume it was added at the end
# 			if (!arr.back().empty()):
# 				var f = File.new()
# 				f.open(arr.back(),File.READ)
# 				var source : String = f.get_as_text()
# 				f.close()
# 				# programs.append(_load_program(source,arr.back()))

# 		else:
# 			#case where we removed a yarn script
# 			#we have to figure out which one is the
# 			#one we removed and also get rid of the program
# 			var index:int = -1
# 			for i in range(_yarnPrograms.size()):
# 				if !(_yarnPrograms[i] in arr):
# 					index = i
# 					break
# 			if index != -1:
# 				programs.remove(index)
# 	else:
# 		var index:int = _get_diff(arr)
# 		#script was changed
# 		print("difference %s"%index)
# 		if index != -1:

# 			if (!arr[index].empty()):
# 				var f = File.new()
# 				f.open(arr[index],File.READ)
# 				var source : String = f.get_as_text()
# 				f.close()

# 				if programs.size() == arr.size():
# 					# programs[index] = _load_program(source,arr.back())
# 					emit_signal("program_added",arr.back(),index,source)
# 				else:
# 					# programs.insert(index,_load_program(source,arr.back()))
# 					emit_signal("program_added",arr.back(),index,source)
#       _yarnPrograms=arr
