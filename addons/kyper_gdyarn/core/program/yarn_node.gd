extends Object

var nodeName : String 
var instructions : Array = []
var labels : Dictionary
var tags: Array
var sourceId : String

func _init(other = null):
    if other != null && other.get_script() == self.get_script():
        nodeName = other.nodeName
        instructions+=other.instructions
        for key in other.labels.keys():
            labels[key] = other.labels[key]
        tags += other.tags
        sourceId = other.sourceId

func equals(other)->bool:

    if other.get_script() != self.get_script():
        return false
    if other.name != self.name:
        return false
    if other.instructions != self.instructions:
        return false
    if other.label != self.label:
        return false
    if other.sourceId != self.sourceId:
        return false
    return true

func _to_string():
    return "Node[%s:%s]"  % [nodeName,sourceId]
