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

var skill_label: String = "Grito de Coragem"
var skill_desc: String = "Tropas atacam 30% mais rápido por 8 segundos."
var active_buff_toast: Control = null

func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.spoils_changed.connect(_on_spoils_changed)
	GameState.king_hp_changed.connect(_on_king_hp_changed)
	GameState.wave_started.connect(_on_wave_started)
	GameState.troop_count_changed.connect(_on_troop_count_changed)
	GameState.dialogue_visibility_changed.connect(_on_dialogue_visibility_changed)
	I18n.language_changed.connect(func(_code: String): _setup_hero_button())
	
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
		action_container.offset_left = -190.0 - insets.y
		action_container.offset_right = -insets.y

func _on_spoils_changed(amount: int) -> void:
	if spoil_label:
		spoil_label.text = str(amount)

func _process(_delta: float) -> void:
	if fps_label:
		I18n.set_text(fps_label, "FPS: %d | Tropas: %d" % [Engine.get_frames_per_second(), GameState.active_troops.size()])
	if skill_button:
		if GameState.hero_ability_duration_remaining > 0.0:
			# Durante o efeito ativo do buff (ex: 8s)
			skill_button.disabled = false
			skill_button.text = "🔥 %ds..." % ceili(GameState.hero_ability_duration_remaining)
			skill_button.modulate = Color(1.0, 0.88, 0.25)
		elif not GameState.hero_ability_ready:
			# Cooldown
			skill_button.disabled = true
			skill_button.text = "⏳ %ds" % ceili(GameState.hero_ability_cooldown_remaining)
			skill_button.modulate = Color(0.6, 0.6, 0.6, 0.7)
		else:
			# Pronto para usar
			skill_button.disabled = GameState.is_game_over
			skill_button.text = skill_label
			skill_button.modulate = Color.WHITE

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
	var raw_skill: String = str(hero_data.get("skill_name", "Grito de Coragem"))
	var raw_desc: String = str(hero_data.get("skill_desc", "Tropas atacam 30% mais rápido por 8 segundos."))
	var skill_key := "heroes.%s_skill_name" % hero_id
	var desc_key := "heroes.%s_skill_desc" % hero_id
	
	skill_label = I18n.t_key(skill_key)
	if skill_label == skill_key:
		skill_label = I18n.tr_text(raw_skill)
		
	skill_desc = I18n.t_key(desc_key)
	if skill_desc == desc_key:
		skill_desc = I18n.tr_text(raw_desc)
		
	if skill_button:
		skill_button.tooltip_text = skill_desc
		if GameState.hero_ability_ready:
			skill_button.text = skill_label

func _on_coins_changed(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)

func _on_king_hp_changed(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current

func _on_wave_started(wave_idx: int, total_waves: int) -> void:
	if wave_label:
		I18n.set_text(wave_label, "Onda %d / %d" % [wave_idx, total_waves])

func _on_troop_count_changed(count: int) -> void:
	if troop_label:
		troop_label.text = str(count)

func set_tutorial_lock(locked: bool) -> void:
	if skill_button:
		skill_button.disabled = locked
		skill_button.visible = not locked

func _on_skill_pressed() -> void:
	if GameState.hero_ability_ready:
		GameState.use_hero_ability()
		_show_buff_toast(skill_desc)

func _show_buff_toast(text: String) -> void:
	if active_buff_toast and is_instance_valid(active_buff_toast):
		active_buff_toast.queue_free()
		active_buff_toast = null
		
	var toast := PanelContainer.new()
	active_buff_toast = toast
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08, 0.94)
	style.border_color = Color(1.0, 0.788, 0.235, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	toast.add_theme_stylebox_override("panel", style)
	
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_child(lbl)
	
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast)
	_update_toast_position()
	
	# Quando a caixa de diálogo ou tutorial estiver visível, oculte temporariamente o toast de buff
	if GameState.is_dialogue_or_tutorial_open:
		toast.visible = false
	
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		if is_instance_valid(toast):
			toast.queue_free()
		if active_buff_toast == toast:
			active_buff_toast = null
	)

func _update_toast_position() -> void:
	if not active_buff_toast or not is_instance_valid(active_buff_toast):
		return
	if GameState.is_dialogue_or_tutorial_open:
		active_buff_toast.visible = false
	else:
		active_buff_toast.visible = true
	active_buff_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	active_buff_toast.position.y -= 140.0

func _on_dialogue_visibility_changed(dialogue_open: bool) -> void:
	if active_buff_toast and is_instance_valid(active_buff_toast):
		active_buff_toast.visible = not dialogue_open
		if not dialogue_open:
			_update_toast_position()

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

