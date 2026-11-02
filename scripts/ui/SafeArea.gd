extends RefCounted

static func horizontal_insets(control: Control) -> Vector2:
	var window_size := DisplayServer.window_get_size()
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0 or safe_rect.size.x <= 0:
		return Vector2.ZERO

	var viewport_size := control.get_viewport().get_visible_rect().size
	var scale_x := viewport_size.x / float(window_size.x)
	var left := maxf(0.0, float(safe_rect.position.x) * scale_x)
	var right := maxf(0.0, float(window_size.x - safe_rect.end.x) * scale_x)
	return Vector2(left, right)

static func apply_horizontal(control: Control, base_left: float, base_right: float) -> void:
	var insets := horizontal_insets(control)
	control.offset_left = base_left + insets.x
	control.offset_right = -(base_right + insets.y)