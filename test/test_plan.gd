
class_name TestPlan

enum StepType{
    Line, 
    Option, 
    Select, 
    Command, 
    Stop
}


class Step:
    var type: StepType
    var value
    var expect_option_enabled: bool = true