extends Control

# IntroCutscene.gd - Cena de Abertura Narrativa do Reino Pequenino
# Humor em duas camadas: fofo para as crianças, irônico para os adultos

signal intro_completed()

@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var skip_button: Button = $SkipButton
@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel

func _ready() -> void:
	AudioManager.play_music("village")
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	
	_start_cutscene()

func _start_cutscene() -> void:
	var story_lines: Array[Dictionary] = [
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "Teodoro! A Coroa Mãe sumiu!"
		},
		{
			"speaker": "Rei Teodoro",
			"icon": "👑",
			"text": "O Biscoito achou que era aveia!"
		},
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "O Barão levou as 6 Estrelas!"
		},
		{
			"speaker": "Rei Teodoro",
			"icon": "👑",
			"text": "Vamos resgatar todas!"
		},
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "Pegue a espada e os arqueiros!"
		}
	]
	
	dialogue_box.show_dialogue(story_lines)

func _on_skip_pressed() -> void:
	_finish_intro()

func _on_dialogue_finished() -> void:
	_finish_intro()

func _finish_intro() -> void:
	AudioManager.play_sfx("button_click")
	intro_completed.emit()
	GameState.start_stage(1)
	get_tree().change_scene_to_file("res://scenes/stages/StageMain.tscn")

