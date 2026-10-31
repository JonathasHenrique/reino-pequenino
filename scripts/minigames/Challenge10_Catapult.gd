extends Node2D

# Challenge10_Catapult.gd - Desafio 10: A Catapulta do Vale
# Módulo de física 2D autoral: arrastar e lançar pedregulhos para derrubar a torre de blocos cinzentos

@export var max_attempts: int = 4
var attempts_left: int = 4
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_current: Vector2 = Vector2.ZERO
var max_pull_distance: float = 120.0
var launch_impulse_multiplier: float = 14.0

var projectile_instance: RigidBody2D = null
var is_projectile_in_flight: bool = false
var game_finished: bool = false

@onready var catapult_anchor: Marker2D = $CatapultAnchor
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var attempts_label: Label = $UI/AttemptsLabel
@onready var target_totem: RigidBody2D = $Targets/TargetTotem
@onready var victory_panel: CanvasLayer = $VictoryUI

func _ready() -> void:
	attempts_left = max_attempts
	if Settings.difficulty == Settings.Difficulty.TRANQUILO:
		attempts_left = 5
	elif Settings.difficulty == Settings.Difficulty.VETERANO:
		attempts_left = 3
		
	_update_attempts_ui()
	AudioManager.play_music("battle")
	_spawn_ready_projectile()

func _update_attempts_ui() -> void:
	if attempts_label:
		attempts_label.text = "Pedregulhos Restantes: %d" % attempts_left

func _spawn_ready_projectile() -> void:
	if game_finished:
		return
		
	var proj_scene = load("res://scenes/minigames/CatapultRock.tscn")
	if not proj_scene:
		return
		
	projectile_instance = proj_scene.instantiate()
	add_child(projectile_instance)
	projectile_instance.freeze = true
	projectile_instance.global_position = catapult_anchor.global_position

func _input(event: InputEvent) -> void:
	if game_finished or is_projectile_in_flight or attempts_left <= 0:
		return
		
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			var touch_pos = event.position
			if touch_pos.distance_to(catapult_anchor.global_position) < 140.0:
				is_dragging = true
				drag_start = catapult_anchor.global_position
				drag_current = touch_pos
				_update_trajectory()
		else:
			if is_dragging:
				is_dragging = false
				_launch_projectile()
				
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and is_dragging):
		drag_current = event.position
		_update_trajectory()

func _update_trajectory() -> void:
	if not is_dragging:
		trajectory_line.clear_points()
		return
		
	var pull_vector = drag_current - drag_start
	if pull_vector.length() > max_pull_distance:
		pull_vector = pull_vector.normalized() * max_pull_distance
		
	if projectile_instance:
		projectile_instance.global_position = drag_start + pull_vector
		
	# Traça a linha de mira
	trajectory_line.clear_points()
	var launch_vel = -pull_vector * launch_impulse_multiplier
	var sim_pos = drag_start + pull_vector
	var gravity = Vector2(0, 980)
	var time_step = 0.05
	
	for i in range(16):
		var t = i * time_step
		var pt = sim_pos + (launch_vel * t) + (0.5 * gravity * t * t)
		trajectory_line.add_point(pt)

func _launch_projectile() -> void:
	trajectory_line.clear_points()
	var pull_vector = projectile_instance.global_position - drag_start
	if pull_vector.length() < 15.0:
		# Puxão muito curto, cancela
		projectile_instance.global_position = drag_start
		return
		
	is_projectile_in_flight = true
	attempts_left -= 1
	_update_attempts_ui()
	
	AudioManager.play_sfx("shoot")
	var impulse = -pull_vector * launch_impulse_multiplier
	projectile_instance.freeze = false
	projectile_instance.apply_central_impulse(impulse)
	
	# Tempo para impacto ou reciclagem do tiro
	get_tree().create_timer(3.2).timeout.connect(_on_projectile_cycle_complete)

func _on_projectile_cycle_complete() -> void:
	if game_finished:
		return
		
	is_projectile_in_flight = false
	if projectile_instance and is_instance_valid(projectile_instance):
		projectile_instance.queue_free()
		projectile_instance = null
		
	# Verifica se o Totem Alvo tombou (ângulo ou altura)
	_check_objective()
	
	if not game_finished:
		if attempts_left > 0:
			_spawn_ready_projectile()
		else:
			# Derrota no desafio
			_trigger_defeat()

func _check_objective() -> void:
	if not target_totem or not is_instance_valid(target_totem):
		_trigger_victory()
		return
		
	# O totem é considerado derrubado se girou mais de 45 graus ou caiu abaixo de certo Y
	var angle_deg = abs(rad_to_deg(target_totem.rotation))
	if angle_deg > 35.0 or target_totem.global_position.y > 620.0 or target_totem.global_position.x > 1200.0:
		_trigger_victory()

func _trigger_victory() -> void:
	if game_finished:
		return
	game_finished = true
	
	var stars = 1
	if attempts_left >= 2:
		stars = 3
	elif attempts_left >= 1:
		stars = 2
		
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(10, {"won": true, "stars": stars})
	
	if victory_panel:
		victory_panel.show_victory(10, stars, "Marta, a Ferreira", 1)

func _trigger_defeat() -> void:
	game_finished = true
	AudioManager.play_sfx("stage_defeat")
	# Recarrega o minigame para nova tentativa
	get_tree().create_timer(2.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)
