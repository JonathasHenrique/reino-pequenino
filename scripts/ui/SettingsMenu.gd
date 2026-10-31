extends CanvasLayer

# SettingsMenu.gd - Painel Completo de Configurações do Reino Pequenino
# Controla áudio, vibração, dificuldade (3 modos), modo retrô e acessibilidade

signal closed()

@onready var music_slider: HSlider = $Panel/VBox/Grid/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/Grid/SFXSlider
@onready var vibration_check: CheckBox = $Panel/VBox/Grid/VibrationCheck
@onready var retro_check: CheckBox = $Panel/VBox/Grid/RetroCheck
@onready var effects_check: CheckBox = $Panel/VBox/Grid/EffectsCheck
@onready var diff_option: OptionButton = $Panel/VBox/Grid/DiffOption
@onready var lang_option: OptionButton = $Panel/VBox/Grid/LangOption
@onready var close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	_populate_options()
	_load_current_values()
	_connect_signals()

func _populate_options() -> void:
	if diff_option:
		diff_option.clear()
		diff_option.add_item("Tranquilo (Modo Passeio)", Settings.Difficulty.TRANQUILO)
		diff_option.add_item("Clássico (Recomendado)", Settings.Difficulty.CLASSICO)
		diff_option.add_item("Veterano (Sem Dicas & Desafio Alto)", Settings.Difficulty.VETERANO)
	
	if lang_option:
		lang_option.clear()
		lang_option.add_item("Português (Brasil)", 0)
		lang_option.add_item("English", 1)

func _load_current_values() -> void:
	if music_slider:
		music_slider.value = Settings.music_volume * 100.0
	if sfx_slider:
		sfx_slider.value = Settings.sfx_volume * 100.0
	if vibration_check:
		vibration_check.button_pressed = Settings.vibration_enabled
	if retro_check:
		retro_check.button_pressed = Settings.retro_mode
	if effects_check:
		effects_check.button_pressed = Settings.reduced_effects
	if diff_option:
		diff_option.select(Settings.difficulty)
	if lang_option:
		lang_option.select(0 if Settings.language == "pt_BR" else 1)

func _connect_signals() -> void:
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if vibration_check:
		vibration_check.toggled.connect(_on_vibration_toggled)
	if retro_check:
		retro_check.toggled.connect(_on_retro_toggled)
	if effects_check:
		effects_check.toggled.connect(_on_effects_toggled)
	if diff_option:
		diff_option.item_selected.connect(_on_diff_selected)
	if lang_option:
		lang_option.item_selected.connect(_on_lang_selected)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_music_changed(val: float) -> void:
	Settings.music_volume = val / 100.0
	Settings.save_settings()

func _on_sfx_changed(val: float) -> void:
	Settings.sfx_volume = val / 100.0
	Settings.save_settings()

func _on_vibration_toggled(toggled: bool) -> void:
	Settings.vibration_enabled = toggled
	Settings.save_settings()

func _on_retro_toggled(toggled: bool) -> void:
	Settings.set_retro_mode(toggled)

func _on_effects_toggled(toggled: bool) -> void:
	Settings.reduced_effects = toggled
	Settings.save_settings()

func _on_diff_selected(idx: int) -> void:
	Settings.difficulty = idx as Settings.Difficulty
	Settings.save_settings()

func _on_lang_selected(idx: int) -> void:
	Settings.language = "pt_BR" if idx == 0 else "en"
	Settings.save_settings()

func _on_close_pressed() -> void:
	AudioManager.play_sfx("button_click")
	closed.emit()
	queue_free()
