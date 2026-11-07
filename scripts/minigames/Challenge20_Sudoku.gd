extends Node2D

# Challenge20_Sudoku.gd - "Chuva de Tesouros do Herói" (estilo Pou Food Drop)
# A criança move o herói para pegar moedas/poções e desviar de bombas lentas.

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")

var hero_x: float = 640.0
var target_x: float = 640.0
var hero_y: float = 600.0
var score: int = 0
var hearts: int = 3
var items: Array = []
var spawn_timer: float = 0.0
var elapsed: float = 0.0
var running: bool = true
var finished: bool = false
var overlay: Control = null

func _ready() -> void:
	running = true
	queue_redraw()

func _process(delta: float) -> void:
	if not running:
		queue_redraw()
		return
	elapsed += delta
	var view := get_viewport_rect().size
	hero_x = lerpf(hero_x, target_x, 10.0 * delta)
	var keyboard := Input.get_axis("ui_left", "ui_right")
	if absf(keyboard) > 0.01:
		target_x = clampf(target_x + keyboard * 620.0 * delta, 70.0, view.x - 70.0)
	hero_x = clampf(hero_x, 70.0, view.x - 70.0)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.55, 0.95)
		var kind := "coin"
		var roll := randf()
		if roll > 0.82:
			kind = "bomb"
		elif roll > 0.70:
			kind = "potion"
		elif roll > 0.58:
			kind = "food"
		items.append({"kind": kind, "x": randf_range(80.0, view.x - 80.0), "y": -40.0, "speed": randf_range(150.0, 210.0)})

	for item in items:
		item["y"] += float(item["speed"]) * delta
		if absf(float(item["x"]) - hero_x) < 46.0 and float(item["y"]) > hero_y - 60.0 and float(item["y"]) < hero_y + 40.0:
			item["y"] = 9999.0
			match str(item["kind"]):
				"coin":
					score += 1
					AudioManager.play_sfx("coin_pickup")
				"potion":
					score += 2
					hearts = mini(3, hearts + 1)
					AudioManager.play_sfx("coin_pickup")
				"food":
					score += 1
					AudioManager.play_sfx("coin_pickup")
				"bomb":
					hearts -= 1
					AudioManager.play_sfx("hit")
	items = items.filter(func(it): return float(it["y"]) < view.y + 60.0)

	if score >= 12:
		_finish(true)
	elif hearts <= 0:
		_finish(false)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		target_x = event.position.x
	elif event is InputEventScreenDrag:
		target_x = event.position.x
	elif event is InputEventMouseButton and event.pressed:
		target_x = event.position.x

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.45, 0.78, 1.0))
	draw_rect(Rect2(Vector2(0, view.y - 120), Vector2(view.x, 120)), Color(0.36, 0.66, 0.24))
	for item in items:
		var p := Vector2(float(item["x"]), float(item["y"]))
		match str(item["kind"]):
			"coin":
				draw_circle(p, 24.0, Color(1.0, 0.78, 0.2))
				draw_circle(p, 16.0, Color(1.0, 0.92, 0.45))
			"potion":
				draw_circle(p, 22.0, Color(0.35, 0.85, 0.45))
				draw_rect(Rect2(p + Vector2(-7, -30), Vector2(14, 12)), Color(0.75, 0.55, 0.3))
			"food":
				draw_circle(p, 22.0, Color(0.9, 0.35, 0.3))
				draw_circle(p + Vector2(0, -6), 18.0, Color(1.0, 0.6, 0.35))
			"bomb":
				draw_circle(p, 24.0, Color(0.18, 0.18, 0.22))
				draw_circle(p + Vector2(8, -20), 6.0, Color(1.0, 0.6, 0.2))
	# herói com rosto
	var hp := Vector2(hero_x, hero_y)
	draw_circle(hp + Vector2(0, -10), 42.0, Color(0.98, 0.82, 0.64))
	draw_rect(Rect2(hp + Vector2(-38, 22), Vector2(76, 44)), Color(0.25, 0.5, 0.88))
	draw_circle(hp + Vector2(-15, -18), 9.0, Color.WHITE)
	draw_circle(hp + Vector2(15, -18), 9.0, Color.WHITE)
	draw_circle(hp + Vector2(-14, -16), 4.5, Color(0.1, 0.07, 0.06))
	draw_circle(hp + Vector2(16, -16), 4.5, Color(0.1, 0.07, 0.06))
	draw_arc(hp + Vector2(0, 2), 14.0, 0.35, PI - 0.35, 12, Color(0.35, 0.12, 0.1), 3.0)
	draw_string(UI_FONT, Vector2(40, 60), "Tesouros: %d/12" % mini(score, 12), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.12, 0.22, 0.45))
	# corações
	for i in range(hearts):
		draw_circle(Vector2(view.x - 60 - i * 46, 50), 16.0, Color(0.95, 0.25, 0.3))

func _draw_text_center(text: String, y: float, size_px: int, color: Color) -> void:
	var font := UI_FONT
	var width := get_viewport_rect().size.x
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, color)

func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	running = false
	if won:
		MiniGameRunner.complete_challenge(20, {"won": true, "stars": 3})
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.55)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(panel)
	var label := Label.new()
	label.text = "Você venceu!" if won else "Tente de novo!"
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05))
	label.add_theme_constant_override("outline_size", 12)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-180, -140)
	overlay.add_child(label)
	var btn := Button.new()
	btn.text = "Ir para a Vila" if won else "Jogar de novo"
	btn.add_theme_font_override("font", UI_FONT)
	btn.add_theme_font_size_override("font_size", 34)
	btn.set_anchors_preset(Control.PRESET_CENTER)
	btn.position = Vector2(-120, 20)
	btn.custom_minimum_size = Vector2(240, 70)
	btn.pressed.connect(_on_overlay_button.bind(won))
	overlay.add_child(btn)

func _on_overlay_button(won: bool) -> void:
	if won:
		get_tree().change_scene_to_file("res://scenes/village/Village.tscn")
	else:
		score = 0
		hearts = 3
		items.clear()
		spawn_timer = 0.0
		finished = false
		running = true
		if overlay:
			overlay.queue_free()
			overlay = null
