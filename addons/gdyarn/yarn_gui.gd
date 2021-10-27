extends Control
### This is the default yarn display implementation that comes bundles out of the box
### for GDYarn. You are able to create your own if you need to but for general game development
### and prototyping purposes it should be enough.

class_name YarnDisplay, "res://addons/gdyarn/assets/display.PNG"


signal selection_made(selection)
signal line_finished

export(NodePath) var _yarnRunner

export(Array,NodePath) var _options

export(NodePath) var _textDisplay

#1 word is  6 chars per second (anything < 0 == instant)
export(float,-1,100) var _charactersPerSecond= 1
var lineElapsed : float = 0 
var totalTime : float = 0
var lineFinished : bool = false

export(bool) var _autoNext = false #automatically move to next line
export(float,0,2) var _autoNextWait = 1.75 #time to wait until next line when autonext is on
var autoNextElapsed : float = 0 
var nextLineRequested : bool = false #wether the next line has been requested by auto next - if yes then dont do it again

var textDisplay
var options : Array = []

var dialogueRunner
var dialogue
var currentLine : String


var selection := -1

func _ready():
	dialogueRunner = get_node(_yarnRunner)
	dialogueRunner.connect("dialogue_started",self,"show_display")
	dialogueRunner.connect("dialogue_finished",self,"hide_display")
	dialogueRunner.connect("line_emitted",self,"feed_line")
	dialogueRunner.connect("options_emitted",self,"feed_options")
	dialogueRunner.connect("command_emitted",self,"feed_command")
	connect("line_finished", dialogueRunner, "resume")
	connect("selection_made", dialogueRunner, "choose")

	for option in _options:
		var o = get_node(option)
		options.append(o)
		o.visible = false

	textDisplay = get_node(_textDisplay)
	textDisplay.visible = false


func show_display():
	self.visible = true


func hide_display():
	self.visible = false


func _process(delta):
	lineElapsed+=delta
	if(lineElapsed >= totalTime):
		if !lineFinished:
			textDisplay.bbcode_text=( currentLine if !currentLine.empty() else textDisplay.bbcode_text)
			currentLine = ""
		lineFinished = true

		if _autoNext && !nextLineRequested:
			autoNextElapsed+=delta
			if autoNextElapsed >= _autoNextWait:
				print("autNexted")
				finish_line()
				nextLineRequested = true
				

	if !lineFinished && textDisplay!=null:
		var newText : String = currentLine.substr(0,round(currentLine.length()*(lineElapsed/totalTime)))
		if newText!=textDisplay.get_text():
			textDisplay.bbcode_text = newText
			# emit_signal("text_changed")

func feed_command(command : String, args: Array, state : GDScriptFunctionState):

	if command == "textspeed" && args.size() > 0:
		_charactersPerSecond = abs(float(args[0]))


	if state.is_valid():
		state.resume()

	pass

func feed_line(line:String)->bool:
	# if(currentLine!= null && !currentLine.empty()):#current line not finished so wait
	# 	yield(self, "line_finished")
	print("tried to feed line : %s" % line)
	currentLine = line
	totalTime = line.length() / (_charactersPerSecond)
	lineElapsed = 0
	autoNextElapsed = 0
	lineFinished = false
	nextLineRequested = false
	if(textDisplay!=null):
		# emit_signal("line_shown")
		textDisplay.visible = true
		if(totalTime <= 0):
			lineFinished = true
			# emit_signal("line_finished")
			textDisplay.bbcode_text=(line)
			# emit_signal("line_finished")
	return true

func finish_line():
	if currentLine.empty()  && _textDisplay!=null:
		textDisplay.visible = false
		printerr(" finished line")
		emit_signal("line_finished")
	elif !currentLine.empty() && !lineFinished:
		lineElapsed = totalTime


	#allow user to handle this themselves through 
	#the use of signals and maybe commmands?
	# if textDisplay != null:
	# 	textDisplay.visible = false
	# if(dialogue.get_exec_state()!=YarnGlobals.ExecutionState.Stopped
	# 	&& dialogue.get_exec_state()!=YarnGlobals.ExecutionState.WaitingForOption):
	# 	if next_line:
	# 		currentLine = ""
	# 	if dialogueRunner.next_line.empty(): # TODO FIXME: Possible unnecessary coupling here. Remove and find some other way to check if there are lines queued up
	# 		dialogue.resume()
	# 	else:
	# 		dialogueRunner.consume_line() # TODO Figure out why we did this
	# pass


func feed_options(options:Array, dialogue):
	printerr("tried to feed otpions:%s" %  str(options))
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
	currentLine = ""

func select_option(selection:int):

	self.selection = selection
	emit_signal("selection_made", selection)

	# dialogue.set_selected_option(selection)
	#hide all option buttons
	for i in range(options.size()):
		options[i].visible = false

	# finish_line(true)
