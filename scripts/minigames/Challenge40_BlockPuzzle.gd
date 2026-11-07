extends Node2D

# Challenge40_BlockPuzzle.gd - "Pula-Nuvens do Herói" (estilo Pou Sky Jump)
# O herói quica sozinho nas nuvens; a criança só guia para a esquerda/direita.

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")
const GRAVITY := 1500.0
const JUMP := 640.0
const SCROLL := 72.0

var hero_x: float = 640.0
var hero_y: float = 360.0
var vy: float = 0.0
var platforms: Array = []
var spawn_timer: float = 0.0
var next_id: int = 0
var landed_ids: Dictionary = {}
var hearts: int = 3
var passed: int = 0
var running: bool = true
var finished: bool = false
var overlay: Control = null

func _ready() -> void:
	var view := get_viewport_rect().size
	for i in range(6):
		platforms.append({"id": next_id, "x": randf_range(160.0, view.x - 160.0), "y": view.y - 100 - i * 130.0, "w": 210.0})
		next_id += 1
	hero_y = platforms[0]["y"] - 34.0
	vy = -JUMP
	queue_redraw()

func _process(delta: float) -> void:
	if not running:
		queue_redraw()
		return
	var view := get_viewport_rect().size
	var keyboard := Input.get_axis("ui_left", "ui_right")
	hero_x = clampf(hero_x + keyboard * 520.0 * delta, 60.0, view.x - 60.0)

	var prev_bottom := hero_y + 30.0
	vy += GRAVITY * delta
	hero_y += vy * delta

	for p in platforms:
		p["y"] += SCROLL * delta

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = 0.85
		var px := clampf(hero_x + randf_range(-220.0, 220.0), 140.0, view.x - 140.0)
		platforms.append({"id": next_id, "x": px, "y": -60.0, "w": 210.0})
		next_id += 1

	if vy > 0.0:
		for p in platforms:
			var top := float(p["y"])
			if prev_bottom <= top + 8.0 and hero_y + 30.0 >= top and absf(hero_x - float(p["x"])) < float(p["w"]) * 0.5:
				hero_y = top - 30.0
				vy = -JUMP
				if not landed_ids.has(int(p["id"])):
					landed_ids[int(p["id"])] = true
					passed += 1
				break

	platforms = platforms.filter(func(p): return float(p["y"]) < view.y + 120.0)

	if hero_y > view.y + 80.0:
		hearts -= 1
		if hearts <= 0:
			_finish(false)
		else:
			hero_x = view.x * 0.5
			hero_y = 280.0
			vy = 0.0
			platforms.append({"id": next_id, "x": hero_x, "y": 330.0, "w": 240.0})
			next_id += 1

	if passed >= 12:
		_finish(true)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var view := get_viewport_rect().size
	if event is InputEventScreenTouch and event.pressed:
		hero_x = clampf(lerpf(hero_x, event.position.x, 0.45), 60.0, view.x - 60.0)
	elif event is InputEventScreenDrag:
		hero_x = clampf(lerpf(hero_x, event.position.x, 0.45), 60.0, view.x - 60.0)
	elif event is InputEventMouseButton and event.pressed:
		hero_x = clampf(lerpf(hero_x, event.position.x, 0.45), 60.0, view.x - 60.0)

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.62, 0.86, 1.0))
	for p in platforms:
		var r := Rect2(Vector2(float(p["x"]) - float(p["w"]) * 0.5, float(p["y"])), Vector2(float(p["w"]), 46))
		draw_rect(r, Color(1, 1, 1))
		draw_circle(Vector2(r.position.x + 24, r.position.y + 24), 32.0, Color(1, 1, 1))
		draw_circle(Vector2(r.end.x - 24, r.position.y + 20), 28.0, Color(1, 1, 1))
		var shade := Rect2(r.position + Vector2(0, 34), Vector2(r.size.x, 12))
		draw_rect(shade, Color(0.86, 0.93, 1.0))
	var hp := Vector2(hero_x, hero_y)
	draw_circle(hp + Vector2(0, -12), 34.0, Color(0.98, 0.82, 0.64))
	draw_rect(Rect2(hp + Vector2(-30, 14), Vector2(60, 34)), Color(0.25, 0.5, 0.88))
	draw_circle(hp + Vector2(-12, -18), 8.0, Color.WHITE)
	draw_circle(hp + Vector2(12, -18), 8.0, Color.WHITE)
	draw_circle(hp + Vector2(-11, -17), 4.0, Color(0.1, 0.07, 0.06))
	draw_circle(hp + Vector2(13, -17), 4.0, Color(0.1, 0.07, 0.06))
	draw_arc(hp + Vector2(0, 0), 12.0, 0.35, PI - 0.35, 12, Color(0.35, 0.12, 0.1), 3.0)
	for i in range(hearts):
		draw_circle(Vector2(view.x - 60 - i * 46, 50), 16.0, Color(0.95, 0.25, 0.3))
	draw_string(UI_FONT, Vector2(40, 60), "Nuvens: %d/12" % mini(passed, 12), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.15, 0.25, 0.45))

func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	running = false
	if won:
		MiniGameRunner.complete_challenge(40, {"won": true, "stars": 3})
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.5)
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
		get_tree().reload_current_scene()
