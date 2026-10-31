extends Control

# EndingCutscene.gd - Final emocionante: A Festa da Coroa Mãe
# O Barão Cinzão não é destruído; é acolhido com bolo, chapéu festivo e amizade

signal credits_requested()

@onready var dialogue_box: CanvasLayer = $DialogueBox
@onready var village_btn: Button = $VillageButton

func _ready() -> void:
	AudioManager.play_music("village")
	if village_btn:
		village_btn.pressed.connect(_on_village_pressed)
	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	
	_start_ending()

func _start_ending() -> void:
	var ending_lines: Array[Dictionary] = [
		{
			"speaker": "Barão Cinzão",
			"icon": "🎩",
			"text": "Eu... eu só queria ter sido convidado. Todo ano vocês fazem aquele bolo de amoras perfumado e esquecem o velho guardião do castelo norte..."
		},
		{
			"speaker": "Rei Teodoro",
			"icon": "👑",
			"text": "Barão! O seu convite deve ter se perdido na caixa de correio do Moinho! Nós guardamos a maior fatia de bolo com cobertura dourada para você."
		},
		{
			"speaker": "Dona Zenaide",
			"icon": "👵",
			"text": "Deixe de bico, Cinzão. Venha tomar chá, coloque esse chapeuzinho de festa amarelo e ajude as crianças a recolocar as Seis Estrelas na Coroa Mãe."
		},
		{
			"speaker": "Narrador",
			"icon": "✨",
			"text": "E assim, a Bruma se dissipou em cores vibrantes. As seis Estrelas voltaram à Coroa Mãe e o Reino Pequenino viveu a festa mais doce de sua história."
		}
	]
	
	dialogue_box.show_dialogue(ending_lines)

func _on_dialogue_finished() -> void:
	if village_btn:
		village_btn.visible = true

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

