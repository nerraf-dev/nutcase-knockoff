extends Node

# Global persisted user settings store.
#
# Owns:
# - loading/saving settings from user://settings.cfg
# - exposing current audio and internet preference values
# - notifying listeners whenever settings change
#
# Usage pattern:
# - read values directly from this autoload
# - update values through setter methods so changes are saved and broadcast

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

const KEY_UI_SFX_ENABLED := "ui_sfx_enabled"
const KEY_UI_SFX_VOLUME_DB := "ui_sfx_volume_db"
const KEY_MUSIC_ENABLED := "music_enabled"
const KEY_MUSIC_VOLUME_DB := "music_volume_db"
const KEY_MASTER_VOLUME_DB := "master_volume_db"
const KEY_INTERNET_ENABLED := "internet_enabled"
const LEGACY_KEY_NETWORK_ENABLED := "network_enabled"

var ui_sfx_enabled: bool = true
var ui_sfx_volume_db: float = 0.0
var music_enabled: bool = true
var music_volume_db: float = 0.0
var master_volume_db: float = 0.0
var internet_enabled: bool = true


func _ready() -> void:
	# Load persisted settings as soon as the autoload is ready.
	load_settings()


func load_settings() -> void:
	# Read saved settings, creating a default file on first launch.
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
	master_volume_db = float(cfg.get_value("audio", KEY_MASTER_VOLUME_DB, master_volume_db))
	internet_enabled = _load_internet_enabled(cfg)
	emit_settings_changed()


func save_settings() -> void:
	# Persist the current in-memory settings snapshot.
	var cfg = ConfigFile.new()
	cfg.set_value("audio", KEY_UI_SFX_ENABLED, ui_sfx_enabled)
	cfg.set_value("audio", KEY_UI_SFX_VOLUME_DB, ui_sfx_volume_db)
	cfg.set_value("audio", KEY_MUSIC_ENABLED, music_enabled)
	cfg.set_value("audio", KEY_MUSIC_VOLUME_DB, music_volume_db)
	cfg.set_value("audio", KEY_MASTER_VOLUME_DB, master_volume_db)
	cfg.set_value("internet", KEY_INTERNET_ENABLED, internet_enabled)
	var err = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed saving user settings to %s" % SAVE_PATH)


func set_ui_sfx_enabled(enabled: bool) -> void:
	# Setter helpers guard against redundant writes and always broadcast real changes.
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


func set_internet_enabled(enabled: bool) -> void:
	if internet_enabled == enabled:
		return
	internet_enabled = enabled
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


func set_master_volume_db(volume_db: float) -> void:
	if is_equal_approx(master_volume_db, volume_db):
		return
	master_volume_db = volume_db
	save_settings()
	emit_settings_changed()


func emit_settings_changed() -> void:
	# Central helper so load and setters use the same signal path.
	settings_changed.emit()


func _load_internet_enabled(cfg: ConfigFile) -> bool:
	# Preserve compatibility with the older network_enabled storage key.
	if cfg.has_section_key("internet", KEY_INTERNET_ENABLED):
		return bool(cfg.get_value("internet", KEY_INTERNET_ENABLED, internet_enabled))
	if cfg.has_section_key("network", LEGACY_KEY_NETWORK_ENABLED):
		return bool(cfg.get_value("network", LEGACY_KEY_NETWORK_ENABLED, internet_enabled))
	return internet_enabled