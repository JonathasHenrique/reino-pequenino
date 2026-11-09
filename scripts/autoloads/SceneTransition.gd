extends CanvasLayer

# SceneTransition.gd - Cortina de Bruma / Fade suave estilo Clash of Clans entre Prólogo, Vila e Fases.

var _rect: ColorRect
var _mist_left: Panel
var _mist_right: Panel
var _busy: bool = false

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.08, 0.12, 0.22, 1.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_rect.visible = false
	add_child(_rect)

	var mist_style := StyleBoxFlat.new()
	mist_style.bg_color = Color(0.76, 0.84, 0.96, 0.92)
	mist_style.set_corner_radius_all(36)

	_mist_left = Panel.new()
	_mist_left.add_theme_stylebox_override("panel", mist_style)
	_mist_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mist_left.visible = false
	add_child(_mist_left)

	_mist_right = Panel.new()
	_mist_right.add_theme_stylebox_override("panel", mist_style)
	_mist_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mist_right.visible = false
	add_child(_mist_right)

func change_scene(path: String, fade_in: float = 0.42, fade_out: float = 0.50) -> void:
	if _busy:
		return
	_busy = true
	var view := get_viewport().get_visible_rect().size
	var half_w := view.x * 0.58
	_mist_left.size = Vector2(half_w, view.y + 40.0)
	_mist_right.size = Vector2(half_w, view.y + 40.0)
	_mist_left.position = Vector2(-half_w, -20.0)
	_mist_right.position = Vector2(view.x, -20.0)
	_mist_left.visible = true
	_mist_right.visible = true
	_rect.visible = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_rect, "modulate:a", 1.0, fade_in)
	tw.tween_property(_mist_left, "position:x", -20.0, fade_in).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mist_right, "position:x", view.x - half_w + 20.0, fade_in).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(_rect, "modulate:a", 0.0, fade_out)
	tw2.tween_property(_mist_left, "position:x", -half_w, fade_out).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw2.tween_property(_mist_right, "position:x", view.x, fade_out).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw2.finished

	_rect.visible = false
	_mist_left.visible = false
	_mist_right.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
