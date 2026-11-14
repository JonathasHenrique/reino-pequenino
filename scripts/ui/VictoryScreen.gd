extends CanvasLayer

# VictoryScreen.gd - Tela de Vitória com avaliação real de 1 a 3 Estrelas, Recompensa em Ouro e opção de Dobrar Ouro (x2)

signal next_stage_requested()
signal return_to_village_requested()

@onready var vbox: VBoxContainer = $Panel/VBox
@onready var stars_container: HBoxContainer = $Panel/VBox/StarsContainer
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var next_button: Button = $Panel/VBox/HBox/NextButton
@onready var village_button: Button = $Panel/VBox/HBox/VillageButton
@onready var double_gold_button: Button = get_node_or_null("Panel/VBox/HBox/DoubleGoldButton")

var criteria_box: VBoxContainer = null
var _criteria_labels: Array[Label] = []
var _last_stars: int = 3
var _base_gold: int = 60
var _last_gold: int = 60
var _double_gold_claimed: bool = false

func _ready() -> void:
	visible = false
	_style_double_gold_button()
	_setup_criteria_box()
	GameState.stage_completed.connect(_on_stage_completed)
	AdManager.ad_reward_earned.connect(_on_ad_reward_earned)
	I18n.language_changed.connect(func(_code: String): _refresh_texts())
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)
	if double_gold_button:
		double_gold_button.pressed.connect(_on_double_gold_pressed)

func _style_double_gold_button() -> void:
	if not double_gold_button:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1.0, 0.78, 0.14, 1.0)
	st.border_color = Color(1.0, 0.95, 0.65, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	double_gold_button.add_theme_stylebox_override("normal", st)

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
	_base_gold = gold_earned
	_last_gold = gold_earned
	_double_gold_claimed = false
	if double_gold_button:
		double_gold_button.disabled = false
		double_gold_button.visible = true
	visible = true
	if stars_container:
		for i in range(stars_container.get_child_count()):
			stars_container.get_child(i).set_star_filled(i < stars)
		stars_container.modulate.a = 0.0
		create_tween().tween_property(stars_container, "modulate:a", 1.0, 0.65)
	_refresh_texts()

func _on_double_gold_pressed() -> void:
	if _double_gold_claimed:
		return
	AudioManager.play_sfx("button_click")
	AdManager.show_rewarded_ad("double_gold", _base_gold)

func _on_ad_reward_earned(reward_type: String, _amount: int) -> void:
	if reward_type != "double_gold" or not visible or _double_gold_claimed:
		return
	_double_gold_claimed = true
	GameState.add_bonus_stage_gold(_base_gold)
	_last_gold = _base_gold * 2
	if double_gold_button:
		double_gold_button.disabled = true
	_refresh_texts()

func _refresh_texts() -> void:
	if gold_label:
		var fmt := I18n.t_key("ui.gold_permanent_earned")
		if fmt == "ui.gold_permanent_earned":
			fmt = "+%d " + I18n.tr_text("Ouro Real Permanente")
		var suffix := " (x2!)" if _double_gold_claimed else ""
		gold_label.text = (fmt % _last_gold) + suffix
		I18n.protect(gold_label)
	if double_gold_button:
		var lang: String = I18n.language
		if _double_gold_claimed:
			if lang == "en":
				double_gold_button.text = "✓ Gold Doubled (x2)!"
			elif lang == "es":
				double_gold_button.text = "✓ ¡Oro Duplicado (x2)!"
			else:
				double_gold_button.text = "✓ Ouro Dobrado (x2)!"
		else:
			if lang == "en":
				double_gold_button.text = "🎬 Double Gold (x2)"
			elif lang == "es":
				double_gold_button.text = "🎬 Duplicar Oro (x2)"
			else:
				double_gold_button.text = "🎬 Dobrar Ouro (x2)"
		I18n.protect(double_gold_button)
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
