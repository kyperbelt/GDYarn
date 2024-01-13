class_name CompiledYarnNode
extends Object

var node_name: String
var instructions: Array[YarnInstruction] = []
var labels: Dictionary
var tags: Array[String]
var source_id: String


func _init(other = null):
	if other != null && other.get_script() == self.get_script():
		node_name = other.node_name
		instructions += other.instructions
		for key in other.labels.keys():
			labels[key] = other.labels[key]
		tags += other.tags
		source_id = other.source_id


func equals(other) -> bool:
	if other.get_script() != self.get_script():
		return false
	if other.name != self.name:
		return false
	if other.instructions != self.instructions:
		return false
	if other.label != self.label:
		return false
	if other.source_id != self.source_id:
		return false
	return true


func _to_string():
	return "Node[%s:%s]" % [node_name, source_id]
