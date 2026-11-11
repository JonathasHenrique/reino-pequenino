extends CanvasLayer

# TrophiesMenu.gd - Mural de Troféus e Conquistas do Reino
# Executa verificação retroativa ao abrir e destaca troféus conquistados em dourado.

@onready var list_container: VBoxContainer = $Panel/VBox/Scroll/ListContainer
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			queue_free()
		)
	SaveManager.check_and_unlock_achievements(true)
	_populate_trophies()

func _make_card_style(is_unlocked: bool) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	if is_unlocked:
		st.bg_color = Color(0.30, 0.21, 0.06, 0.96)
		st.border_color = Color(1.0, 0.84, 0.22, 1.0)
		st.set_border_width_all(3)
	else:
		st.bg_color = Color(0.15, 0.15, 0.18, 0.92)
		st.border_color = Color(0.32, 0.34, 0.38, 0.85)
		st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.content_margin_left = 16.0
	st.content_margin_right = 16.0
	st.content_margin_top = 10.0
	st.content_margin_bottom = 10.0
	return st

func _populate_trophies() -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

	var path = "res://data/trophies/trophies.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	var unlocked_list: Array = SaveManager.save_data.get("trophies", [])
	var ordered_keys := [
		"first_victory",
		"catapult_master",
		"sudoku_wizard",
		"shield_hero",
		"village_architect",
		"full_crown"
	]
	
	for key in ordered_keys:
		if not data.has(key):
			continue
		var info = data[key]
		var is_unlocked: bool = unlocked_list.has(key)
		
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _make_card_style(is_unlocked))
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		panel.add_child(hbox)
		
		var icon_lbl = Label.new()
		icon_lbl.text = "🏆" if is_unlocked else "🔒"
		icon_lbl.add_theme_font_size_override("font_size", 36)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.modulate = Color(1.0, 0.88, 0.22) if is_unlocked else Color(0.55, 0.58, 0.62)
		I18n.protect(icon_lbl)
		hbox.add_child(icon_lbl)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 3)
		hbox.add_child(vbox)
		
		var title_lbl = Label.new()
		var title_key := "trophies.%s_title" % key
		var translated_title = I18n.t_key(title_key)
		if translated_title == title_key:
			translated_title = I18n.tr_text(info.get("name", ""))
		title_lbl.text = translated_title
		title_lbl.add_theme_font_size_override("font_size", 19)
		title_lbl.modulate = Color(1.0, 0.90, 0.28) if is_unlocked else Color(0.68, 0.70, 0.74)
		I18n.protect(title_lbl)
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		var desc_key := "trophies.%s_desc" % key
		var translated_desc = I18n.t_key(desc_key)
		if translated_desc == desc_key:
			translated_desc = I18n.tr_text(info.get("description", ""))
		desc_lbl.text = translated_desc
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.modulate = Color(0.96, 0.92, 0.82) if is_unlocked else Color(0.52, 0.54, 0.58)
		I18n.protect(desc_lbl)
		vbox.add_child(desc_lbl)

		var status_lbl = Label.new()
		if is_unlocked:
			status_lbl.text = "🏆 OK"
			status_lbl.modulate = Color(1.0, 0.88, 0.25)
		else:
			status_lbl.text = "🔒"
			status_lbl.modulate = Color(0.50, 0.52, 0.56)
		status_lbl.add_theme_font_size_override("font_size", 16)
		status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		I18n.protect(status_lbl)
		hbox.add_child(status_lbl)
		
		list_container.add_child(panel)
