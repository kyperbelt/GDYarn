extends Control

export(NodePath) var _textDisplay

export(Array,NodePath) var _options

const CHARS_PER_WORD : int = 6
#1 word is  6 chars per second (anything < 0 == instant)
export(float,-1,100) var _wordsPerSecond = 1
var lineElapsed : float = 0 
var totalTime : float = 0
var lineFinished : bool = false

var textDisplay 
var options : Array = []

var _dialogue
var _currentLine : String

#called when a line is first shown
signal line_shown
#called when the line is finished displaying
signal line_finished

signal dialogue_finished

func _ready():
	for option in _options:
		var o = get_node(option)
		options.append(o)
		o.visible = false

	textDisplay = get_node(_textDisplay)
	textDisplay.visible = false


func _process(delta):
	lineElapsed+=delta
	if(lineElapsed >= totalTime):
		lineFinished = true


	if !lineFinished && textDisplay!=null:
		textDisplay.text = _currentLine.substr(0,round(_currentLine.length()*(lineElapsed/totalTime)))

	

func feed_line(line:String):
	_currentLine = line
	totalTime = line.length() / (_wordsPerSecond * CHARS_PER_WORD)
	lineElapsed = 0
	lineFinished = false
	if(textDisplay!=null):
		emit_signal("line_shown")
		textDisplay.visible = true
		if(totalTime <= 0):
			lineFinished = true
			textDisplay.set_text(line)
			emit_signal("line_finished")

func finish_line():
	print("finished line")
	#allow user to handle this themselves through 
	#the use of signals and maybe commmands?
	# if textDisplay != null:
	# 	textDisplay.visible = false
	if(_dialogue.get_exec_state()!=YarnGlobals.ExecutionState.Stopped):
		_dialogue.resume()
	pass

func feed_options(options:Array):
	for i in range(options.size()):
		if i >= self.options.size():
			printerr("Tried to display more options than available gui components")
			break
		self.options[i].visible = true
		self.options[i].connect("pressed",self,"select_option",[i],CONNECT_ONESHOT)
		self.options[i].text = options[i]

		#self.options[i].set_text(options[i].line.)

func dialogue_finished():
	if(textDisplay!=null):
		textDisplay.visible = false
	emit_signal("dialogue_finished")

func select_option(selection:int):
	
	_dialogue.set_selected_option(selection)
	#hide all option buttons
	for i in range(options.size()):
		options[i].visible = false

	_dialogue.resume()
	pass

	
	
