################### LineTag Utilities #########################

const lineTagPattern: String = "#line:(?:[0-9]|(?:a|b|c|d|e|f))+"
const commandStartPatern: String = "^(?:<<)"
const commentTrimPattern: String = "(?(?=^\/\/)|(?(?=.*\/\/)(?:.+?(?=\/\/))|.*))"


# Generate a line tag using a 32bit hex value
# this is 8 bits larger than the yarnspinner implementation
# which should prevent collisions between nodes
static func generate_line_tag(s: int) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = s
	var tagNum = rng.randi()
	return "line:%x" % tagNum


# tag all untagged lines in the sources and then return any files that need to be saved to disk
# will return in the format {file,new_source}
static func tag_untagged_lines(sources: Dictionary, tags: Dictionary) -> Dictionary:
	var changedFiles := {}

	for source_key in sources:
		var source = sources[source_key]
		var lineNumber: int = 0
		var changed: bool = false

		var fileLines: PoolStringArray = source.split("\n", true)
		# printerr("source lines %s" % fileLines.size())
		for i in range(fileLines.size()):
			fileLines[i] = fileLines[i].strip_edges(false, true)

		while lineNumber < fileLines.size():
			# get title
			while lineNumber < fileLines.size() && fileLines[lineNumber] != "---":
				lineNumber += 1

			lineNumber += 1

			while lineNumber < fileLines.size() && fileLines[lineNumber] != "===":
				var tag = get_line_tag(fileLines[lineNumber])
				if should_tag_line(fileLines[lineNumber]) && tag.empty():
					# no tag found so we make one
					var tagSeed = (
						(
							33 * lineNumber * OS.get_time().second
							+ source_key.hash()
							+ fileLines[lineNumber].hash()
						)
						% 65537
					)
					var searchingForValidTag = true
					while searchingForValidTag:
						tag = generate_line_tag(tagSeed)

						print("returning tag : %s" % tag)
						if !tags.has(tag):
							tags[tag] = source_key
							changed = true
							fileLines.set(lineNumber, add_tag_to_line(fileLines[lineNumber], tag))
							searchingForValidTag = false
							print("tag added ")
						else:
							tagSeed = ((tagSeed << 1) * 89) % 65537

				lineNumber += 1

			lineNumber += 1
		if changed:
			sources[source_key] = fileLines.join("\n")
			changedFiles[source_key] = sources[source_key]

	return changedFiles


# get all the line tags from the sources dictionary passed in
# entries in the dictioanry are in the format {file : source}
# returns dictionary with an error:message key value pair if there was a conflict
static func get_tags_from_sources(sources):
	var lineTags: Dictionary = {}

	for source_key in sources:
		var source = sources[source_key]
		var lineNumber: int = 0

		var fileLines: Array = source.split("\n", true)
		# printerr("source lines %s" % fileLines.size())
		for i in range(fileLines.size()):
			fileLines[i] = fileLines[i].strip_edges(false, true)

		while lineNumber < fileLines.size():
			# get title
			while lineNumber < fileLines.size() && fileLines[lineNumber] != "---":
				lineNumber += 1

			lineNumber += 1

			while lineNumber < fileLines.size() && fileLines[lineNumber] != "===":
				var tag = get_line_tag(fileLines[lineNumber])
				if lineTags.has(tag):
					return {
						"error":
						(
							"duplicate line tag[%s] in file[%s] and file[%s]"
							% [tag, source_key, lineTags[tag]]
						)
					}
				if !tag.empty():
					lineTags[tag] = source_key
				lineNumber += 1

			lineNumber += 1

	return lineTags


# get all the tags in the node body
static func get_all_tags(sourceLines: Array) -> Array:
	var results := []
	for line in sourceLines:
		var lineTag = get_line_tag(line)
		if !lineTag.empty():
			results.append(lineTag)
	return results


# get the line tag for the passd in line
#
# we will stop looking once we start a comment line,
# reach the end, or find a line tag in the form #line:<value>
static func get_line_tag(line: String) -> String:
	# regex used to trim the comments from lines
	var commentTrimRegex: RegEx = RegEx.new()

	# regex to get the line tag in the line if it exists
	var lineTagRegex: RegEx = RegEx.new()

	commentTrimRegex.compile(commentTrimPattern)
	lineTagRegex.compile(lineTagPattern)
	# then we strip the line of comments
	# this is to make sure that we are not finding any tags that are
	# commented out
	var trimmedLine: RegExMatch = commentTrimRegex.search(line)

	if trimmedLine && !trimmedLine.get_string().empty():
		# find the line tag and return it if found
		var lineTagMatch := lineTagRegex.search(trimmedLine.get_string())

		if lineTagMatch:
			return lineTagMatch.get_string()

	return ""


