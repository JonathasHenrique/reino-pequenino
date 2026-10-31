extends Node

# WaveManager.gd - Gerenciador de Ondas de Inimigos Orientado a Dados
# Controla o tempo de preparação, contagem de hordas e invocação de inimigos

signal wave_countdown_updated(seconds_left: float)
signal all_waves_spawned()

@export var stage_id: int = 1
@export var default_prep_time: float = 8.0

var total_waves: int = 2
var current_wave_idx: int = 0
var wave_data: Array = []
var is_in_prep_phase: bool = true
var prep_timer: float = 0.0

var active_enemies_count: int = 0
var spawn_markers: Dictionary = {}

func _ready() -> void:
	_load_wave_data()

func setup_spawn_points(markers: Dictionary) -> void:
	spawn_markers = markers

func _load_wave_data() -> void:
	var path = "res://data/waves/world1_waves.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var key = "stage_" + str(stage_id)
				if json.data.has(key):
					var s_data = json.data[key]
					total_waves = int(s_data.get("total_waves", 2))
					default_prep_time = float(s_data.get("prep_time_seconds", 8.0))
					wave_data = s_data.get("waves", [])
	
	prep_timer = default_prep_time
	is_in_prep_phase = true

func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
		
	if is_in_prep_phase:
		prep_timer -= delta
		wave_countdown_updated.emit(prep_timer)
		if prep_timer <= 0.0:
			_start_next_wave()

func _start_next_wave() -> void:
	is_in_prep_phase = false
	current_wave_idx += 1
	GameState.wave_started.emit(current_wave_idx, total_waves)
	
	if current_wave_idx <= wave_data.size():
		var wave_info = wave_data[current_wave_idx - 1]
		_execute_wave_spawns(wave_info)
	else:
		# Fallback se não houver JSON específico para a fase
		_execute_fallback_wave(current_wave_idx)

func _execute_wave_spawns(wave_info: Dictionary) -> void:
	var enemy_groups = wave_info.get("enemies", [])
	for group in enemy_groups:
		var e_type = group.get("type", "misty_runner")
		var count = int(group.get("count", 4))
		var interval = float(group.get("interval", 1.2))
		var pt_key = group.get("spawn_point", "east")
		_spawn_group_routine(e_type, count, interval, pt_key)

func _spawn_group_routine(e_type: String, count: int, interval: float, pt_key: String) -> void:
	for i in range(count):
		get_tree().create_timer(i * interval).timeout.connect(func():
			if is_instance_valid(self) and not GameState.is_game_over:
				_spawn_single_enemy(e_type, pt_key)
		)

func _spawn_single_enemy(e_type: String, pt_key: String) -> void:
	var scene_path = "res://scenes/entities/MistyRunner.tscn"
	var enemy_scene = load(scene_path)
	if not enemy_scene:
		return
		
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	
	var spawn_pos = Vector3(16.0, 0, randf_range(-4.0, 4.0))
	if spawn_markers.has(pt_key) and is_instance_valid(spawn_markers[pt_key]):
		spawn_pos = spawn_markers[pt_key].global_position + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
		
	enemy.global_position = spawn_pos
	active_enemies_count += 1
	enemy.died.connect(_on_enemy_died)

func _execute_fallback_wave(w_idx: int) -> void:
	var count = 4 + w_idx * 3
	for i in range(count):
		get_tree().create_timer(i * 1.0).timeout.connect(func():
			if is_instance_valid(self) and not GameState.is_game_over:
				_spawn_single_enemy("misty_runner", "east")
		)

func _on_enemy_died(_enemy: Node3D) -> void:
	active_enemies_count = maxi(0, active_enemies_count - 1)
	if active_enemies_count == 0 and current_wave_idx < total_waves:
		# Próxima onda após intervalo
		GameState.wave_completed.emit(current_wave_idx)
		is_in_prep_phase = true
		prep_timer = default_prep_time
	elif active_enemies_count == 0 and current_wave_idx >= total_waves:
		all_waves_spawned.emit()
