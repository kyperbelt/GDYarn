extends Object

const Operand = preload("res://addons/gdyarn/core/program/operand.gd")

var operation: int  #bytcode
var operands: Array  #Operands


func _init(other = null):
	if other != null && other.get_script() == self.get_script():
		self.operation = other.operation
		self.operands += other.operands


func dump(program, library) -> String:
	return "InstructionInformation:NotImplemented"
