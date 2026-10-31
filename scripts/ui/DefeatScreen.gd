extends CanvasLayer

# DefeatScreen.gd - Tela de Derrota Amigável (sem violência)
# O jovem rei dá uma tropeçada e pode tentar novamente imediatamente

signal retry_stage_requested()
signal return_to_village_requested()

@onready var retry_button: Button = $Panel/VBox/HBox/RetryButton
@onready var village_button: Button = $Panel/VBox/HBox/VillageButton

func _ready() -> void:
	visible = false
	GameState.stage_failed.connect(_on_stage_failed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)

func _on_stage_failed() -> void:
	visible = true

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("button_click")
	retry_stage_requested.emit()
	GameState.start_stage(GameState.current_stage)
	get_tree().reload_current_scene()

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameState.is_game_over = false
	return_to_village_requested.emit()
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

