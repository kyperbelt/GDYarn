@tool
extends VBoxContainer

signal compile_clicked(showTokens, printSyntax)

@export var CompileButton: NodePath
@export var ShowTokens: NodePath
@export var PrintTree: NodePath
@export var TestButton: NodePath
@export var OpenDialog: NodePath
@export var Dialog: NodePath


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node(CompileButton).connect("pressed", Callable(self, "_clicked"))
	get_node(OpenDialog).connect("pressed", Callable(self, "_open_dialog"))
	get_node(TestButton).connect("pressed", Callable(self, "_close_dialog"))
	pass  # Replace with function body.


func _clicked():
	emit_signal("compile_clicked", get_node(ShowTokens).pressed, get_node(PrintTree).pressed)


func _open_dialog():
	get_node(Dialog).popup_centered()


func _close_dialog():
	(get_node(Dialog) as Popup).hide()
