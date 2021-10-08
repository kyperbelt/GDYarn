extends Object

const Line = preload("res://addons/gdyarn/core/dialogue/line.gd")

var line : Line
var id : int 
var destination : String

func _init(line : Line,id : int, destination: String):
    self.line = line
    self.id = id
    self.destination = destination

