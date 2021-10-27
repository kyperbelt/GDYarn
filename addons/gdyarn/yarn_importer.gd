tool
extends EditorImportPlugin

class_name YarnImporter

const YARN_TRACKER_PATH := "res://.tracked_yarn_files"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_importer_name():
	return "gdyarn.yarnFile"

func get_visible_name():
	return "Yarn Files"


func get_recognized_extensions():
	return ["yarn"]

func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"

enum Presets{Default}

func get_preset_count():
	return 1

func get_import_options(preset):
	return []

func get_preset_name(preset):
	for key in Presets.keys():
		if Presets[key] == preset:
			return key
	return "Unknown"

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, platform_variants, gen_files):



	print("imported -> "+ source_file)

	# get all files in the file tracker

	var trackedFiles := PoolStringArray([])
	var trackerFile := File.new()

	if trackerFile.file_exists(YARN_TRACKER_PATH):
		trackerFile.open(YARN_TRACKER_PATH,File.READ)
		trackedFiles = trackerFile.get_as_text().split('\n')

	if !(source_file in trackedFiles):
		trackedFiles.append(source_file)

	# check that all files exist, if they dont then delte them

	trackerFile.close()

	var fc := File.new()

	var indexesToRemove := []
	for i in range(trackedFiles.size()):
		if !fc.file_exists(trackedFiles[i]):
			indexesToRemove.append(i)

	for i in indexesToRemove:
		trackedFiles.remove(i)

	trackerFile = File.new()
	trackerFile.open(YARN_TRACKER_PATH,File.WRITE)
	trackerFile.store_string(trackedFiles.join('\n'))
	trackerFile.close()

	var saveFilePath = "%s.%s" % [save_path,get_save_extension()]
	fc = File.new()
	if fc.file_exists(saveFilePath):
		return OK

	var yarnFile = Resource.new()
	yarnFile.resource_path = source_file
	yarnFile.resource_name = source_file.get_file()

	return ResourceSaver.save(saveFilePath,yarnFile)
