extends Control

export(NodePath) var _textDisplay

export(Array,NodePath) var _options

const CHARS_PER_WORD : int = 6
#1 word is  6 chars per second (anything < 0 == instant)
export(float,-1,100) var _wordsPerSecond = 1
var lineElapsed : float = 0 
var totalTime : float = 0
var lineFinished : bool = false

export(bool) var _autoNext = false #automatically move to next line
export(float,0,2) var _autoNextWait = 1.75 #time to wait until next line when autonext is on
var autoNextElapsed : float = 0 
var nextLineRequested : bool = false #wether the next line has been requested by auto next - if yes then dont do it again


var textDisplay 
var options : Array = []

var _dialogueRunner
var _dialogue
var _currentLine : String

#called when a line is first shown
signal line_shown
#called when the line is finished displaying
signal line_finished

signal dialogue_finished
#called when the line text is changed
signal text_changed

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
		if !lineFinished:
			emit_signal("line_finished")
			finish_line(false)
			textDisplay.text = _currentLine if !_currentLine.empty() else textDisplay.text
		lineFinished = true
		
		if _autoNext && !nextLineRequested:
			autoNextElapsed+=delta
			if autoNextElapsed >= _autoNextWait:
				print("autNexted")
				finish_line(true)
				nextLineRequested = true
				

	if !lineFinished && textDisplay!=null:
		var newText : String = _currentLine.substr(0,round(_currentLine.length()*(lineElapsed/totalTime)))
		if newText!=textDisplay.text:
			textDisplay.text = newText
			emit_signal("text_changed")

	

func feed_line(line:String)->bool:
	if(_currentLine!= null && !_currentLine.empty()):#current line not finished so wait
		return false
	_currentLine = line
	totalTime = line.length() / (_wordsPerSecond * CHARS_PER_WORD)
	lineElapsed = 0
	autoNextElapsed = 0
	lineFinished = false
	nextLineRequested = false
	if(textDisplay!=null):
		emit_signal("line_shown")
		textDisplay.visible = true
		if(totalTime <= 0):
			lineFinished = true
			textDisplay.set_text(line)
			emit_signal("line_finished")
	return true

func finish_line(next_line:bool = true):
	if _currentLine.empty() && next_line && _textDisplay!=null:
		textDisplay.visible = false
		emit_signal("dialogue_finished")
	elif next_line && !_currentLine.empty() && !lineFinished:
		lineElapsed = totalTime
		return

	#allow user to handle this themselves through 
	#the use of signals and maybe commmands?
	# if textDisplay != null:
	# 	textDisplay.visible = false
	if(_dialogue.get_exec_state()!=YarnGlobals.ExecutionState.Stopped 
		&& _dialogue.get_exec_state()!=YarnGlobals.ExecutionState.WaitingForOption):
		if next_line:
			_currentLine = ""
		if _dialogueRunner.next_line.empty():
			_dialogue.resume()
		else:
			_dialogueRunner.consume_line()
			


			
	pass

func feed_options(options:Array):
	for i in range(options.size()):
		if i >= self.options.size():
			printerr("Tried to display more options than available gui components")
			break
		self.options[i].visible = true
		if self.options[i].is_connected("pressed",self,"select_option"):
			self.options[i].disconnect("pressed",self,"select_option")

		self.options[i].connect("pressed",self,"select_option",[i])
		self.options[i].text = options[i]

		#self.options[i].set_text(options[i].line.)

func dialogue_finished():
	_currentLine = ""

func select_option(selection:int):

	_dialogue.set_selected_option(selection)
	#hide all option buttons
	for i in range(options.size()):
		options[i].visible = false

	finish_line(true)

	
	
