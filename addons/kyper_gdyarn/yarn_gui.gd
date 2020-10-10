extends Control

export(NodePath) var _textDisplay

export(Array,NodePath) var _options

var textDisplay 
var options : Array = []

var _dialogue 

#called when a line is shown
signal line_shown

func _ready():
    for option in _options:
        var o = get_node(option)
        options.append(o)
        o.visible = false

    textDisplay = get_node(_textDisplay)
    textDisplay.visible = false


func feed_line(line:String):
    if(textDisplay!=null):
        textDisplay.visible = true
        textDisplay.set_text(line)
        emit_signal("line_shown")

func finish_line():
    print("finished line")
    pass

func feed_options(options:Array):
    for i in range(options.size()):
        if i >= self.options.size():
            printerr("Tried to display more options than available gui components")
            break
        self.options[i].visible = true
        self.options[i].set_text(options[i])

func select_option(selection:int):
    pass

    
    
