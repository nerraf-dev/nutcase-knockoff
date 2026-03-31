extends RefCounted
class_name TitleAnimator

static func animate_title_in(host: Node, title: CanvasItem, style: String = "clean", options: Dictionary = {}) -> void:
	match style:
		"playful":
			await _animate_title_in_playful(host, title, options)
		"dramatic":
			await _animate_title_in_dramatic(host, title, options)
		_:
			await _animate_title_in_clean(host, title, options)


static func _optf(options: Dictionary, key: String, fallback: float) -> float:
	if options.has(key):
		return float(options[key])
	return fallback


static func _animate_title_in_clean(host: Node, title: CanvasItem, options: Dictionary) -> void:
	var delay: float = _optf(options, "delay", 0.15)
	var distance_x: float = _optf(options, "distance_x", 220.0)
	var duration: float = _optf(options, "duration", 0.55)
	var fade_duration: float = _optf(options, "fade_duration", 0.42)

	var end_pos: Vector2 = title.position
	title.position = end_pos + Vector2(-distance_x, 0.0)
	title.modulate.a = 0.0

	await host.get_tree().create_timer(delay).timeout

	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(title, "position", end_pos, duration)
	tween.tween_property(title, "modulate:a", 1.0, fade_duration)


static func _animate_title_in_playful(host: Node, title: CanvasItem, options: Dictionary) -> void:
	var delay: float = _optf(options, "delay", 0.18)
	var distance_x: float = _optf(options, "distance_x", 280.0)
	var distance_y: float = _optf(options, "distance_y", -10.0)
	var duration: float = _optf(options, "duration", 0.48)
	var fade_duration: float = _optf(options, "fade_duration", 0.35)
	var start_scale_factor: float = _optf(options, "start_scale", 0.92)
	var overshoot_x: float = _optf(options, "overshoot_x", 12.0)
	var overshoot_scale_factor: float = _optf(options, "overshoot_scale", 1.03)
	var settle_duration: float = _optf(options, "settle_duration", 0.12)

	var end_pos: Vector2 = title.position
	var end_scale: Vector2 = title.scale
	title.position = end_pos + Vector2(-distance_x, distance_y)
	title.scale = end_scale * start_scale_factor
	title.modulate.a = 0.0

	await host.get_tree().create_timer(delay).timeout

	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(title, "position", end_pos + Vector2(overshoot_x, 0.0), duration)
	tween.tween_property(title, "modulate:a", 1.0, fade_duration)
	tween.tween_property(title, "scale", end_scale * overshoot_scale_factor, duration)

	await tween.finished

	var settle := host.create_tween()
	settle.set_parallel(true)
	settle.set_trans(Tween.TRANS_QUAD)
	settle.set_ease(Tween.EASE_OUT)
	settle.tween_property(title, "position", end_pos, settle_duration)
	settle.tween_property(title, "scale", end_scale, settle_duration)


static func _animate_title_in_dramatic(host: Node, title: CanvasItem, options: Dictionary) -> void:
	var delay: float = _optf(options, "delay", 0.24)
	var distance_x: float = _optf(options, "distance_x", 520.0)
	var distance_y: float = _optf(options, "distance_y", 20.0)
	var start_rotation: float = _optf(options, "start_rotation", -6.0)
	var start_scale_factor: float = _optf(options, "start_scale", 0.84)
	var duration: float = _optf(options, "duration", 0.62)
	var fade_duration: float = _optf(options, "fade_duration", 0.40)
	var overshoot_x: float = _optf(options, "overshoot_x", 18.0)
	var overshoot_rotation: float = _optf(options, "overshoot_rotation", 0.8)
	var overshoot_scale_factor: float = _optf(options, "overshoot_scale", 1.04)
	var settle_duration: float = _optf(options, "settle_duration", 0.14)

	var end_pos: Vector2 = title.position
	var end_rotation: float = title.rotation_degrees
	var end_scale: Vector2 = title.scale
	title.position = end_pos + Vector2(-distance_x, distance_y)
	title.rotation_degrees = end_rotation + start_rotation
	title.scale = end_scale * start_scale_factor
	title.modulate.a = 0.0

	await host.get_tree().create_timer(delay).timeout

	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(title, "position", end_pos + Vector2(overshoot_x, 0.0), duration)
	tween.tween_property(title, "rotation_degrees", end_rotation + overshoot_rotation, duration)
	tween.tween_property(title, "scale", end_scale * overshoot_scale_factor, duration)
	tween.tween_property(title, "modulate:a", 1.0, fade_duration)

	await tween.finished

	var settle := host.create_tween()
	settle.set_parallel(true)
	settle.set_trans(Tween.TRANS_SINE)
	settle.set_ease(Tween.EASE_OUT)
	settle.tween_property(title, "position", end_pos, settle_duration)
	settle.tween_property(title, "rotation_degrees", end_rotation, settle_duration)
	settle.tween_property(title, "scale", end_scale, settle_duration)


