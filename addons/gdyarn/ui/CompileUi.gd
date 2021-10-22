tool
extends VBoxContainer

signal compile_clicked(showTokens, printSyntax)

export(NodePath) var CompileButton
export(NodePath) var ShowTokens
export(NodePath) var PrintTree
export(NodePath) var TestButton
export(NodePath) var OpenDialog
export(NodePath) var Dialog


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node(CompileButton).connect("pressed", self, "_clicked")
	get_node(OpenDialog).connect("pressed", self, "_open_dialog")
	get_node(TestButton).connect("pressed",self,"_close_dialog")
	pass # Replace with function body.

func _clicked():
	emit_signal("compile_clicked",get_node(ShowTokens).pressed, get_node(PrintTree).pressed)

func _open_dialog():
	get_node(Dialog).popup_centered()

func _close_dialog():
	(get_node(Dialog) as PopupDialog).hide()
