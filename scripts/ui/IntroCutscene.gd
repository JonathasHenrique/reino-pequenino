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
			"text": "Teodoro, meu neto... eu avisei trinta vezes para não deixar a grande Coroa Mãe na janela enquanto tomava café com leite."
		},
		{
			"speaker": "Rei Teodoro",
			"icon": "👑",
			"text": "Mas Vovó, o Biscoito só queria ver o reflexo dourado dele no espelho da coroa! Ele achou que era um pacote de aveia gigante."
		},
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "Pois é. Agora o Barão Cinzão ficou amuado porque esqueceram de convidá-lo para a quermesse do reino e levou as 6 Estrelas embora na Bruma."
		},
		{
			"speaker": "Rei Teodoro",
			"icon": "👑",
			"text": "Nós vamos resgatar todas as Estrelas, Vovó! O Biscoito já calçou as ferraduras de passeio."
		},
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "Muito bem. Pegue sua espada de madeira, reúna os arqueiros do vilarejo e lembre-se: nada de correr de meia no piso ensaboado. Vamos ao Vale dos Girassóis!"
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

