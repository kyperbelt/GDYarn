extends Resource

var programName: String
var yarnStrings: Dictionary = {}
var yarnNodes: Dictionary = {}

# an array of line Info data that gets exported to file
# stripped of the text information that is saved to another file
var _lineInfos: Array = []


func _init():
	yarnNodes = {}
	yarnStrings = {}
	programName = ""


func get_node_tags(name: String) -> Array:
	return yarnNodes[name].tags


func get_yarn_string(key: String) -> String:
	return yarnStrings[key]


func get_node_text(name: String) -> String:
	var key = yarnNodes[name].sourceId
	return get_yarn_string(key)


func has_yarn_node(name: String) -> bool:
	return yarnNodes.has(name)


#possible support for line tags
func get_untagged_strings() -> Dictionary:
	return {}


# merge this program with the other
func merge(other):
	pass


# include the other program in this one
func include(other):
	# same as merge
	# TODO: Remove merge and just keep include as it makes more semantic sense
	#       since we are not returning a new program containing the other one.
	pass


# dump all the instructions into a readable format
func dump(library):
	print("not yet implemented")
	pass
