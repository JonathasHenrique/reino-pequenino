extends CanvasLayer

# TrophiesMenu.gd - Mural de Troféus e Conquistas do Reino

@onready var list_container: VBoxContainer = $Panel/VBox/Scroll/ListContainer
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			queue_free()
		)
	_populate_trophies()

func _populate_trophies() -> void:
	var path = "res://data/trophies/trophies.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	var unlocked_list: Array = SaveManager.save_data.get("trophies", [])
	
	for key in data.keys():
		var info = data[key]
		var is_unlocked = unlocked_list.has(key)
		
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		panel.add_child(hbox)
		
		var icon_lbl = Label.new()
		icon_lbl.text = info.get("icon", "🏆") if is_unlocked else "🔒"
		icon_lbl.add_theme_font_size_override("font_size", 32)
		hbox.add_child(icon_lbl)
		
		var vbox = VBoxContainer.new()
		hbox.add_child(vbox)
		
		var title_lbl = Label.new()
		var title_key := "trophies.%s_title" % key
		var translated_title = I18n.t_key(title_key)
		if translated_title == title_key:
			translated_title = I18n.tr_text(info.get("name", ""))
		title_lbl.text = translated_title
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.modulate = Color(1.0, 0.85, 0.25) if is_unlocked else Color(0.6, 0.6, 0.6)
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		var desc_key := "trophies.%s_desc" % key
		var translated_desc = I18n.t_key(desc_key)
		if translated_desc == desc_key:
			translated_desc = I18n.tr_text(info.get("description", ""))
		desc_lbl.text = translated_desc
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.modulate = Color(0.85, 0.85, 0.85) if is_unlocked else Color(0.45, 0.45, 0.45)
		vbox.add_child(desc_lbl)
		
		list_container.add_child(panel)

