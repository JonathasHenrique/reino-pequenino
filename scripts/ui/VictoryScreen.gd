extends CanvasLayer

# VictoryScreen.gd - Tela de Vitória com avaliação real de 1 a 3 Estrelas e Recompensa em Ouro

signal next_stage_requested()
signal return_to_village_requested()

@onready var vbox: VBoxContainer = $Panel/VBox
@onready var stars_container: HBoxContainer = $Panel/VBox/StarsContainer
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var next_button: Button = $Panel/VBox/HBox/NextButton
@onready var village_button: Button = $Panel/VBox/HBox/VillageButton

var criteria_box: VBoxContainer = null
var _criteria_labels: Array[Label] = []
var _last_stars: int = 3
var _last_gold: int = 60

func _ready() -> void:
	visible = false
	_setup_criteria_box()
	GameState.stage_completed.connect(_on_stage_completed)
	I18n.language_changed.connect(func(_code: String): _refresh_texts())
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)

func _setup_criteria_box() -> void:
	if vbox == null or criteria_box != null:
		return
	criteria_box = VBoxContainer.new()
	criteria_box.name = "CriteriaContainer"
	criteria_box.add_theme_constant_override("separation", 4)
	vbox.add_child(criteria_box)
	if stars_container:
		vbox.move_child(criteria_box, stars_container.get_index() + 1)
	for i in range(3):
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		criteria_box.add_child(lbl)
		_criteria_labels.append(lbl)
	_refresh_texts()

func _on_stage_completed(stars: int, gold_earned: int) -> void:
	_last_stars = stars
	_last_gold = gold_earned
	visible = true
	if stars_container:
		for i in range(stars_container.get_child_count()):
			stars_container.get_child(i).set_star_filled(i < stars)
		stars_container.modulate.a = 0.0
		create_tween().tween_property(stars_container, "modulate:a", 1.0, 0.65)
	_refresh_texts()

func _refresh_texts() -> void:
	if gold_label:
		var fmt := I18n.t_key("ui.gold_permanent_earned")
		if fmt == "ui.gold_permanent_earned":
			fmt = "+%d " + I18n.tr_text("Ouro Real Permanente")
		gold_label.text = fmt % _last_gold
		I18n.protect(gold_label)
	var keys := ["ui.star_1_criteria", "ui.star_2_criteria", "ui.star_3_criteria"]
	for i in range(_criteria_labels.size()):
		var lbl := _criteria_labels[i]
		var earned := i < _last_stars
		var prefix := "[OK] " if earned else "[ - ] "
		lbl.text = prefix + I18n.t_key(keys[i])
		lbl.add_theme_color_override("font_color", Color(0.62, 0.98, 0.58) if earned else Color(0.68, 0.68, 0.72))
		I18n.protect(lbl)

func _on_next_pressed() -> void:
	AudioManager.play_sfx("button_click")
	next_stage_requested.emit()
	var next_id = GameState.current_stage + 1
	if next_id % 10 == 0:
		# Fase de Desafio/Minigame a cada 10 fases!
		MiniGameRunner.launch_challenge(next_id)
	else:
		GameState.start_stage(next_id)
		SceneTransition.change_scene("res://scenes/stages/StageMain.tscn")

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameState.is_game_over = false
	GameState.is_stage_active = false
	return_to_village_requested.emit()
	SceneTransition.change_scene("res://scenes/village/Village.tscn")

