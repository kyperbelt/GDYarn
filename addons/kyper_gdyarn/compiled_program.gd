extends Resource

class_name CompiledProgram

const EXTENSION := ".cyarn"

export(Array, String, FILE, "*.yarn") var _yarnPrograms = []
export(String) var _program_name = "compiled_yarn_program"
