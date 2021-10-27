var text : String
var nodeName : String 
var lineNumber : int
var fileName : String
var implicit : bool
var meta : PoolStringArray = []

func _init(text:String,nodeName:String,lineNumber:int,fileName:String,implicit:bool,meta:PoolStringArray):
    self.text = text
    self.nodeName = nodeName
    self.lineNumber = lineNumber
    self.fileName = fileName
    self.implicit = implicit
    self.meta = meta
