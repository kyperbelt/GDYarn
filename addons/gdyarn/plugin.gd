tool
extends EditorPlugin

const CompilerInspector: Script = preload("res://addons/gdyarn/ui/compiler_inspector.gd")
const LocalizerScene: PackedScene = preload("res://addons/gdyarn/ui/LocalizerGui.tscn")

var Autoloads: Dictionary = {
	"NumberPlurals": "res://addons/gdyarn/autoloads/number_plurals.gd",
	"YarnGlobals": "res://addons/gdyarn/autoloads/execution_states.gd",
	# "GDYarnUtils" : "res://addons/gdyarn/autoloads/gdyarn_utilities.gd"
}

var Nodes: Dictionary = {
	#name            #parent         #script                                     #icon
	"YarnRunner":
	["Node", "res://addons/gdyarn/yarn_runner.gd", "res://addons/gdyarn/assets/runner.PNG"],
}

var localizerGui
var compilerInspector

var yarnImporter = null


func _enter_tree():
	yarnImporter = YarnImporter.new()
	add_import_plugin(yarnImporter)

	localizerGui = LocalizerScene.instance()
	add_child(localizerGui)
	localizerGui._initiate()
	for auto in Autoloads.keys():
		add_autoload_singleton(auto, Autoloads[auto])

	for node in Nodes.keys():
		add_custom_type(node, Nodes[node][0], load(Nodes[node][1]), load(Nodes[node][2]))

	compilerInspector = CompilerInspector.new()

	# localizer
	add_tool_menu_item("GDYarn Localizer", self, "open_localizer_gui")

	# inspector plugin
	add_inspector_plugin(compilerInspector)


func _exit_tree():
	for auto in Autoloads.keys():
		remove_autoload_singleton(auto)

	for node in Nodes.keys():
		remove_custom_type(node)

	remove_inspector_plugin(compilerInspector)
	remove_tool_menu_item("GDYarn Localizer")
	remove_import_plugin(yarnImporter)

	yarnImporter = null


func open_localizer_gui(ud):
	print(ud)
	localizerGui.popup_centered()
