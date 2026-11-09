extends CanvasLayer

const SafeArea = preload("res://scripts/ui/SafeArea.gd")

# VillageHUD.gd - Interface da Vila Real do Rei
# Conecta botões da vila às telas de ajustes, mapa de fases e seleção de heróis

@onready var gold_label: Label = $TopBar/HBox/GoldContainer/GoldLabel
@onready var crown_label: Label = $TopBar/HBox/CrownContainer/CrownLabel
@onready var battle_button: Button = $BottomBar/BattleButton
@onready var heroes_button: Button = $BottomBar/HeroesButton
@onready var settings_button: Button = $TopBar/HBox/SettingsButton
@onready var album_button: Button = $TopBar/HBox/AlbumButton
@onready var trophies_button: Button = $TopBar/HBox/TrophiesButton
@onready var joystick: Control = get_node_or_null("VirtualJoystick")
@onready var top_bar: Control = $TopBar
@onready var bottom_bar: Control = $BottomBar

func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_update_hud()
	SaveManager.save_saved.connect(_update_hud)
	
	if joystick:
		joystick.joystick_updated.connect(_on_joystick_updated)
	
	if battle_button:
		battle_button.pressed.connect(_on_battle_pressed)
	if heroes_button:
		heroes_button.pressed.connect(_on_heroes_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if album_button:
		album_button.pressed.connect(_on_album_pressed)
	if trophies_button:
		trophies_button.pressed.connect(_on_trophies_pressed)

func _apply_safe_area() -> void:
	if top_bar:
		SafeArea.apply_horizontal(top_bar, 20.0, 20.0)
	if bottom_bar:
		SafeArea.apply_horizontal(bottom_bar, 40.0, 40.0)

func _on_album_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var scene = load("res://scenes/ui/StickerAlbum.tscn")
	if scene:
		add_child(scene.instantiate())

func _on_trophies_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var scene = load("res://scenes/ui/TrophiesMenu.tscn")
	if scene:
		add_child(scene.instantiate())

func _update_hud() -> void:
	if gold_label:
		gold_label.text = str(SaveManager.get_gold())
	if crown_label:
		var stars = int(SaveManager.save_data.get("crown_stars", 0))
		crown_label.text = "%d / 6" % stars
	if battle_button:
		var next_stage = int(SaveManager.save_data.get("unlocked_stages", 1))
		I18n.set_text(battle_button, "⚔ Batalha (Fase %d)" % next_stage)
	_update_hero_button()

func _on_battle_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var next_stage = int(SaveManager.save_data.get("unlocked_stages", 1))
	if next_stage % 10 == 0:
		MiniGameRunner.launch_challenge(next_stage)
	else:
		GameState.start_stage(next_stage)
		get_tree().change_scene_to_file("res://scenes/stages/StageMain.tscn")

func _on_heroes_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var unlocked: Array = SaveManager.save_data.get("unlocked_heroes", ["teodoro"])
	var available: Array = _hero_ids().filter(func(id): return unlocked.has(str(id)))
	if available.size() <= 1:
		_show_toast("Vença o Desafio 10 para ganhar Marta!")
		return
	var current = str(SaveManager.save_data.get("selected_hero", "teodoro"))
	var cur_idx = available.find(current)
	if cur_idx < 0:
		cur_idx = 0
	var next_idx = (cur_idx + 1) % available.size()
	SaveManager.save_data["selected_hero"] = available[next_idx]
	SaveManager.save_game()
	_update_hero_button()
	if GameState.king_node and is_instance_valid(GameState.king_node) and GameState.king_node.has_method("refresh_hero_appearance"):
		GameState.king_node.call("refresh_hero_appearance")

func _hero_ids() -> Array:
	var file := FileAccess.open("res://data/heroes/heroes.json", FileAccess.READ)
	if not file:
		return ["teodoro"]
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return ["teodoro"]
	var ids: Array = parsed.keys()
	ids.sort()
	return ids

func _show_toast(text: String) -> void:
	var toast := Label.new()
	toast.text = text
	toast.add_theme_font_size_override("font_size", 30)
	toast.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	toast.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05))
	toast.add_theme_constant_override("outline_size", 8)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position.y -= 150.0
	add_child(toast)
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)

func _update_hero_button() -> void:
	if heroes_button == null:
		return
	var hero_id = str(SaveManager.save_data.get("selected_hero", "teodoro"))
	var display := hero_id.capitalize()
	var file := FileAccess.open("res://data/heroes/heroes.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has(hero_id):
			display = str(parsed[hero_id].get("name", display))
	I18n.set_text(heroes_button, "Herói: %s" % display)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var settings_scene = load("res://scenes/ui/SettingsMenu.tscn")
	if settings_scene:
		var menu = settings_scene.instantiate()
		add_child(menu)

func _on_joystick_updated(direction: Vector2) -> void:
	if GameState.king_node and is_instance_valid(GameState.king_node):
		GameState.king_node.set_input_direction(direction)
