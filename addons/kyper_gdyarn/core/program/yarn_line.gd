extends Object

var text : String
var nodeName : String 
var lineNumber : int
var fileName : String
var implicit : bool
var meta : Array = []

func _init(text:String,nodeName:String,lineNumber:int,fileName:String,implicit:bool,meta:Array):
    self.text = text
    self.nodeName = nodeName
    self.fileName = fileName
    self.implicit = implicit
    self.meta = meta
 