static func animate_nodes_in(host: Node, nodes: Array, options: Dictionary = {}) -> void:
	var delay: float = _optf(options, "delay", 0.0)
	var stagger: float = _optf(options, "stagger", 0.07)
	var distance_x: float = _optf(options, "distance_x", 0.0)
	var distance_y: float = _optf(options, "distance_y", 20.0)
	var duration: float = _optf(options, "duration", 0.38)
	var fade_duration: float = _optf(options, "fade_duration", 0.30)
	var start_scale_factor: float = _optf(options, "start_scale", 0.96)

	var index := 0
	for node in nodes:
		if not (node is CanvasItem):
			continue

		var item: CanvasItem = node
		var end_pos: Vector2 = item.position
		var end_scale: Vector2 = item.scale
		item.position = end_pos + Vector2(distance_x, distance_y)
		item.scale = end_scale * start_scale_factor
		item.modulate.a = 0.0

		var node_delay := delay + (float(index) * stagger)
		var tween := host.create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "position", end_pos, duration).set_delay(node_delay)
		tween.parallel().tween_property(item, "modulate:a", 1.0, fade_duration).set_delay(node_delay)
		tween.parallel().tween_property(item, "scale", end_scale, duration).set_delay(node_delay)
		index += 1

	if index <= 0:
		return

	var longest_duration := maxf(duration, fade_duration)
	var total_wait := delay + (float(index - 1) * stagger) + longest_duration
	await host.get_tree().create_timer(total_wait).timeout


static func start_idle_motion(host: Node, node: CanvasItem, style: String = "wobble", options: Dictionary = {}) -> Tween:
	match style:
		"none":
			return null
		"jelly":
			return _start_idle_jelly(host, node, options)
		"floaty":
			return _start_idle_floaty(host, node, options)
		_:
			return _start_idle_wobble(host, node, options)


static func stop_idle_motion(idle_tween: Tween) -> void:
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()


static func _start_idle_wobble(host: Node, node: CanvasItem, options: Dictionary) -> Tween:
	var move_up: float = _optf(options, "move_up", 4.0)
	var move_down: float = _optf(options, "move_down", 3.0)
	var rot_left: float = _optf(options, "rot_left", 1.4)
	var rot_right: float = _optf(options, "rot_right", 1.2)
	var t1: float = _optf(options, "t1", 0.40)
	var t2: float = _optf(options, "t2", 0.40)
	var t3: float = _optf(options, "t3", 0.30)

	var base_y: float = node.position.y
	var base_rot: float = node.rotation_degrees

	var tween := host.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", base_y - move_up, t1)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot - rot_left, t1)
	tween.tween_property(node, "position:y", base_y + move_down, t2)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot + rot_right, t2)
	tween.tween_property(node, "position:y", base_y, t3)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot, t3)
	return tween


static func _start_idle_jelly(host: Node, node: CanvasItem, options: Dictionary) -> Tween:
	var sx1: float = _optf(options, "sx1", 1.03)
	var sy1: float = _optf(options, "sy1", 0.97)
	var sx2: float = _optf(options, "sx2", 0.98)
	var sy2: float = _optf(options, "sy2", 1.02)
	var rot_left: float = _optf(options, "rot_left", 0.8)
	var rot_right: float = _optf(options, "rot_right", 0.8)
	var t1: float = _optf(options, "t1", 0.22)
	var t2: float = _optf(options, "t2", 0.22)
	var t3: float = _optf(options, "t3", 0.26)
	var pause_time: float = _optf(options, "pause", 0.35)

	var base_scale: Vector2 = node.scale
	var base_rot: float = node.rotation_degrees

	var tween := host.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", base_scale * Vector2(sx1, sy1), t1)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot - rot_left, t1)
	tween.tween_property(node, "scale", base_scale * Vector2(sx2, sy2), t2)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot + rot_right, t2)
	tween.tween_property(node, "scale", base_scale, t3)
	tween.parallel().tween_property(node, "rotation_degrees", base_rot, t3)
	tween.tween_interval(pause_time)
	return tween


static func _start_idle_floaty(host: Node, node: CanvasItem, options: Dictionary) -> Tween:
	var move_up: float = _optf(options, "move_up", 7.0)
	var move_down: float = _optf(options, "move_down", 2.0)
	var t1: float = _optf(options, "t1", 1.05)
	var t2: float = _optf(options, "t2", 1.05)
	var t3: float = _optf(options, "t3", 0.70)

	var base_y: float = node.position.y

	var tween := host.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", base_y - move_up, t1)
	tween.tween_property(node, "position:y", base_y + move_down, t2)
	tween.tween_property(node, "position:y", base_y, t3)
	return tween
