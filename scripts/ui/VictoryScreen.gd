extends CanvasLayer

# VictoryScreen.gd - Tela de Vitória com avaliação de 1 a 3 Estrelas e Recompensa em Ouro

signal next_stage_requested()
signal return_to_village_requested()

@onready var stars_container: HBoxContainer = $Panel/VBox/StarsContainer
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var next_button: Button = $Panel/VBox/HBox/NextButton
@onready var village_button: Button = $Panel/VBox/HBox/VillageButton

func _ready() -> void:
	visible = false
	GameState.stage_completed.connect(_on_stage_completed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)

func _on_stage_completed(stars: int, gold_earned: int) -> void:
	visible = true
	if stars_container:
		for i in range(stars_container.get_child_count()):
			stars_container.get_child(i).set_star_filled(i < stars)
		stars_container.modulate.a = 0.0
		create_tween().tween_property(stars_container, "modulate:a", 1.0, 0.65)
	if gold_label:
		gold_label.text = "+%d Ouro Real Permanente" % gold_earned

func _on_next_pressed() -> void:
	AudioManager.play_sfx("button_click")
	next_stage_requested.emit()
	var next_id = GameState.current_stage + 1
	if next_id % 10 == 0:
		# Fase de Desafio/Minigame a cada 10 fases!
		MiniGameRunner.launch_challenge(next_id)
	else:
		GameState.start_stage(next_id)
		get_tree().reload_current_scene()

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameState.is_game_over = false
	GameState.is_stage_active = false
	return_to_village_requested.emit()
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

