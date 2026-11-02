extends Node2D

# Challenge60_LaneDefense.gd - Desafio 60: Jardim da Defesa
# Defesa autoral de 5 faixas: estrelas cadentes geram faíscas estelares; posicionamento tático de tropas;
# Confronto final épico em 3 fases contra o Barão Cinzão!

var sparks: int = 150
var selected_defender: String = "archer"
var lane_count: int = 5
var lane_y_positions: Array = [160, 260, 360, 460, 560]
var boss_phase: int = 1 # 1: Névoa densa, 2: Gigantes de cinza, 3: Barão arrependido
var boss_hp: int = 600
var max_boss_hp: int = 600
var game_finished: bool = false

# Custos em faíscas estelares
const DEFENDER_COSTS: Dictionary = {
	"archer": 50,      # Disparo à distância
	"spearman": 75,    # Ataque frontal corpo a corpo
	"honey_barrel": 40,# Desacelera brumosos na faixa
	"shield_wall": 60, # Alta durabilidade
	"mage": 100        # Dano mágico em área
}

@onready var sparks_label: Label = $UI/TopPanel/HBox/SparksLabel
@onready var base_label: Label = $UI/TopPanel/HBox/BaseLabel
@onready var boss_bar: ProgressBar = $UI/TopPanel/HBox/BossContainer/BossBar
@onready var boss_label: Label = $UI/TopPanel/HBox/BossContainer/BossLabel
@onready var lane_container: Node2D = $Lanes
@onready var sparks_container: Node2D = $SparksContainer
@onready var victory_ui: CanvasLayer = $VictoryUI
@onready var archer_button: Button = $UI/BottomDefenderBar/ArcherBtn
@onready var spearman_button: Button = $UI/BottomDefenderBar/SpearmanBtn
@onready var mage_button: Button = $UI/BottomDefenderBar/MageBtn

var base_integrity: int = 3

func _ready() -> void:
	AudioManager.play_music("boss")
	if archer_button:
		archer_button.pressed.connect(select_defender.bind("archer"))
	if spearman_button:
		spearman_button.pressed.connect(select_defender.bind("spearman"))
	if mage_button:
		mage_button.pressed.connect(select_defender.bind("mage"))
	_update_ui()
	_start_falling_sparks_timer()
	_start_enemy_wave_timer()

func _update_ui() -> void:
	if sparks_label:
		sparks_label.text = "✨ Faíscas Estelares: %d" % sparks
	if base_label:
		base_label.text = "Base: %d" % base_integrity
	if boss_bar:
		boss_bar.max_value = max_boss_hp
		boss_bar.value = boss_hp
	if boss_label:
		boss_label.text = "Barão Cinzão (Fase %d/3)" % boss_phase

func _start_falling_sparks_timer() -> void:
	# Estrelas cadentes caem do céu a cada 3.5 segundos
	var timer = Timer.new()
	timer.wait_time = 3.5
	timer.autostart = true
	timer.timeout.connect(_spawn_falling_spark)
	add_child(timer)

func _spawn_falling_spark() -> void:
	if game_finished:
		return
	var spark = Area2D.new()
	spark.add_to_group("falling_sparks")
	spark.position = Vector2(randf_range(200, 1000), 50)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	spark.add_child(col)
	
	var lbl = Label.new()
	lbl.text = "⭐"
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.position = Vector2(-16, -20)
	spark.add_child(lbl)
	
	spark.input_event.connect(func(_vp, event, _shape):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.pressed:
				sparks += 25
				AudioManager.play_sfx("coin_pickup")
				_update_ui()
				spark.queue_free()
	)
	
	# Desce suavemente até o chão
	var tween = create_tween()
	tween.tween_property(spark, "position:y", randf_range(200, 600), 4.0)
	tween.tween_interval(5.0)
	tween.tween_callback(func():
		if is_instance_valid(spark):
			spark.queue_free()
	)
	sparks_container.add_child(spark)

func _start_enemy_wave_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.autostart = true
	timer.timeout.connect(_spawn_lane_enemy)
	add_child(timer)

