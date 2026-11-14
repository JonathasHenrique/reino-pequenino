extends CanvasLayer

# StickerAlbum.gd - Álbum de Figurinhas Colecionável da Coroa
# Exibe as 6 ilustrações reais (sticker_1.jpeg a sticker_6.jpeg) conforme o progresso.

@onready var grid_container: GridContainer = find_child("GridContainer", true, false) as GridContainer
@onready var back_button: Button = find_child("BackButton", true, false) as Button

const STICKER_IMAGES := {
	"star_1": "res://assets/ui/illustrations/sticker_1.jpeg",
	"star_2": "res://assets/ui/illustrations/sticker_2.jpeg",
	"star_3": "res://assets/ui/illustrations/sticker_3.jpeg",
	"star_4": "res://assets/ui/illustrations/sticker_4.jpeg",
	"star_5": "res://assets/ui/illustrations/sticker_5.jpeg",
	"star_6": "res://assets/ui/illustrations/sticker_6.jpeg"
}

const STICKER_TITLES := {
	"star_1": {"pt_BR": "Estrela do Vale", "en": "Valley Star", "es": "Estrella del Valle"},
	"star_2": {"pt_BR": "Estrela dos Cogumelos", "en": "Mushroom Star", "es": "Estrella de los Hongos"},
	"star_3": {"pt_BR": "Estrela do Mel", "en": "Honey Star", "es": "Estrella de la Miel"},
	"star_4": {"pt_BR": "Estrela dos Espelhos", "en": "Mirror Star", "es": "Estrella de los Espejos"},
	"star_5": {"pt_BR": "Estrela do Inverno", "en": "Winter Star", "es": "Estrella del Invierno"},
	"star_6": {"pt_BR": "Estrela da Festa", "en": "Feast Star", "es": "Estrella de la Fiesta"}
}

const RARITY_TRANSLATIONS := {
	"Rara": {"pt_BR": "⭐ Rara", "en": "⭐ Rare", "es": "⭐ Rara"},
	"Épica": {"pt_BR": "⭐ Épica", "en": "⭐ Epic", "es": "⭐ Épica"},
	"Lendária": {"pt_BR": "⭐ Lendária", "en": "⭐ Legendary", "es": "⭐ Legendaria"}
}

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			queue_free()
		)
	SaveManager.check_and_unlock_achievements(false)
	_populate_stickers()

func _load_sticker_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res_tex := ResourceLoader.load(path) as Texture2D
		if res_tex:
			return res_tex
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if FileAccess.file_exists(path):
		var img2 := Image.load_from_file(path)
		if img2 and not img2.is_empty():
			return ImageTexture.create_from_image(img2)
	return null

func _make_card_style(is_unlocked: bool) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	if is_unlocked:
		st.bg_color = Color(0.20, 0.16, 0.08, 0.96)
		st.border_color = Color(1.0, 0.84, 0.22, 1.0)
		st.set_border_width_all(3)
	else:
		st.bg_color = Color(0.13, 0.15, 0.20, 0.94)
		st.border_color = Color(0.32, 0.38, 0.48, 0.85)
		st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 10.0
	st.content_margin_bottom = 10.0
	return st

func _get_unlock_condition(world_idx: int) -> String:
	var lang := I18n.language
	if lang == "en":
		return "🔒 Complete World %d" % world_idx
	if lang == "es":
		return "🔒 Completa el Mundo %d" % world_idx
	return "🔒 Vença o Mundo %d" % world_idx

func _populate_stickers() -> void:
	if not grid_container:
		return
	for child in grid_container.get_children():
		child.queue_free()

	var path = "res://data/stickers/stickers.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	var unlocked_stickers: Array = SaveManager.save_data.get("stickers", [])
	var lang := I18n.language
	var ordered_keys := ["star_1", "star_2", "star_3", "star_4", "star_5", "star_6"]
	
	for i in range(ordered_keys.size()):
		var key: String = ordered_keys[i]
		if not data.has(key):
			continue
		var info = data[key]
		var world_idx: int = i + 1
		var is_unlocked: bool = unlocked_stickers.has(key)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(228, 194)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card.add_theme_stylebox_override("panel", _make_card_style(is_unlocked))
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 5)
		card.add_child(vbox)
		
		if is_unlocked:
			var img_path: String = str(STICKER_IMAGES.get(key, ""))
			var tex: Texture2D = _load_sticker_texture(img_path)
			if tex:
				var img_center := CenterContainer.new()
				img_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var tex_rect := TextureRect.new()
				tex_rect.texture = tex
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect.custom_minimum_size = Vector2(176, 114)
				tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				img_center.add_child(tex_rect)
				vbox.add_child(img_center)
			else:
				var icon_lbl = Label.new()
				icon_lbl.text = info.get("icon", "⭐")
				icon_lbl.add_theme_font_size_override("font_size", 46)
				icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				icon_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				I18n.protect(icon_lbl)
				vbox.add_child(icon_lbl)
		else:
			var locked_box := CenterContainer.new()
			locked_box.custom_minimum_size = Vector2(176, 114)
			locked_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var q_lbl := Label.new()
			q_lbl.text = "?"
			q_lbl.add_theme_font_size_override("font_size", 56)
			q_lbl.add_theme_color_override("font_color", Color(0.92, 0.28, 0.30))
			q_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.04))
			q_lbl.add_theme_constant_override("outline_size", 6)
			q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			I18n.protect(q_lbl)
			locked_box.add_child(q_lbl)
			vbox.add_child(locked_box)
		
		var name_lbl = Label.new()
		if is_unlocked:
			var title_map: Dictionary = STICKER_TITLES.get(key, {})
			name_lbl.text = str(title_map.get(lang, info.get("name", "")))
			name_lbl.modulate = Color(1.0, 0.95, 0.78)
		else:
			var prefix := "Sticker" if lang == "en" else "Figurinha"
			name_lbl.text = "%s #%d" % [prefix, world_idx]
			name_lbl.modulate = Color(0.75, 0.78, 0.84)
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		I18n.protect(name_lbl)
		vbox.add_child(name_lbl)
		
		var sub_lbl = Label.new()
		if is_unlocked:
			var raw_rarity: String = str(info.get("rarity", "Rara"))
			var r_map: Dictionary = RARITY_TRANSLATIONS.get(raw_rarity, {})
			sub_lbl.text = str(r_map.get(lang, raw_rarity))
			sub_lbl.modulate = Color(1.0, 0.84, 0.22)
		else:
			sub_lbl.text = _get_unlock_condition(world_idx)
			sub_lbl.modulate = Color(0.62, 0.68, 0.76)
		sub_lbl.add_theme_font_size_override("font_size", 13)
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		I18n.protect(sub_lbl)
		vbox.add_child(sub_lbl)
		
		grid_container.add_child(card)
