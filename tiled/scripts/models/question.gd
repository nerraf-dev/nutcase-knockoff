class_name Question
extends Resource

@export var question_id: int = 0
@export var question_text: String = ""
@export var answer: String = ""
@export var alt_answers: Array[String] = []
@export var fun_fact: String = ""
@export_enum("easy", "medium", "hard") var difficulty: String = "medium"
@export var category: String = "General"
@export var tags: Array[String] = []
