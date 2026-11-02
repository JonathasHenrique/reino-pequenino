extends CanvasLayer

const SafeArea = preload("res://scripts/ui/SafeArea.gd")

# GameHUD.gd - Interface do jogador durante as fases
# Exibe moedas, vida do rei, botão de habilidade do herói e joystick virtual

@onready var coin_label: Label = $TopBar/HBox/CoinPill/CoinBox/CoinLabel
@onready var spoil_label: Label = $TopBar/HBox/SpoilPill/SpoilBox/SpoilLabel
@onready var hp_bar: ProgressBar = $TopBar/HBox/HPPill/HPBox/HPBar
@onready var wave_label: Label = $TopBar/HBox/WavePill/WaveLabel
@onready var troop_label: Label = $TopBar/HBox/TroopPill/TroopBox/TroopLabel
@onready var skill_button: Button = $ActionContainer/SkillButton
@onready var joystick: Control = $VirtualJoystick
@onready var fps_label: Label = $DebugOverlay/FPSLabel
@onready var pause_button: Button = $TopBar/HBox/PauseButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/Panel/VBox/ResumeButton
@onready var village_button: Button = $PauseOverlay/Panel/VBox/VillageButton
@onready var top_bar: Control = $TopBar
@onready var action_container: Control = $ActionContainer

var skill_label: String = "Coragem!"

func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.spoils_changed.connect(_on_spoils_changed)
	GameState.king_hp_changed.connect(_on_king_hp_changed)
	GameState.wave_started.connect(_on_wave_started)
	GameState.troop_count_changed.connect(_on_troop_count_changed)
	
	if joystick:
		joystick.joystick_updated.connect(_on_joystick_updated)
		
	if skill_button:
		skill_button.pressed.connect(_on_skill_pressed)
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if village_button:
		village_button.pressed.connect(_on_pause_village_pressed)
	
	_on_coins_changed(GameState.stage_coins)
	_on_spoils_changed(GameState.stage_spoils)
	_on_king_hp_changed(GameState.king_hp, GameState.king_max_hp)
	_on_troop_count_changed(GameState.active_troops.size())
	_setup_hero_button()

func _apply_safe_area() -> void:
	if top_bar:
		SafeArea.apply_horizontal(top_bar, 20.0, 20.0)
	if action_container:
		var insets := SafeArea.horizontal_insets(action_container)
		action_container.offset_left = -160.0 - insets.y
		action_container.offset_right = -insets.y

func _on_spoils_changed(amount: int) -> void:
	if spoil_label:
		spoil_label.text = str(amount)

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d | Tropas: %d" % [Engine.get_frames_per_second(), GameState.active_troops.size()]
	if skill_button:
		if GameState.hero_ability_ready:
			skill_button.disabled = GameState.is_game_over
			skill_button.text = skill_label
			skill_button.modulate = Color.WHITE
		else:
			skill_button.disabled = true
			skill_button.text = "%ds" % ceili(GameState.hero_ability_cooldown_remaining)
			skill_button.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _setup_hero_button() -> void:
	var hero_id = SaveManager.save_data.get("selected_hero", "teodoro")
	var file := FileAccess.open("res://data/heroes/heroes.json", FileAccess.READ)
	if not file:
		return
	var heroes: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(heroes) != TYPE_DICTIONARY:
		return
	var hero_data: Dictionary = heroes.get(hero_id, {})
	skill_label = str(hero_data.get("skill_name", "Coragem!"))
	skill_button.tooltip_text = str(hero_data.get("skill_desc", ""))

func _on_coins_changed(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)

func _on_king_hp_changed(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current

func _on_wave_started(wave_idx: int, total_waves: int) -> void:
	if wave_label:
		wave_label.text = "Onda %d / %d" % [wave_idx, total_waves]

func _on_troop_count_changed(count: int) -> void:
	if troop_label:
		troop_label.text = str(count)

func _on_skill_pressed() -> void:
	if GameState.hero_ability_ready:
		GameState.use_hero_ability()

func _on_pause_pressed() -> void:
	if GameState.is_game_over:
		return
	GameState.is_paused = true
	pause_overlay.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("button_click")
	pause_overlay.visible = false
	GameState.is_paused = false
	get_tree().paused = false

func _on_pause_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	pause_overlay.visible = false
	GameState.is_paused = false
	GameState.is_stage_active = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

func _on_joystick_updated(direction: Vector2) -> void:
	if GameState.king_node and is_instance_valid(GameState.king_node):
		GameState.king_node.set_input_direction(direction)

