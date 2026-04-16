extends Node2D

signal start_game
signal open_options
signal exit_game

@onready var start_game_btn = $StartGame
@onready var options_btn = $Options
@onready var credits_btn = $Credits
@onready var exit_btn = $Exit
@onready var accept_dialog = $AcceptDialog
@onready var credits_dialog = $CreditsPopup

const CLICK_LEAD_IN_SECONDS: float = 0.05
const TITLE_ANIMATION_STYLE: String = "dramatic" # clean | playful | dramatic
const TITLE_IDLE_STYLE: String = "floaty" # none | wobble | jelly | floaty
const TitleAnimatorScript := preload("res://scripts/utils/title_animator.gd")
const TITLE_ANIMATION_OVERRIDES: Dictionary = {
	# Shared tuning keys: delay, distance_x, distance_y, duration, fade_duration.
	# Style-specific keys are also supported (for example overshoot_x, settle_duration).
	"delay": 0.30,
	"duration": 0.68,
	"fade_duration": 0.45,
}
const UI_REVEAL_OVERRIDES: Dictionary = {
	"delay": 0.08,
	"stagger": 0.07,
	"distance_y": 26.0,
	"duration": 0.34,
	"fade_duration": 0.26,
	"start_scale": 0.95,
}
const TITLE_IDLE_OVERRIDES: Dictionary = {}
var _start_requested: bool = false
var _title_idle_tween: Tween
var _home_disabled_states: Dictionary = {} # node path -> previous disabled state
var _exit_dialog_open: bool = false


func _ready() -> void:
	print("GameHome scene ready")
	_prepare_intro_visual_state()
	
	credits_dialog.visible = false
	start_game_btn.pressed.connect(_on_start_game_btn_pressed)
	options_btn.pressed.connect(_on_options_btn_pressed)
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	accept_dialog.confirmed.connect(_on_AcceptDialog_confirmed)
	accept_dialog.visibility_changed.connect(_on_accept_dialog_visibility_changed)
	if accept_dialog.has_signal("canceled"):
		accept_dialog.canceled.connect(_on_accept_dialog_closed)
	if accept_dialog.has_signal("close_requested"):
		accept_dialog.close_requested.connect(_on_accept_dialog_closed)
	credits_btn.pressed.connect(_on_credits_btn_pressed)

	start_game_btn.focus_mode = Control.FOCUS_ALL
	options_btn.focus_mode = Control.FOCUS_ALL
	options_btn.disabled = false
	exit_btn.focus_mode = Control.FOCUS_ALL

	await _animate_title_in()
	await _animate_home_controls_in()
	_title_idle_tween = TitleAnimatorScript.start_idle_motion(
		self ,
		$Title,
		TITLE_IDLE_STYLE,
		TITLE_IDLE_OVERRIDES
	)
	start_game_btn.grab_focus()

func _animate_title_in() -> void:
	await TitleAnimatorScript.animate_title_in(self , $Title, TITLE_ANIMATION_STYLE, TITLE_ANIMATION_OVERRIDES)


func _animate_home_controls_in() -> void:
	await TitleAnimatorScript.animate_nodes_in(
		self ,
		[start_game_btn, options_btn, credits_btn, exit_btn],
		UI_REVEAL_OVERRIDES
	)


func _prepare_intro_visual_state() -> void:
	$Title.modulate.a = 0.0
	for node in [start_game_btn, options_btn, credits_btn, exit_btn]:
		node.modulate.a = 0.0


func _exit_tree() -> void:
	TitleAnimatorScript.stop_idle_motion(_title_idle_tween)
	

func _play_click_sound() -> void:
	UISfx.play_ui_click()

func _on_start_game_btn_pressed() -> void:
	if _start_requested:
		return
	_start_requested = true
	start_game_btn.disabled = true
	_play_click_sound()
	# Small lead-in prevents scene transition from cutting off the click.
	await get_tree().create_timer(CLICK_LEAD_IN_SECONDS).timeout
	print("Start Game button pressed, emitting start_game signal")
	start_game.emit()

func _on_options_btn_pressed() -> void:
	_play_click_sound()
	open_options.emit()

func _on_exit_btn_pressed() -> void:
	if _exit_dialog_open:
		return
	_exit_dialog_open = true
	_play_click_sound()
	_set_home_controls_enabled(false)
	accept_dialog.popup_centered()
	await get_tree().process_frame # Wait one frame
	if is_instance_valid(accept_dialog):
		var ok_button = accept_dialog.get_ok_button()
		if is_instance_valid(ok_button):
			ok_button.grab_focus() # Focus the OK button

func _set_home_controls_enabled(enabled: bool) -> void:
	for node in [start_game_btn, options_btn, credits_btn, exit_btn]:
		var button := node as BaseButton
		if button == null:
			continue
		var key = button.get_path()
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if enabled:
			if _home_disabled_states.has(key):
				button.disabled = _home_disabled_states[key]
				_home_disabled_states.erase(key)
		else:
			if not _home_disabled_states.has(key):
				_home_disabled_states[key] = button.disabled
			button.disabled = true

func _on_accept_dialog_visibility_changed() -> void:
	if _exit_dialog_open and not accept_dialog.visible:
		_exit_dialog_open = false
		_set_home_controls_enabled(true)

func _on_accept_dialog_closed() -> void:
	# Explicitly hide then let visibility_changed restore controls.
	if accept_dialog.visible:
		accept_dialog.hide()

func _on_AcceptDialog_confirmed() -> void:
	_exit_dialog_open = false
	_set_home_controls_enabled(true)
	_play_click_sound()
	if not NetworkManager.is_local:
		NetworkManager.stop_server()
	print("Exit button pressed, quitting application")
	exit_game.emit()

func _on_credits_btn_pressed() -> void:
	_play_click_sound()
	print("Credits button pressed, showing credits dialog")
	credits_dialog.popup_centered()
