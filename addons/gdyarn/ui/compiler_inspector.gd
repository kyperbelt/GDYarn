extends EditorInspectorPlugin

var compilerUi : PackedScene= preload("res://addons/gdyarn/ui/CompileUi.tscn")

func can_handle(object):
	if object.has_method("_handle_command"):
		return true
	return false

func parse_begin(object):
	var instance = compilerUi.instance()
	if !instance.is_connected("compile_clicked",object,"_compile_programs"):
		instance.connect("compile_clicked",object,"_compile_programs")

	add_custom_control(instance)
