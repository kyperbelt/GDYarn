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


func _load_program(p : YarnProgram,source:String,fileName:String,showTokens: bool , printSyntax : bool)->int:
	var YarnCompiler = load("res://addons/gdyarn/core/compiler/compiler.gd")
	return YarnCompiler.compile_string(source,fileName,p,showTokens,printSyntax)

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
	var GDYarnUtils = YarnGlobals.GDYarnUtils
	var programs := []

	var sources := {}

	# load all source file yarn programs
	for filepath in _yarnPrograms:
		# ignore empty files
		if filepath.empty():
			continue

		var f := File.new()
		f.open(filepath,File.READ)
		sources[filepath] = f.get_as_text()

		f.close()

	# gather all line tags currently in the files
	var lineTags :Dictionary =  GDYarnUtils.get_tags_from_sources(sources)

	if "error" in lineTags: # conflict of line tags that needs to be resolved was found
		printerr(lineTags["error"])
		return

	# tag all untagged lines
	var changedFiles = GDYarnUtils.tag_untagged_lines(sources, lineTags)

	# save all changed files - TODO: change variable names to be more consitent in this function
	#                                file should not be file but file path instead, unless strictly
	#                                reffering to a file.
	for filepath in changedFiles:
		var file := File.new()
		file.open(filepath,File.WRITE)
		file.store_string(changedFiles[filepath])
		file.close()

	for source_file in sources.keys():
		var source = sources[source_file]
		if source.empty():
			continue

		var p = YarnProgram.new()

		var _ok = _load_program(p,source,source_file,showTokens,printSyntax)
		if _ok == OK:
			programs.append(p)
			print("compiled [%s] successfully!" % source_file)
		else:
			printerr("failed to compile [%s]."%source_file)
			return

	# combine all the programs into a single one
	var yarnProgram = ProgramUtils.combine_programs([]+programs)

	return yarnProgram


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
