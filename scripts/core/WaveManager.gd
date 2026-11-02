extends Node

# WaveManager.gd - Gerenciador de Ondas de Inimigos Orientado a Dados
# Lê o arquivo do mundo correto, gera ondas procedurais quando o JSON não as define,
# instancia o tipo certo de inimigo e só libera o Totem quando TODAS as ondas foram vencidas.

signal wave_countdown_updated(seconds_left: float)
signal all_waves_spawned()

const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/MistyRunner.tscn")

# Aparência de cada tipo (escala e cor), para diferenciar sem depender só da cor (daltonismo)
const ENEMY_LOOKS: Dictionary = {
	"misty_runner": {"scale": 1.0, "tint": Color(0.48, 0.54, 0.62)},
	"misty_squire": {"scale": 1.25, "tint": Color(0.40, 0.46, 0.58)},
	"misty_archer": {"scale": 0.9, "tint": Color(0.55, 0.60, 0.70)},
	"misty_crow": {"scale": 0.7, "tint": Color(0.30, 0.33, 0.40)},
	"misty_giant": {"scale": 2.2, "tint": Color(0.36, 0.40, 0.50)}
}

@export var stage_id: int = 1
@export var default_prep_time: float = 8.0

var total_waves: int = 2
var current_wave_idx: int = 0
var wave_data: Array = []
var enemy_stats: Dictionary = {}
var is_in_prep_phase: bool = true
var prep_timer: float = 0.0
var finished: bool = false
var tutorial_hold: bool = false

var active_enemies_count: int = 0
var pending_spawns: int = 0 # inimigos agendados que ainda não nasceram
var spawn_markers: Dictionary = {}

func _ready() -> void:
	# CORREÇÃO: _ready do filho roda antes do pai, então lemos a fase direto do GameState
	stage_id = GameState.current_stage
	_load_enemy_stats()
	_load_wave_data()

func setup_spawn_points(markers: Dictionary) -> void:
	spawn_markers = markers

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func _load_enemy_stats() -> void:
	var data = _read_json("res://data/enemies/enemies.json")
	if typeof(data) == TYPE_DICTIONARY:
		enemy_stats = data

func _load_wave_data() -> void:
	var world = int((stage_id - 1) / 10) + 1
	var data = _read_json("res://data/waves/world%d_waves.json" % world)
	var key = "stage_" + str(stage_id)
	if typeof(data) == TYPE_DICTIONARY and data.has(key):
		var s_data: Dictionary = data[key]
		total_waves = int(s_data.get("total_waves", 3))
		default_prep_time = float(s_data.get("prep_time_seconds", 8.0))
		wave_data = s_data.get("waves", [])
	if wave_data.is_empty():
		wave_data = _generate_waves(stage_id, total_waves)
	total_waves = wave_data.size()
	
	# Dificuldade: Tranquilo dá mais tempo para construir, Veterano menos
	match Settings.difficulty:
		Settings.Difficulty.TRANQUILO:
			default_prep_time *= 1.4
		Settings.Difficulty.VETERANO:
			default_prep_time *= 0.8
	
	prep_timer = default_prep_time
	is_in_prep_phase = true

# Gera ondas para fases cujo JSON só define nome/quantidade (mundos 2 a 6).
# Ritmo "serrote": cada mundo começa um pouco mais leve que o fim do anterior.
func _generate_waves(stage: int, count: int) -> Array:
	var in_world = ((stage - 1) % 10) + 1 # 1..9
	var world = int((stage - 1) / 10) + 1
	var waves: Array = []
	for w in range(1, count + 1):
		var groups: Array = []
		var base = 4 + in_world + w * 2 + world
		groups.append({"type": "misty_runner", "count": base, "interval": maxf(0.5, 1.2 - world * 0.08), "spawn_point": "east" if w % 2 == 1 else "north"})
		if in_world >= 2 or world >= 2:
			groups.append({"type": "misty_squire", "count": 1 + int((in_world + w) / 3), "interval": 1.6, "spawn_point": "north"})
		if in_world >= 4 or world >= 2:
			groups.append({"type": "misty_archer", "count": 1 + int(w / 2), "interval": 1.8, "spawn_point": "east"})
		if world >= 2 or in_world >= 7:
			groups.append({"type": "misty_crow", "count": int(w / 2) + 1, "interval": 1.4, "spawn_point": "north"})
		if in_world == 9 and w == count:
			groups.append({"type": "misty_giant", "count": 1 + int(world / 3), "interval": 3.0, "spawn_point": "east"})
		waves.append({"wave_index": w, "enemies": groups})
	return waves

func _process(delta: float) -> void:
	if GameState.is_game_over or finished:
		return
	if is_in_prep_phase and not tutorial_hold:
		prep_timer -= delta
		wave_countdown_updated.emit(prep_timer)
		if prep_timer <= 0.0:
			_start_next_wave()

func _start_next_wave() -> void:
	is_in_prep_phase = false
	current_wave_idx += 1
	GameState.wave_started.emit(current_wave_idx, total_waves)
	var wave_info: Dictionary = wave_data[current_wave_idx - 1]
	for group in wave_info.get("enemies", []):
		_spawn_group_routine(str(group.get("type", "misty_runner")), int(group.get("count", 4)), float(group.get("interval", 1.2)), str(group.get("spawn_point", "east")))

func _spawn_group_routine(e_type: String, count: int, interval: float, pt_key: String) -> void:
	pending_spawns += count
	for i in range(count):
		get_tree().create_timer(i * interval).timeout.connect(func():
			if is_instance_valid(self) and not GameState.is_game_over:
				_spawn_single_enemy(e_type, pt_key)
		)

func _spawn_single_enemy(e_type: String, pt_key: String) -> void:
	pending_spawns = maxi(0, pending_spawns - 1)
	var enemy = ENEMY_SCENE.instantiate()
	# Os atributos precisam ser definidos ANTES de entrar na árvore (o _ready calcula a vida)
	var st: Dictionary = enemy_stats.get(e_type, {})
	enemy.enemy_id = e_type
	enemy.base_hp = int(st.get("hp", enemy.base_hp))
	enemy.move_speed = float(st.get("speed", enemy.move_speed))
	enemy.damage = int(st.get("damage", enemy.damage))
	enemy.attack_range = float(st.get("attack_range", enemy.attack_range))
	enemy.attack_rate = float(st.get("attack_rate", enemy.attack_rate))
	enemy.coin_drop_count = int(st.get("coin_drop", enemy.coin_drop_count))
	enemy.is_flying = bool(st.get("is_flying", false))
	
	get_parent().add_child(enemy)
	var look: Dictionary = ENEMY_LOOKS.get(e_type, ENEMY_LOOKS["misty_runner"])
	enemy.apply_look(float(look["scale"]), look["tint"])
	
	var spawn_pos = Vector3(16.0, 0, randf_range(-4.0, 4.0))
	if spawn_markers.has(pt_key) and is_instance_valid(spawn_markers[pt_key]):
		spawn_pos = spawn_markers[pt_key].global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	if enemy.is_flying:
		spawn_pos.y = 1.6
	enemy.global_position = spawn_pos
	active_enemies_count += 1
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Node3D) -> void:
	active_enemies_count = maxi(0, active_enemies_count - 1)
	# CORREÇÃO: só encerra a onda quando ninguém está vivo E ninguém falta nascer
	if active_enemies_count > 0 or pending_spawns > 0:
		return
	if current_wave_idx < total_waves:
		GameState.wave_completed.emit(current_wave_idx)
		is_in_prep_phase = true
		prep_timer = default_prep_time
	elif not finished:
		finished = true
		all_waves_spawned.emit()
