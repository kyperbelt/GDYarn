tool
extends EditorPlugin


var Autoloads : Dictionary = {
	"YarnGlobals":"res://addons/kyper_gdyarn/autoloads/execution_states.gd"
}

var Nodes : Dictionary = {
	#name            #parent         #script                                     #icon
	"YarnRunner" : ["Node" , "res://addons/kyper_gdyarn/yarn_runner.gd", "res://addons/kyper_gdyarn/assets/runner.PNG"],
}

func _enter_tree():
	for auto in Autoloads.keys():
		add_autoload_singleton(auto,Autoloads[auto])

	for node in Nodes.keys():
		add_custom_type(node,Nodes[node][0],load(Nodes[node][1]),load(Nodes[node][2]))


func _exit_tree():
	for auto in Autoloads.keys():
		remove_autoload_singleton(auto)

	for node in Nodes.keys():
		remove_custom_type(node)

