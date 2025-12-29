class_name QuestionLoader
extends RefCounted

static func load_questions_from_file(file_path: String) -> Array[Question]:
	var questions: Array[Question] = []
	
	if not FileAccess.file_exists(file_path):
		push_error("Question file not found: " + file_path)
		return questions
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open question file: " + file_path)
		return questions
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return questions
	
	var data = json.get_data()
	
	if not data is Array:
		push_error("JSON root must be an array")
		return questions
	
	for item in data:
		if not item is Dictionary:
			continue
		
		var question = Question.new()
		question.question_text = item.get("question", "")
		question.answer = item.get("answer", "")
		question.difficulty = item.get("difficulty", "medium")
		question.category = item.get("category", "General")
		
		# Handle tags array
		if item.has("tags") and item["tags"] is Array:
			var tags_array: Array[String] = []
			for tag in item["tags"]:
				tags_array.append(str(tag))
			question.tags = tags_array
		
		questions.append(question)
	
	print("Loaded %d questions from %s" % [questions.size(), file_path])
	return questions

static func get_random_question(questions: Array[Question]) -> Question:
	if questions.is_empty():
		return null
	return questions[randi() % questions.size()]

static func filter_by_difficulty(questions: Array[Question], difficulty: String) -> Array[Question]:
	var filtered: Array[Question] = []
	for q in questions:
		if q.difficulty == difficulty:
			filtered.append(q)
	return filtered

static func filter_by_category(questions: Array[Question], category: String) -> Array[Question]:
	var filtered: Array[Question] = []
	for q in questions:
		if q.category == category:
			filtered.append(q)
	return filtered
