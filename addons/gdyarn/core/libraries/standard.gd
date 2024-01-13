extends "res://addons/gdyarn/core/library.gd"


func _init():
	register_function("Add", 2, add, true)
	register_function("Minus", 2, sub, true)
	register_function("UnaryMinus", 1, unary_minus, true)
	register_function("Divide", 2, div, true)
	register_function("Multiply", 2, mul, true)
	register_function("Modulo", 2, mod, true)
	register_function("EqualTo", 2, equal, true)
	register_function("NotEqualTo", 2, noteq, true)
	register_function("GreaterThan", 2, ge, true)
	register_function("GreaterThanOrEqualTo", 2, geq, true)
	register_function("LessThan", 2, le, true)
	register_function("LessThanOrEqualTo", 2, leq, true)
	register_function("And", 2, land, true)
	register_function("Or", 2, lor, true)
	register_function("Xor", 2, xor, true)
	register_function("Not", 1, lnot, true)


func add(param1, param2):
	return param1.add(param2)


func sub(param1, param2):
	return param1.sub(param2)


func unary_minus(param1):
	return param1.negative()


func div(param1, param2):
	return param1.div(param2)


func mul(param1, param2):
	return param1.mult(param2)


func mod(param1, param2):
	return param1.mod(param2)


func equal(param1, param2):
	return param1.equals(param2)


func noteq(param1, param2):
	return !param1.equals(param2)


func ge(param1, param2):
	return param1.greater(param2)


func geq(param1, param2):
	return param1.geq(param2)


func le(param1, param2):
	return param1.less(param2)


func leq(param1, param2):
	return param1.leq(param2)


func land(param1, param2):
	return param1.as_bool() && param2.as_bool()


func lor(param1, param2):
	return param1.as_bool() || param2.as_bool()


func xor(param1, param2):
	return param1.xor(param2)


func lnot(param1):
	return !param1.as_bool()
