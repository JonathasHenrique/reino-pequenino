extends CanvasLayer

# StageTimeline.gd - Mapa de Linha do Tempo das Fases (Estilo Angry Birds / Kingdom Rush)
# Conecta os nós das fases com trilha tracejada, mostra estrelas (1-3), destaca a fase atual e bloqueia futuras.

signal stage_selected(stage_id: int)

const UI_FONT = preload("res://assets/fonts/Fredoka-Variable.ttf")

var current_world_tab: int = 1
var unlocked_stages: int = 1
var stage_stars: Dictionary = {}

var title_label: Label
var subtitle_label: Label
var world_tabs_box: HBoxContainer
var map_area: Control
var close_btn: Button
var play_current_btn: Button

var _node_positions: Array[Vector2] = []
var _pulse_time: float = 0.0
var _current_node_btn: Button = null

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	unlocked_stages = int(SaveManager.save_data.get("unlocked_stages", 1))
	stage_stars = SaveManager.save_data.get("stage_stars", {})
	current_world_tab = clampi(int((unlocked_stages - 1) / 10) + 1, 1, 6)
	_build_ui()
	I18n.language_changed.connect(func(_code: String): _refresh_texts())

func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	if is_instance_valid(_current_node_btn):
		var s := 1.0 + sin(_pulse_time) * 0.06
		_current_node_btn.scale = Vector2(s, s)

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.05, 0.07, 0.12, 0.82)
	add_child(dimmer)

	var panel := PanelContainer.new()
	panel.name = "MainPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(1060, 600)
	panel.offset_left = -530.0
	panel.offset_top = -300.0
	panel.offset_right = 530.0
	panel.offset_bottom = 300.0
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.14, 0.17, 0.25, 0.98)
	p_style.border_width_left = 4
	p_style.border_width_top = 4
	p_style.border_width_right = 4
	p_style.border_width_bottom = 4
	p_style.border_color = Color(0.95, 0.78, 0.25, 1.0)
	p_style.corner_radius_top_left = 24
	p_style.corner_radius_top_right = 24
	p_style.corner_radius_bottom_left = 24
	p_style.corner_radius_bottom_right = 24
	p_style.content_margin_left = 24
	p_style.content_margin_right = 24
	p_style.content_margin_top = 18
	p_style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", p_style)
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(root_vbox)

	# Cabeçalho
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_vbox)

	title_label = Label.new()
	title_label.add_theme_font_override("font", UI_FONT)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	title_vbox.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.add_theme_font_override("font", UI_FONT)
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.94))
	title_vbox.add_child(subtitle_label)

	close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.add_theme_font_override("font", UI_FONT)
	close_btn.add_theme_font_size_override("font_size", 18)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.45, 0.24, 0.18)
	close_style.corner_radius_top_left = 12
	close_style.corner_radius_top_right = 12
	close_style.corner_radius_bottom_left = 12
	close_style.corner_radius_bottom_right = 12
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(0.85, 0.55, 0.40)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	# Seletor de Mundos (1 a 6)
	world_tabs_box = HBoxContainer.new()
	world_tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	world_tabs_box.add_theme_constant_override("separation", 10)
	root_vbox.add_child(world_tabs_box)

	# Área do Mapa de Trilha
	var map_frame := PanelContainer.new()
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map_style := StyleBoxFlat.new()
	map_style.bg_color = Color(0.18, 0.32, 0.20, 1.0)
	map_style.corner_radius_top_left = 18
	map_style.corner_radius_top_right = 18
	map_style.corner_radius_bottom_left = 18
	map_style.corner_radius_bottom_right = 18
	map_style.border_width_left = 3
	map_style.border_width_top = 3
	map_style.border_width_right = 3
	map_style.border_width_bottom = 3
	map_style.border_color = Color(0.38, 0.58, 0.28, 1.0)
	map_frame.add_theme_stylebox_override("panel", map_style)
	root_vbox.add_child(map_frame)

	map_area = Control.new()
	map_area.name = "TrailCanvas"
	map_area.custom_minimum_size = Vector2(980, 360)
	map_area.draw.connect(_on_map_draw)
	map_frame.add_child(map_area)

	# Barra inferior com botão de ação rápida
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(footer)

	play_current_btn = Button.new()
	play_current_btn.custom_minimum_size = Vector2(320, 52)
	play_current_btn.add_theme_font_override("font", UI_FONT)
	play_current_btn.add_theme_font_size_override("font_size", 22)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.92, 0.68, 0.14)
	play_style.corner_radius_top_left = 16
	play_style.corner_radius_top_right = 16
	play_style.corner_radius_bottom_left = 16
	play_style.corner_radius_bottom_right = 16
	play_style.border_width_left = 3
	play_style.border_width_top = 3
	play_style.border_width_right = 3
	play_style.border_width_bottom = 3
	play_style.border_color = Color(1.0, 0.94, 0.65)
	play_current_btn.add_theme_stylebox_override("normal", play_style)
	play_current_btn.add_theme_color_override("font_color", Color(0.16, 0.10, 0.04))
	play_current_btn.pressed.connect(func(): _launch_stage(unlocked_stages))
	footer.add_child(play_current_btn)

	_refresh_texts()
	_rebuild_world_tabs()
	_rebuild_stage_nodes()

