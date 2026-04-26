extends Node

const MENU_MUSIC_STREAM := preload("res://assets/sound/music/8bit Bossa.mp3")
const GAME_MUSIC_STREAM := [
	preload("res://assets/sound/music/game/regrowth wip.wav"),
	preload("res://assets/sound/music/game/shop.wav"),
	preload("res://assets/sound/music/game/boss battle.wav"),
]
const VOTE_MUSIC_STREAM := preload("res://assets/sound/music/8Bit Adventure Loop.ogg")

const MASTER_BUS_NAME := "Master"
const MUSIC_BUS_NAME := "Music"
const SILENT_DB := -80.0
const LOOP_DELAY_SECONDS: float = 1.5
const DEFAULT_FADE_SECONDS: float = 0.5

var _player: AudioStreamPlayer
var _active_track: String = ""
var _loop_timer: SceneTreeTimer = null
var _fade_tween: Tween = null


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
	# _play_track("menu", MENU_MUSIC_STREAM)
	_switch_track_with_fade("menu", MENU_MUSIC_STREAM)
	print("Playing menu music")


func play_game_music() -> void:
	# _play_track("game", GAME_MUSIC_STREAM)
	var random_index = randi() % GAME_MUSIC_STREAM.size()
	_switch_track_with_fade("game", GAME_MUSIC_STREAM[random_index])
	print("Playing game music")

func play_vote_music() -> void:
	# _play_track("vote", VOTE_MUSIC_STREAM)
	_switch_track_with_fade("vote", VOTE_MUSIC_STREAM)
	print("Playing vote music")

func stop_music() -> void:
	_stop_loop_timer()
	_kill_fade_tween()
	_active_track = ""
	if is_instance_valid(_player) and _player.playing:
		_player.stop()
		_player.volume_db = 0.0


func _on_track_finished() -> void:
	if _active_track == "":
		return
	_stop_loop_timer()
	_loop_timer = get_tree().create_timer(LOOP_DELAY_SECONDS)
	_loop_timer.timeout.connect(_restart_active_track)


func _exit_tree() -> void:
	_stop_loop_timer()
	_kill_fade_tween()
	_loop_timer = null
	_active_track = ""


func _restart_active_track() -> void:
	match _active_track:
		"menu": play_menu_music()
		"game": play_game_music()
		"vote": play_vote_music()


func _play_track(track_key: String, stream: AudioStream) -> void:
	if not is_instance_valid(_player):
		return
	if stream == null:
		return
	_stop_loop_timer()
	_kill_fade_tween()

	var same_track = _active_track == track_key
	if same_track and _player.playing:
		_apply_settings()
		return

	_player.stream = stream
	_player.play()
	_active_track = track_key
	_apply_settings()
	_player.volume_db = 0.0


func _fade_in_track(track_key: String, stream: AudioStream, fade_time: float = DEFAULT_FADE_SECONDS) -> void:
	if not is_instance_valid(_player):
		return
	if stream == null:
		return
	_stop_loop_timer()
	_kill_fade_tween()

	_player.stream = stream
	_player.volume_db = SILENT_DB
	_player.play()
	_active_track = track_key
	_apply_settings()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", 0.0, max(fade_time, 0.01)) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN)


func _fade_out_track(fade_time: float = DEFAULT_FADE_SECONDS) -> void:
	if not is_instance_valid(_player):
		return
	if not _player.playing:
		return
	_stop_loop_timer()
	_kill_fade_tween()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", SILENT_DB, max(fade_time, 0.01)) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(Callable(self , "_finish_fade_out"))


func _switch_track_with_fade(track_key: String, stream: AudioStream, fade_out_time: float = DEFAULT_FADE_SECONDS, fade_in_time: float = DEFAULT_FADE_SECONDS) -> void:
	if not is_instance_valid(_player):
		return
	if stream == null:
		return

	var same_track := _active_track == track_key
	if same_track and _player.playing:
		_apply_settings()
		return

	_stop_loop_timer()
	_kill_fade_tween()

	if not _player.playing:
		_fade_in_track(track_key, stream, fade_in_time)
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", SILENT_DB, max(fade_out_time, 0.01)) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(Callable(self , "_play_track_after_fade_out").bind(track_key, stream, fade_in_time))


func _play_track_after_fade_out(track_key: String, stream: AudioStream, fade_in_time: float) -> void:
	if not is_instance_valid(_player):
		return
	_player.stop()
	_player.volume_db = 0.0
	_fade_in_track(track_key, stream, fade_in_time)


func _finish_fade_out() -> void:
	if not is_instance_valid(_player):
		return
	_player.stop()
	_player.volume_db = 0.0


func _stop_loop_timer() -> void:
	if _loop_timer == null:
		return
	if _loop_timer.timeout.is_connected(_restart_active_track):
		_loop_timer.timeout.disconnect(_restart_active_track)
	_loop_timer = null


func _kill_fade_tween() -> void:
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = null


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