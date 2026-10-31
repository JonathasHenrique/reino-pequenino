extends CanvasLayer

# VillageHUD.gd - Interface da Vila Real do Rei
# Conecta botões da vila às telas de ajustes, mapa de fases e seleção de heróis

@onready var gold_label: Label = $TopBar/HBox/GoldContainer/GoldLabel
@onready var crown_label: Label = $TopBar/HBox/CrownContainer/CrownLabel
@onready var battle_button: Button = $BottomBar/BattleButton
@onready var heroes_button: Button = $BottomBar/HeroesButton
@onready var settings_button: Button = $TopBar/HBox/SettingsButton
@onready var album_button: Button = $TopBar/HBox/AlbumButton
@onready var trophies_button: Button = $TopBar/HBox/TrophiesButton

func _ready() -> void:
	_update_hud()
	SaveManager.save_saved.connect(_update_hud)
	
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
		battle_button.text = "⚔️ Batalha (Fase %d)" % next_stage

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
	# Alterna o herói selecionado entre os desbloqueados para teste rápido
	var unlocked = SaveManager.save_data.get("unlocked_heroes", ["teodoro"])
	var current = SaveManager.save_data.get("selected_hero", "teodoro")
	var cur_idx = unlocked.find(current)
	var next_idx = (cur_idx + 1) % unlocked.size()
	SaveManager.save_data["selected_hero"] = unlocked[next_idx]
	SaveManager.save_game()
	
	var hero_name = unlocked[next_idx].capitalize()
	if heroes_button:
		heroes_button.text = "Herói: %s" % hero_name

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var settings_scene = load("res://scenes/ui/SettingsMenu.tscn")
	if settings_scene:
		var menu = settings_scene.instantiate()
		add_child(menu)