func _refresh_texts() -> void:
	if title_label:
		title_label.text = I18n.t_key("ui.timeline_title")
		I18n.protect(title_label)
	if subtitle_label:
		subtitle_label.text = I18n.t_key("ui.timeline_subtitle")
		I18n.protect(subtitle_label)
	if close_btn:
		close_btn.text = "X  " + I18n.t_key("ui.timeline_close")
		I18n.protect(close_btn)
	if play_current_btn:
		play_current_btn.text = "⚔ %s %d" % [I18n.t_key("ui.play"), unlocked_stages]
		I18n.protect(play_current_btn)
	_rebuild_world_tabs()
	_rebuild_stage_nodes()

func _rebuild_world_tabs() -> void:
	if world_tabs_box == null:
		return
	for c in world_tabs_box.get_children():
		c.queue_free()
	var max_world_unlocked := clampi(int((unlocked_stages - 1) / 10) + 1, 1, 6)
	for w in range(1, 7):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(145, 38)
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 16)
		var is_unlocked := w <= max_world_unlocked
		var is_active := w == current_world_tab
		btn.text = ("%s %d" if is_unlocked else "🔒 %s %d") % [I18n.t_key("ui.world"), w]
		I18n.protect(btn)
		var st := StyleBoxFlat.new()
		st.corner_radius_top_left = 10
		st.corner_radius_top_right = 10
		st.corner_radius_bottom_left = 10
		st.corner_radius_bottom_right = 10
		if is_active:
			st.bg_color = Color(0.28, 0.56, 0.88)
			st.border_width_bottom = 3
			st.border_color = Color(1.0, 0.86, 0.28)
		elif is_unlocked:
			st.bg_color = Color(0.22, 0.28, 0.38)
		else:
			st.bg_color = Color(0.16, 0.18, 0.22)
		btn.add_theme_stylebox_override("normal", st)
		var world_idx := w
		btn.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			current_world_tab = world_idx
			_rebuild_world_tabs()
			_rebuild_stage_nodes()
		)
		world_tabs_box.add_child(btn)