func _spawn_lane_enemy() -> void:
	if game_finished:
		return
	var lane_idx = randi() % lane_count
	var target_y = lane_y_positions[lane_idx]
	
	var enemy = Area2D.new()
	enemy.add_to_group("lane_enemies")
	enemy.set_meta("lane_idx", lane_idx)
	enemy.position = Vector2(1250, target_y)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 50)
	col.shape = shape
	enemy.add_child(col)
	
	var lbl = Label.new()
	lbl.text = "👾"
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.position = Vector2(-20, -25)
	enemy.add_child(lbl)
	
	lane_container.add_child(enemy)
	
	# Move pela faixa em direção à esquerda
	var tween = create_tween()
	var duration = 16.0 if boss_phase == 1 else 12.0
	tween.tween_property(enemy, "position:x", 80.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(enemy):
			_on_enemy_reached_base(enemy)
	)

func _on_enemy_reached_base(enemy: Area2D) -> void:
	if game_finished:
		return
	enemy.queue_free()
	AudioManager.play_sfx("king_hit")
	sparks = maxi(0, sparks - 30)
	base_integrity -= 1
	_update_ui()
	if base_integrity <= 0 or sparks <= 0:
		_trigger_defeat()

func select_defender(type_id: String) -> void:
	selected_defender = type_id
	AudioManager.play_sfx("button_click")

func place_defender_on_lane(lane_idx: int) -> void:
	if game_finished or lane_idx < 0 or lane_idx >= lane_count:
		return
	var cost = DEFENDER_COSTS.get(selected_defender, 50)
	if sparks >= cost:
		sparks -= cost
		AudioManager.play_sfx("recruit")
		_update_ui()
		
		# Cria o defensor visual na faixa
		var def = Node2D.new()
		def.position = Vector2(240, lane_y_positions[lane_idx])
		var lbl = Label.new()
		match selected_defender:
			"spearman":
				lbl.text = "🗡️"
			"mage":
				lbl.text = "🔮"
			_:
				lbl.text = "🏹"
		lbl.add_theme_font_size_override("font_size", 36)
		def.add_child(lbl)
		lane_container.add_child(def)
		var attack_timer := Timer.new()
		attack_timer.wait_time = 1.25
		attack_timer.autostart = true
		def.add_child(attack_timer)
		attack_timer.timeout.connect(_defender_attack.bind(def, lane_idx))

func _defender_attack(defender: Node2D, lane_idx: int) -> void:
	if game_finished or not is_instance_valid(defender):
		return
	for enemy in get_tree().get_nodes_in_group("lane_enemies"):
		if not is_instance_valid(enemy) or int(enemy.get_meta("lane_idx", -1)) != lane_idx:
			continue
		if enemy.position.x < defender.position.x:
			continue
		enemy.queue_free()
		_damage_boss(50)
		return

func _unhandled_input(event: InputEvent) -> void:
	if game_finished:
		return
	var pressed_position := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed_position = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_position = event.position
	else:
		return
	if pressed_position.y < 110.0 or pressed_position.y > 610.0:
		return
	var lane_idx := clampi(int((pressed_position.y - 110.0) / 100.0), 0, lane_count - 1)
	place_defender_on_lane(lane_idx)

func _damage_boss(amount: int) -> void:
	if game_finished:
		return
	boss_hp -= amount
	AudioManager.play_sfx("hit")
	_update_ui()
	
	if boss_hp <= 400 and boss_phase == 1:
		boss_phase = 2
		AudioManager.play_sfx("hero_skill")
		_update_ui()
	elif boss_hp <= 200 and boss_phase == 2:
		boss_phase = 3
		AudioManager.play_sfx("hero_skill")
		_update_ui()
	elif boss_hp <= 0:
		_trigger_victory()

func _trigger_victory() -> void:
	if game_finished:
		return
	game_finished = true
	_stop_gameplay_timers()
	_clear_active_enemies()
	
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(60, {"won": true, "stars": 3})
	
	if victory_ui:
		victory_ui.show_victory(60, 3, "Barão Cinzão (Redimido)", 6)

func _trigger_defeat() -> void:
	if game_finished:
		return
	game_finished = true
	_stop_gameplay_timers()
	_clear_active_enemies()
	MiniGameRunner.complete_challenge(60, {"won": false, "stars": 0})
	var dialog := AcceptDialog.new()
	dialog.title = "Defesa perdida"
	dialog.dialog_text = "A base ficou sem faíscas e não pode mais resistir."
	dialog.confirmed.connect(func(): get_tree().change_scene_to_file("res://scenes/village/Village.tscn"))
	add_child(dialog)
	dialog.popup_centered()

func _stop_gameplay_timers() -> void:
	for child in get_children():
		if child is Timer:
			child.stop()

func _clear_active_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("lane_enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for spark in get_tree().get_nodes_in_group("falling_sparks"):
		if is_instance_valid(spark):
			spark.queue_free()

