extends CanvasLayer

# ChallengeVictoryScreen.gd - Painel de Recompensa de Minigame e Desafio
# Exibe a Estrela da Coroa recuperada e a ficha do Herói desbloqueado

@onready var star_label: Label = $Panel/VBox/StarLabel
@onready var hero_card: PanelContainer = $Panel/VBox/HeroCard
@onready var hero_title: Label = $Panel/VBox/HeroCard/VBox/HeroTitle
@onready var hero_desc: Label = $Panel/VBox/HeroCard/VBox/HeroDesc
@onready var village_btn: Button = $Panel/VBox/VillageButton

func _ready() -> void:
	visible = false
	if village_btn:
		village_btn.pressed.connect(_on_village_pressed)

func show_victory(_challenge_id: int, _stars: int, hero_name: String, star_index: int) -> void:
	visible = true
	if star_label:
		star_label.text = "👑 %dª ESTRELA DA COROA RECUPERADA! 👑" % star_index
	if hero_title:
		hero_title.text = "NOVO HERÓI DESBLOQUEADO: %s" % hero_name.to_upper()
	if hero_desc:
		hero_desc.text = "Passiva: Construções 15% mais baratas nas fases.\nHabilidade Ativa: Martelada Mestra (conserta e fortalece todas as torres)."

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

