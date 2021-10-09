tool
extends HBoxContainer

signal compile_clicked(showTokens, printSyntax)

onready var CompileButton = $CompileButton
onready var ShowTokens = $ShowTokens/CheckBox
onready var PrintTree = $PrintTree/CheckBox
# Called when the node enters the scene tree for the first time.
func _ready():
	CompileButton.connect("pressed", self, "_clicked")
	pass # Replace with function body.

func _clicked():
	emit_signal("compile_clicked",ShowTokens.pressed, PrintTree.pressed)
