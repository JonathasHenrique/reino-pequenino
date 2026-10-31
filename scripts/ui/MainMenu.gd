extends Control

# MainMenu.gd - Menu Principal do Reino Pequenino
# Ponto de entrada com estética acolhedora de brinquedo e música alegre

@onready var play_button: Button = $VBox/PlayButton
@onready var village_button: Button = $VBox/VillageButton
@onready var settings_button: Button = $VBox/SettingsButton

func _ready() -> void:
	AudioManager.play_music("village")
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var unlocked = int(SaveManager.save_data.get("unlocked_stages", 1))
	if unlocked == 1 and not SaveManager.save_data.get("stage_stars", {}).has("1"):
		# Primeira vez: exibe a cena de abertura e tutorial
		get_tree().change_scene_to_file("res://scenes/ui/IntroCutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var settings_scene = load("res://scenes/ui/SettingsMenu.tscn")
	if settings_scene:
		var menu = settings_scene.instantiate()
		add_child(menu)

