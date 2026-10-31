extends CanvasLayer

# StickerAlbum.gd - Álbum de Figurinhas Colecionável do Reino
# Estética nostálgica de álbum de banca de jornal e figurinhas metalizadas

@onready var grid_container: GridContainer = $Panel/VBox/Scroll/GridContainer
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			queue_free()
		)
	_populate_stickers()

func _populate_stickers() -> void:
	var path = "res://data/stickers/stickers.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	var unlocked_stickers: Array = SaveManager.save_data.get("stickers", [])
	
	for key in data.keys():
		var info = data[key]
		var is_unlocked = unlocked_stickers.has(key)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(160, 190)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		var icon_lbl = Label.new()
		icon_lbl.text = info.get("icon", "⭐") if is_unlocked else "❓"
		icon_lbl.add_theme_font_size_override("font_size", 46)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(icon_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = info.get("name", "") if is_unlocked else "Figurinha %s" % key.replace("star_", "")
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		var rarity_lbl = Label.new()
		rarity_lbl.text = info.get("rarity", "") if is_unlocked else "Bloqueada"
		rarity_lbl.add_theme_font_size_override("font_size", 12)
		rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_lbl.modulate = Color(1.0, 0.8, 0.2) if is_unlocked else Color(0.5, 0.5, 0.5)
		vbox.add_child(rarity_lbl)
		
		grid_container.add_child(card)

