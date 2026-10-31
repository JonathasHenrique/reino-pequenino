extends CanvasLayer

# GameHUD.gd - Interface do jogador durante as fases
# Exibe moedas, vida do rei, botão de habilidade do herói e joystick virtual

@onready var coin_label: Label = $TopBar/CoinContainer/CoinLabel
@onready var hp_bar: ProgressBar = $TopBar/HPContainer/HPBar
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var troop_label: Label = $TopBar/TroopContainer/TroopLabel
@onready var skill_button: Button = $ActionContainer/SkillButton
@onready var joystick: Control = $VirtualJoystick
@onready var fps_label: Label = $DebugOverlay/FPSLabel

func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.king_hp_changed.connect(_on_king_hp_changed)
	GameState.wave_started.connect(_on_wave_started)
	GameState.troop_count_changed.connect(_on_troop_count_changed)
	
	if joystick:
		joystick.joystick_updated.connect(_on_joystick_updated)
		
	if skill_button:
		skill_button.pressed.connect(_on_skill_pressed)
	
	_on_coins_changed(GameState.stage_coins)
	_on_king_hp_changed(GameState.king_hp, GameState.king_max_hp)
	_on_troop_count_changed(GameState.active_troops.size())
	_setup_hero_button()

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d | Tropas: %d" % [Engine.get_frames_per_second(), GameState.active_troops.size()]

func _setup_hero_button() -> void:
	var hero_id = SaveManager.save_data.get("selected_hero", "teodoro")
	match hero_id:
		"marta":
			skill_button.text = "Martelada"
		"fidelio":
			skill_button.text = "Rúnica"
		"rosa":
			skill_button.text = "Escudo"
		"clara":
			skill_button.text = "Bênção"
		"bento":
			skill_button.text = "Rugido"
		_:
			skill_button.text = "Coragem!"

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
		skill_button.disabled = true
		skill_button.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _on_joystick_updated(direction: Vector2) -> void:
	if GameState.king_node and is_instance_valid(GameState.king_node):
		GameState.king_node.set_input_direction(direction)
