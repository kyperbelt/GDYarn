extends Resource

export var programName : String
export var yarnStrings : Dictionary = {}
export var yarnNodes : Dictionary = {}

func _init():
    yarnNodes = {}
    yarnStrings = {}
    programName = ""

func get_node_tags(name:String)->Array:
    return yarnNodes[name].tags

func get_yarn_string(key:String)->String:
    return yarnStrings[key]

func get_node_text(name:String)->String:
    var key = yarnNodes[name].sourceId
    return get_yarn_string(key)

func has_yarn_node(name : String)-> bool:
    return yarnNodes.has(name)

#possible support for line tags
func get_untagged_strings()->Dictionary:
    return {}

# merge this program with the other
func merge(other):
    pass

# include the other program in this one
func include(other):
    pass

# dump all the instructions into a readable format
func dump(library):
    print("not yet implemented")
    pass
