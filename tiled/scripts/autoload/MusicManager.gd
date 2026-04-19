extends Node

const MENU_MUSIC_STREAM := preload("res://assets/sound/music/8bit Bossa.mp3")
const GAME_MUSIC_STREAM := preload("res://assets/sound/music/8bit Bossa.mp3")
const MASTER_BUS_NAME := "Master"
const MUSIC_BUS_NAME := "Music"
const SILENT_DB := -80.0
const LOOP_DELAY_SECONDS: float = 1.5

var _player: AudioStreamPlayer
var _active_track: String = ""
var _loop_timer: SceneTreeTimer = null


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = MUSIC_BUS_NAME
	_player.stream_paused = false
	_player.volume_db = 0.0
	add_child(_player)
	_apply_settings()
	if not UserSettings.settings_changed.is_connected(_on_settings_changed):
		UserSettings.settings_changed.connect(_on_settings_changed)
	_player.finished.connect(_on_track_finished)

	
func play_menu_music() -> void:
	_play_track("menu", MENU_MUSIC_STREAM)
	print("Playing menu music")


func play_game_music() -> void:
	_play_track("game", GAME_MUSIC_STREAM)


func stop_music() -> void:
	_active_track = ""
	if is_instance_valid(_player) and _player.playing:
		_player.stop()


func _on_track_finished() -> void:
	if _active_track == "":
		return
	_loop_timer = get_tree().create_timer(LOOP_DELAY_SECONDS)
	_loop_timer.timeout.connect(_restart_active_track)


func _exit_tree() -> void:
	if _loop_timer != null and _loop_timer.timeout.is_connected(_restart_active_track):
		_loop_timer.timeout.disconnect(_restart_active_track)
	_loop_timer = null
	_active_track = ""


func _restart_active_track() -> void:
	match _active_track:
		"menu": play_menu_music()
		"game": play_game_music()


func _play_track(track_key: String, stream: AudioStream) -> void:
	if not is_instance_valid(_player):
		return
	if stream == null:
		return

	var same_track = _active_track == track_key
	if same_track and _player.playing:
		_apply_settings()
		return

	_player.stream = stream
	_player.play()
	_active_track = track_key
	_apply_settings()


func _on_settings_changed() -> void:
	_apply_settings()


func _apply_settings() -> void:
	if not is_instance_valid(_player):
		return
	_apply_master_bus(UserSettings.master_volume_db)
	_apply_bus_settings(MUSIC_BUS_NAME, UserSettings.music_volume_db, UserSettings.music_enabled)
	_player.stream_paused = not UserSettings.music_enabled


func _apply_master_bus(volume_db: float) -> void:
	var bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	AudioServer.set_bus_mute(bus_index, volume_db <= SILENT_DB)


func _apply_bus_settings(bus_name: String, volume_db: float, enabled: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus '%s' not found; falling back to Master" % bus_name)
		bus_index = AudioServer.get_bus_index("Master")
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	AudioServer.set_bus_mute(bus_index, not enabled)