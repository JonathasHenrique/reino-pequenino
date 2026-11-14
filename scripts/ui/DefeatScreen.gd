extends CanvasLayer

# DefeatScreen.gd - Tela de Derrota Amigável (sem violência)
# Inclui Segunda Chance opcional via anúncio recompensado a partir da Fase 2 (1x por tentativa)

signal retry_stage_requested()
signal return_to_village_requested()

@onready var retry_button: Button = $Panel/VBox/HBox/RetryButton
@onready var village_button: Button = $Panel/VBox/HBox/VillageButton
@onready var revive_ad_button: Button = get_node_or_null("Panel/VBox/HBox/ReviveAdButton")

func _ready() -> void:
	visible = false
	_style_revive_button()
	GameState.stage_failed.connect(_on_stage_failed)
	GameState.stage_revived.connect(func(): visible = false)
	AdManager.ad_reward_earned.connect(_on_ad_reward_earned)
	I18n.language_changed.connect(func(_code: String): _refresh_revive_text())
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if village_button:
		village_button.pressed.connect(_on_village_pressed)
	if revive_ad_button:
		revive_ad_button.pressed.connect(_on_revive_ad_pressed)
	_refresh_revive_text()

func _style_revive_button() -> void:
	if not revive_ad_button:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.16, 0.58, 0.28, 1.0)
	st.border_color = Color(1.0, 0.84, 0.22, 1.0)
	st.set_border_width_all(3)
	st.set_corner_radius_all(14)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	revive_ad_button.add_theme_stylebox_override("normal", st)
	var st_hover := st.duplicate() as StyleBoxFlat
	st_hover.bg_color = Color(0.22, 0.68, 0.34, 1.0)
	revive_ad_button.add_theme_stylebox_override("hover", st_hover)
	revive_ad_button.add_theme_stylebox_override("pressed", st_hover)

func _refresh_revive_text() -> void:
	if not revive_ad_button:
		return
	var lang: String = I18n.language
	if lang == "en":
		revive_ad_button.text = "🎬 Second Chance! (50% Wall + Royal Push)"
	elif lang == "es":
		revive_ad_button.text = "🎬 ¡Segunda Oportunidad! (50% Muro + Empuje Real)"
	else:
		revive_ad_button.text = "🎬 Segunda Chance! (50% Muralha + Empurrão Real)"
	I18n.protect(revive_ad_button)

func _on_stage_failed() -> void:
	if revive_ad_button:
		# Fase 1 ou já usou Segunda Chance -> Game Over normal sem botão de anúncio
		var can_revive: bool = (GameState.current_stage > 1) and (not GameState.revive_used)
		revive_ad_button.visible = can_revive
		revive_ad_button.disabled = not can_revive
		_refresh_revive_text()
	visible = true

func _on_revive_ad_pressed() -> void:
	if GameState.current_stage <= 1 or GameState.revive_used:
		return
	AudioManager.play_sfx("button_click")
	AdManager.show_rewarded_ad("revive_wall", 50)

func _on_ad_reward_earned(reward_type: String, _amount: int) -> void:
	if reward_type != "revive_wall" or not visible:
		return
	visible = false
	GameState.revive_wall_second_chance()

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
