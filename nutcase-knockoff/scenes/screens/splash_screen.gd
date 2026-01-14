extends Control

signal splash_complete

@onready var timer = $Timer

func _ready() -> void:
	print("SplashScreen scene ready")
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	print("SplashScreen timer started for %d seconds" % timer.wait_time)
	

func _on_timer_timeout() -> void:
	print("SplashScreen timer complete, emitting splash_complete signal")
	splash_complete.emit()
