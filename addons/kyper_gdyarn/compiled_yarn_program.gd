tool
extends Resource

class_name CompiledYarnProgram

const YarnGlobals = preload("res://addons/kyper_gdyarn/autoloads/execution_states.gd")
const YarnCompiler = preload("res://addons/kyper_gdyarn/core/compiler/compiler.gd")
const YarnProgram = preload("res://addons/kyper_gdyarn/core/program/program.gd")
const EXTENSION := ".cyarn"

export(Array, String, FILE, "*.yarn") var _yarnPrograms = [] setget set_file
export(String) var _program_name = "compiled_yarn_program"

# TODO: save this to a plain txt file and then load it in each
#       time before we run the program
var stringTable : Dictionary

var showTokens  := false
var printSyntax := false

export(Resource) var program

func _init():
	pass

func _load_program(source:String,fileName:String)->YarnProgram:
	var p : YarnProgram = YarnProgram.new()
	YarnCompiler.compile_string(source,fileName,p,stringTable,showTokens,printSyntax)
	return p

func _reload_all_programs(arr:Array):
	var programs := []
	for file in arr:
		if file.empty():
			continue
		var f := File.new()
		f.open(file,File.READ)
		var source := f.get_as_text()
		var p = _load_program(source,file)
		programs.append(p)
		f.close()
	if !programs.empty():
		program = YarnGlobals.combine_programs([]+programs)

func set_file(arr):

	if arr.size() > _yarnPrograms.size():
		# added new program file
		if !arr.back().empty() && !_yarnPrograms.has(arr.back()):
			var f = File.new()
			f.open(arr.back(),File.READ)
			var source : String = f.get_as_text()
			f.close()
			var p = _load_program(source,arr.back())
			program = p if !program else YarnGlobals.combine_programs([program,p])
		_yarnPrograms = arr

	elif arr.size() < _yarnPrograms.size():
		# removed program
		_reload_all_programs(arr)
		_yarnPrograms = arr
	else:
		# we did not remove any program but we updated
		# one of the current entries
		var index = _get_diff(arr)
		if index != -1 && !_yarnPrograms.has(arr[index]):
			_reload_all_programs(arr)
			_yarnPrograms = arr

#get the change so we can load/unload
func _get_diff(newOne:Array,offset:int = 0)->int:
	for i in range(offset,_yarnPrograms.size()):
		if _yarnPrograms[i] != newOne[i]:
			return i
	return -1

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
