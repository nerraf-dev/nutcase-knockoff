extends RefCounted

class_name GameBoardControllerSync

var board: Node = null


func _init(p_board: Node = null) -> void:
	board = p_board


func broadcast_scores() -> void:
	if board == null or NetworkManager.is_local:
		return
	NetworkManager.broadcast_scores(PlayerManager.players)


func broadcast_turn() -> void:
	if board == null or NetworkManager.is_local:
		return

	var current = PlayerManager.get_current_player()
	if current == null:
		return

	NetworkManager.broadcast_turn_changed(current.id)
	if current.device_id != "":
		NetworkManager.broadcast_your_turn(current.device_id, current.id)


func broadcast_new_round() -> void:
	if board == null or NetworkManager.is_local:
		return
	if board.round_instance == null:
		return

	var slider_count := 9
	if board.round_instance.has_method("get") and board.round_instance.get("current_question") != null:
		var words = board.round_instance.current_question.question_text.split(" ")
		slider_count = words.size()

	NetworkManager.broadcast_new_round(GameManager.game.current_round, slider_count)


func broadcast_overlay_prompt(active: bool, message: String) -> void:
	if board == null or NetworkManager.is_local:
		return
	NetworkManager.broadcast_overlay_prompt(active, message)