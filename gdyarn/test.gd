extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var regex : RegEx = RegEx.new()
	var pat = "\"([^\"\\\\]*(?:\\.[^\"\\\\]*)*)\""
	var _ok = regex.compile(pat)
	var test = " this is a test string \"Hello World!\" and this anotherone <\"HAHAHAHAHAH  \">"

	for result in regex.search_all(test,38):
		print(result.get_string()+" %s" % result.get_start())

	var test2 = " this is\t a tabbed \tstring"

	print("before:%s"%test2)
	print("after:%s"%test2.replace("\t","cars"))

	print("this is it fam \\\\".replace("\\\\","\\"))

	print(varArgFunc([1,2,3,4,5,6]))


func varArgFunc(args:Array)->int:
	return args.size()
	