func _rebuild_stage_nodes() -> void:
	if map_area == null:
		return
	for c in map_area.get_children():
		c.queue_free()
	_node_positions.clear()
	_current_node_btn = null

	var start_stage := (current_world_tab - 1) * 10 + 1
	var width := 980.0
	var height := 360.0
	# 10 nós dispostos em uma trilha sinuosa estilo Angry Birds / Kingdom Rush
	var y_offsets := [0.68, 0.32, 0.24, 0.62, 0.76, 0.36, 0.22, 0.64, 0.72, 0.42]

	for i in range(10):
		var stg := start_stage + i
		var x := 68.0 + float(i) * ((width - 136.0) / 9.0)
		var y := height * float(y_offsets[i])
		var center := Vector2(x, y)
		_node_positions.append(center)

		var is_unlocked := stg <= unlocked_stages
		var is_current := stg == unlocked_stages
		var is_boss := (stg % 10 == 0)
		var stars := int(stage_stars.get(str(stg), 0))

		var holder := Control.new()
		holder.position = center
		map_area.add_child(holder)

		var node_size := Vector2(74, 74) if is_boss else (Vector2(68, 68) if is_current else Vector2(60, 60))
		var btn := Button.new()
		btn.custom_minimum_size = node_size
		btn.size = node_size
		btn.position = -node_size * 0.5
		btn.pivot_offset = node_size * 0.5
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 22 if is_current or is_boss else 19)

		var st := StyleBoxFlat.new()
		st.corner_radius_top_left = 38
		st.corner_radius_top_right = 38
		st.corner_radius_bottom_left = 38
		st.corner_radius_bottom_right = 38
		st.border_width_left = 4
		st.border_width_top = 4
		st.border_width_right = 4
		st.border_width_bottom = 4
		st.shadow_color = Color(0, 0, 0, 0.45)
		st.shadow_size = 6
		st.shadow_offset = Vector2(0, 3)

		if is_current:
			st.bg_color = Color(0.95, 0.68, 0.12)
			st.border_color = Color(1.0, 0.96, 0.72)
			btn.text = ("★\n%d" if is_boss else "%d") % stg
			btn.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
			_current_node_btn = btn
		elif is_unlocked:
			st.bg_color = Color(0.24, 0.56, 0.88) if not is_boss else Color(0.68, 0.28, 0.82)
			st.border_color = Color(0.85, 0.94, 1.0)
			btn.text = str(stg)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			st.bg_color = Color(0.28, 0.30, 0.35)
			st.border_color = Color(0.46, 0.48, 0.54)
			btn.text = "🔒\n%d" % stg
			btn.add_theme_font_size_override("font_size", 15)
			btn.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
			btn.disabled = true

		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		btn.add_theme_stylebox_override("disabled", st)
		I18n.protect(btn)

		if is_unlocked:
			var target_stage := stg
			btn.pressed.connect(func(): _launch_stage(target_stage))

		holder.add_child(btn)

		# Destaque de Coroa vetorial sobre a Fase Atual
		if is_current:
			var crown_badge := Control.new()
			crown_badge.set_script(load("res://scripts/ui/IconBadge.gd"))
			crown_badge.set("icon_type", "crown")
			crown_badge.custom_minimum_size = Vector2(36, 32)
			crown_badge.size = Vector2(36, 32)
			crown_badge.position = Vector2(-18, -node_size.y * 0.5 - 32)
			holder.add_child(crown_badge)

		# Exibição das 3 Estrelas abaixo de cada fase concluída/desbloqueada
		if is_unlocked:
			var stars_lbl := Label.new()
			var s_txt := ""
			for s_idx in range(3):
				s_txt += "★" if s_idx < stars else "☆"
			stars_lbl.text = s_txt
			stars_lbl.add_theme_font_override("font", UI_FONT)
			stars_lbl.add_theme_font_size_override("font_size", 18)
			stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22) if stars > 0 else Color(0.75, 0.80, 0.85))
			stars_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.04))
			stars_lbl.add_theme_constant_override("outline_size", 4)
			stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stars_lbl.custom_minimum_size = Vector2(76, 24)
			stars_lbl.position = Vector2(-38, node_size.y * 0.5 + 2)
			I18n.protect(stars_lbl)
			holder.add_child(stars_lbl)

	map_area.queue_redraw()

func _on_map_draw() -> void:
	if _node_positions.size() < 2:
		return
	var start_stage := (current_world_tab - 1) * 10 + 1
	# Desenha trilha tracejada conectando os nós
	for i in range(_node_positions.size() - 1):
		var a := _node_positions[i]
		var b := _node_positions[i + 1]
		var seg_unlocked := (start_stage + i + 1) <= unlocked_stages
		var col := Color(1.0, 0.86, 0.32, 0.95) if seg_unlocked else Color(0.62, 0.66, 0.72, 0.55)
		_draw_dashed_segment(a, b, col, 5.0, 12.0, 8.0)

func _draw_dashed_segment(from: Vector2, to: Vector2, color: Color, width: float, dash_len: float, gap_len: float) -> void:
	var total := from.distance_to(to)
	if total <= 0.001:
		return
	var dir := (to - from) / total
	var d := 0.0
	while d < total:
		var seg_end := minf(d + dash_len, total)
		var p1 := from + dir * d
		var p2 := from + dir * seg_end
		map_area.draw_line(p1, p2, Color(0.10, 0.08, 0.05, color.a * 0.7), width + 3.0, true)
		map_area.draw_line(p1, p2, color, width, true)
		d += dash_len + gap_len

func _launch_stage(stg: int) -> void:
	AudioManager.play_sfx("button_click")
	stage_selected.emit(stg)
	if stg % 10 == 0:
		MiniGameRunner.launch_challenge(stg)
	else:
		GameState.start_stage(stg)
		SceneTransition.change_scene("res://scenes/stages/StageMain.tscn")

func _on_close_pressed() -> void:
	AudioManager.play_sfx("button_click")
	queue_free()
