extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

const KEY_UI_SFX_ENABLED := "ui_sfx_enabled"
const KEY_UI_SFX_VOLUME_DB := "ui_sfx_volume_db"
const KEY_MUSIC_ENABLED := "music_enabled"
const KEY_MUSIC_VOLUME_DB := "music_volume_db"
const KEY_NETWORK_ENABLED := "network_enabled"

var ui_sfx_enabled: bool = true
var ui_sfx_volume_db: float = 0.0
var music_enabled: bool = true
var music_volume_db: float = 0.0
var network_enabled: bool = true


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		save_settings()
		emit_settings_changed()
		return

	ui_sfx_enabled = bool(cfg.get_value("audio", KEY_UI_SFX_ENABLED, ui_sfx_enabled))
	ui_sfx_volume_db = float(cfg.get_value("audio", KEY_UI_SFX_VOLUME_DB, ui_sfx_volume_db))
	music_enabled = bool(cfg.get_value("audio", KEY_MUSIC_ENABLED, music_enabled))
	music_volume_db = float(cfg.get_value("audio", KEY_MUSIC_VOLUME_DB, music_volume_db))
	network_enabled = bool(cfg.get_value("network", KEY_NETWORK_ENABLED, network_enabled))
	emit_settings_changed()


func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", KEY_UI_SFX_ENABLED, ui_sfx_enabled)
	cfg.set_value("audio", KEY_UI_SFX_VOLUME_DB, ui_sfx_volume_db)
	cfg.set_value("audio", KEY_MUSIC_ENABLED, music_enabled)
	cfg.set_value("audio", KEY_MUSIC_VOLUME_DB, music_volume_db)
	cfg.set_value("network", KEY_NETWORK_ENABLED, network_enabled)
	var err = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed saving user settings to %s" % SAVE_PATH)


func set_ui_sfx_enabled(enabled: bool) -> void:
	if ui_sfx_enabled == enabled:
		return
	ui_sfx_enabled = enabled
	save_settings()
	emit_settings_changed()


func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return
	music_enabled = enabled
	save_settings()
	emit_settings_changed()


func set_network_enabled(enabled: bool) -> void:
	if network_enabled == enabled:
		return
	network_enabled = enabled
	save_settings()
	emit_settings_changed()


func set_ui_sfx_volume_db(volume_db: float) -> void:
	if is_equal_approx(ui_sfx_volume_db, volume_db):
		return
	ui_sfx_volume_db = volume_db
	save_settings()
	emit_settings_changed()


func set_music_volume_db(volume_db: float) -> void:
	if is_equal_approx(music_volume_db, volume_db):
		return
	music_volume_db = volume_db
	save_settings()
	emit_settings_changed()


func emit_settings_changed() -> void:
	settings_changed.emit()