static func add_tag_to_line(line: String, tag: String) -> String:
	# regex used to trim the comments from lines
	var commentTrimRegex: RegEx = RegEx.new()

	commentTrimRegex.compile(commentTrimPattern)
	var strippedLine = strip_line_tag(line)

	# trim comments
	var trimmedLineMatch := commentTrimRegex.search(strippedLine)

	if !trimmedLineMatch || trimmedLineMatch.get_string().empty():
		return strippedLine

	var comments: String = strippedLine.replace(trimmedLineMatch.get_string(), "")

	var trimmedLine := trimmedLineMatch.get_string()

	return "%s %s %s" % [trimmedLineMatch.get_string(), "#" + tag, comments]


# check if line should be tagged
static func should_tag_line(line: String) -> bool:
	# regex used to trim the comments from lines
	var commentTrimRegex: RegEx = RegEx.new()

	# regex used to check if lien starts with command - if it does then we ignore it
	var commandStartRegex: RegEx = RegEx.new()

	commentTrimRegex.compile(commentTrimPattern)
	commandStartRegex.compile(commandStartPatern)
	if (
		commandStartRegex.search(line.strip_edges())
		|| !commentTrimRegex.search(line)
		|| commentTrimRegex.search(line).get_string().empty()
	):
		return false
	return true


# removes the #line: tag from the line if it exists
static func strip_line_tag(line: String) -> String:
	var commentTrimRegex: RegEx = RegEx.new()
	var commandStartRegex: RegEx = RegEx.new()
	var lineTagRegex: RegEx = RegEx.new()
	commentTrimRegex.compile(commentTrimPattern)
	commandStartRegex.compile(commandStartPatern)
	lineTagRegex.compile(lineTagPattern)

	# if line starts with command, then do nothing
	if commandStartRegex.search(line):
		return line

	# trim comments
	var trimmedLineMatch := commentTrimRegex.search(line)

	if !trimmedLineMatch || trimmedLineMatch.get_string().empty():
		return line

	var trimmedLine := trimmedLineMatch.get_string()

	# find and replace line tag if found

	var lineTagMatch := lineTagRegex.search(trimmedLine)

	if lineTagMatch:
		return line.replace(lineTagMatch.get_string(), "")

	return line


######################### CSV Utilities #########################

# need to seperate headers from the content and create
# an array that will be are look up table
# [id, topic1, topic2, topic3]

# then we need to split each line into its array of entries
# [lineId, entry1 , entry2, entry3]

# I should the be able to say, change the entry off topic1 for line with lineidX
# and we can use the topic index to quickly access it.


# return an array of headers and a poolstring Array containing
#               [Headers:PoolStringArray, csvLines : Array [PoolStringArray]]
static func csv_from_text(fileText: String, delim: String = ",") -> Array:
	var splits := fileText.split("\n")
	var csvLines := []
	var headers := splits[0].split(delim)
	for i in range(headers.size()):
		headers.set(i, headers[i].strip_edges())
	splits.remove(0)
	for line in splits:
		var csvLine: PoolStringArray = line.split(delim)
		csvLine.set(0, csvLine[0].strip_edges())
		csvLines.append(csvLine)
	return [headers, csvLines]


# search all the csvLines using the id( 0th element )
static func get_row_of_id(csvLines: Array, id: String) -> int:
	for i in range(csvLines.size()):
		if csvLines[i][0].id == id:
			return i
	return -1


# get the col index of the header if found in the headers
static func get_col_of_header(headers: PoolStringArray, head: String) -> int:
	return Array(headers).find(head)


# generate csv text from file
static func text_from_csv(headers: PoolStringArray, csvLines: Array, delim: String = ",") -> String:
	csvLines.insert(0, headers)
	var lines: PoolStringArray = []

	for line in csvLines:
		lines.append(line.join(delim))

	return lines.join("\n")


static func set_data_at(data: String, csvLines: Array, row: int, col: int) -> bool:
	if csvLines.size() > row && csvLines[row].size() > col:
		csvLines[row].set(col, data)
		return true
	return false


# takes in an array of PoolStringArrays
static func get_data_at(csvLines: Array, row: int, col: int) -> String:
	if csvLines.size() > row && csvLines[row].size() > col:
		return csvLines[row][col].strip_edges()
	return ""
