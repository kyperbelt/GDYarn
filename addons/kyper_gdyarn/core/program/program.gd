extends Node

var programName : String
var yarnStrings : Dictionary = {}
var yarnNodes : Dictionary = {}

func get_node_tags(name:String)->Array:
    return yarnNodes[name].tags

func get_yarn_string(key:String)->String:
    return yarnStrings[key]

func get_node_text(name:String)->String:
    var key = yarnNodes[name].sourceId
    return get_yarn_string(key)

#possible support for line tags
func get_untagged_strings()->Dictionary:
    return {}

func merge(other):
    pass

func include(other):
    pass

func dump(library):
    print("not yet implemented")
    pass
    