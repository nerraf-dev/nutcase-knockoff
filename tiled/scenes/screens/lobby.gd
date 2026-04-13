extends Node2D

@onready var room_code_label = $RoomInfoContainer/Code
@onready var players_list = $PlayersContainer/Players
@onready var instructions_label = $JoinContainer/instructions
@onready var qr_code_rect = $JoinContainer/QrCode
@onready var start_button = $StartBtn
@onready var home_button = $HomeBtn

signal lobby_start_requested(settings: Dictionary)
signal lobby_back_to_home
signal lobby_back_to_setup

const p_badge = preload("res://scenes/components/player_badge.tscn")
const QR_CODE_SCRIPT = preload("res://scripts/third_party/qrcode/qr_code.gd")
const QR_TARGET_PIXEL_SIZE := 200

var _setup_settings: Dictionary = {}
var ready_by_device: Dictionary = {}


func configure(settings: Dictionary) -> void:
	_setup_settings = settings.duplicate(true)


func _ready() -> void:
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not home_button.pressed.is_connected(_on_home_button_pressed):
		home_button.pressed.connect(_on_home_button_pressed)

	# Display controller URL for players to join
	var controller_url = ControllerServer.get_controller_url()
	instructions_label.text = "Scan the QR code with your phone or head straight to: [b]%s[/b]" % controller_url
	qr_code_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


	if NetworkManager.is_local == false:
		NetworkManager.start_server()
		room_code_label.text = "Room Code: %s" % NetworkManager.room_code
		NetworkManager.player_join_received.connect(_on_player_joined)
		NetworkManager.client_disconnected.connect(_on_player_disconnected)
		NetworkManager.player_ready_received.connect(_on_player_ready)

		_update_players_list()
		_update_start_button_state()
	else:
		room_code_label.text = "Offline Lobby (Multiplayer mode not active)"

	var qr_code = QR_CODE_SCRIPT.new()

	# Use MEDIUM correction level (enum value 1) when available.
	if qr_code.get("error_correct_level") != null:
		qr_code.error_correct_level = 1

	var qr_texture: ImageTexture = qr_code.get_texture(controller_url)
	qr_code.queue_free()

	if qr_texture:
		qr_code_rect.texture = _make_crisp_qr_texture(qr_texture, QR_TARGET_PIXEL_SIZE)
		qr_code_rect.custom_minimum_size = Vector2(QR_TARGET_PIXEL_SIZE, QR_TARGET_PIXEL_SIZE)
		qr_code_rect.visible = true
	else:
		qr_code_rect.visible = false


func _make_crisp_qr_texture(source_texture: ImageTexture, target_size_px: int) -> ImageTexture:
	var source_image := source_texture.get_image()
	if source_image == null:
		return source_texture

	var source_width := source_image.get_width()
	if source_width <= 0:
		return source_texture

	# Use integer scaling to keep hard module edges (no blur).
	var scale := maxi(1, int(floor(float(target_size_px) / float(source_width))))
	var final_size := source_width * scale
	source_image.resize(final_size, final_size, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(source_image)


func _on_player_joined(device_id: String, player_name: String, avatar_index: int) -> void:
	print("Player joined: %s (Device ID: %s)" % [player_name, device_id])
	#  validate input
	var res = InputValidator.validate_player_name(player_name)
	if res["valid"] == false:
		print("Invalid player name '%s' from device %s, rejecting join" % [player_name, device_id])
		print("Reason: %s" % res["error"])
		return
	if avatar_index < 0 or avatar_index >= GameConfig.PLR_BADGE_ICONS.size():
		print("Invalid avatar index %d from device %s, rejecting join" % [avatar_index, device_id])
		return

	# Upsert by device_id so reconnect/profile edits do not create duplicates.
	var existing = PlayerManager.get_player_by_device_id(device_id)
	if existing == null:
		PlayerManager.add_player(player_name, device_id, avatar_index)
	else:
		existing.name = player_name
		existing.avatar_index = avatar_index

	# Joining or rejoining resets ready state until player confirms again.
	ready_by_device[device_id] = false
	
	_update_players_list()
	_update_start_button_state()

func _on_player_ready(device_id: String, is_ready: bool) -> void:
	var player = PlayerManager.get_player_by_device_id(device_id)
	if player == null:
		print("Received ready signal from unknown device %s, ignoring" % device_id)
		return

	ready_by_device[device_id] = is_ready
	print("Ready state changed: %s -> %s" % [player.name, str(ready_by_device[device_id])])
	_update_players_list()
	_update_start_button_state()


func _on_player_disconnected(device_id: String) -> void:
	print("Player disconnected: Device ID %s" % device_id)
	var player = PlayerManager.get_player_by_device_id(device_id)
	if player != null:
		print("Removing player: %s (Device ID: %s)" % [player.name, device_id])
		PlayerManager.remove_player(player.id)
		ready_by_device.erase(device_id)
		_update_players_list()
		_update_start_button_state()


func _update_players_list() -> void:
	if players_list.get_child_count() > 0:
		for child in players_list.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = p_badge.instantiate()
		players_list.add_child(badge_instance)
		badge_instance.setup(player)
		if not ready_by_device.get(player.device_id, false):
			badge_instance.modulate = Color(1.0, 1.0, 1.0, 0.65)

func _update_start_button_state() -> void:
	var enough_players = PlayerManager.players.size() >= 2
	var all_ready = true
	for player in PlayerManager.players:
		if not ready_by_device.get(player.device_id, false):
			all_ready = false
			break

	start_button.disabled = not enough_players or not all_ready

func _on_start_button_pressed() -> void:
	UISfx.play_ui_click()
	print("Start button pressed in lobby, emitting lobby_start_requested signal")
	if _setup_settings.is_empty():
		push_warning("Lobby settings are empty; cannot start game")
		return

	var settings = _setup_settings.duplicate(true)
	settings["players"] = PlayerManager.players
	settings["player_count"] = PlayerManager.players.size()

	lobby_start_requested.emit(settings)

	# Old direct GameManager.game usage kept here for reference during transition:
	# var settings = {
	# 	"players": PlayerManager.players,
	# 	"player_count": PlayerManager.players.size(),
	# 	"game_mode": GameManager.game.game_mode,
	# 	"game_type": GameManager.game.game_type,
	# 	"game_target": GameManager.game.game_target
	# }
	# lobby_start_requested.emit(settings)

func _on_home_button_pressed() -> void:
	UISfx.play_ui_click()
	print("Home button pressed in lobby, emitting lobby_back_to_home signal")
	lobby_back_to_home.emit()
	NetworkManager.stop_server() # Stop server if we're going back to home
	
func _on_return_to_setup_pressed() -> void:
	UISfx.play_ui_click()
	print("Back to setup button pressed in lobby, emitting lobby_back_to_setup signal")
	lobby_back_to_setup.emit()
	NetworkManager.stop_server() # Stop server if we're going back to setup
