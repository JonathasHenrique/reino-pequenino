extends Node2D

# Challenge10_Catapult.gd - Desafio 10: A Catapulta do Vale
# Mecânica suculenta de estilingue/catapulta física 2D autoral,
# com elástico duplo que estica, mira parabólica tracejada,
# física potente de destruição e câmera com tremor de impacto!

@export var max_attempts: int = 4
var attempts_left: int = 4
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_current: Vector2 = Vector2.ZERO
var max_pull_distance: float = 140.0
var launch_speed_multiplier: float = 12.5 # Garante impacto forte e veloz (até 1750 px/s)

var projectile_instance: RigidBody2D = null
var is_projectile_in_flight: bool = false
var game_finished: bool = false

@onready var anchor_left: Vector2 = Vector2(200, 480)
@onready var anchor_right: Vector2 = Vector2(250, 475)
@onready var anchor_center: Vector2 = Vector2(225, 485)

@onready var line_back: Line2D = $CatapultFrame/BandBack
@onready var line_front: Line2D = $CatapultFrame/BandFront
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var attempts_label: Label = $UI/TopBar/HBox/AttemptsLabel
@onready var target_totem: RigidBody2D = $Targets/TargetTotem
@onready var victory_panel: CanvasLayer = $VictoryUI
@onready var camera: Camera2D = $Camera2D

var camera_shake_intensity: float = 0.0

func _ready() -> void:
	attempts_left = max_attempts
	if Settings.difficulty == Settings.Difficulty.TRANQUILO:
		attempts_left = 5
	elif Settings.difficulty == Settings.Difficulty.VETERANO:
		attempts_left = 3
		
	_update_attempts_ui()
	AudioManager.play_music("battle")
	_update_slingshot_bands(anchor_center)
	_spawn_ready_projectile()

func _process(delta: float) -> void:
	if camera_shake_intensity > 0.0:
		camera_shake_intensity = maxf(0.0, camera_shake_intensity - delta * 15.0)
		if camera:
			camera.offset = Vector2(
				randf_range(-camera_shake_intensity, camera_shake_intensity),
				randf_range(-camera_shake_intensity, camera_shake_intensity)
			)
			
	if not game_finished and is_projectile_in_flight:
		_check_objective()

func shake_camera(amount: float = 10.0) -> void:
	camera_shake_intensity = amount

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
	projectile_instance.global_position = anchor_center
	_update_slingshot_bands(anchor_center)

func _update_slingshot_bands(pouch_pos: Vector2) -> void:
	if line_back:
		line_back.clear_points()
		line_back.add_point(anchor_left)
		line_back.add_point(pouch_pos)
	if line_front:
		line_front.clear_points()
		line_front.add_point(pouch_pos)
		line_front.add_point(anchor_right)

func _input(event: InputEvent) -> void:
	if game_finished or is_projectile_in_flight or attempts_left <= 0:
		return
		
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			var touch_pos = event.position
			# Permite toque em qualquer lugar da área do estilingue (lado esquerdo)
			if touch_pos.x < 420.0 and touch_pos.y > 300.0:
				is_dragging = true
				drag_start = anchor_center
				drag_current = touch_pos
				_update_aim()
		else:
			if is_dragging:
				is_dragging = false
				_launch_projectile()
				
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and is_dragging):
		drag_current = event.position
		_update_aim()

func _update_aim() -> void:
	if not is_dragging:
		trajectory_line.clear_points()
		_update_slingshot_bands(anchor_center)
		return
		
	var pull_vector = drag_current - drag_start
	if pull_vector.length() > max_pull_distance:
		pull_vector = pull_vector.normalized() * max_pull_distance
		
	var pouch_pos = drag_start + pull_vector
	if projectile_instance:
		projectile_instance.global_position = pouch_pos
	_update_slingshot_bands(pouch_pos)
		
	# Trajetória parabólica tracejada
	trajectory_line.clear_points()
	var launch_vel = -pull_vector * launch_speed_multiplier
	var sim_pos = pouch_pos
	var gravity = Vector2(0, 980) # Gravidade padrão do Godot 2D
	var time_step = 0.04
	
	for i in range(22):
		var t = i * time_step
		var pt = sim_pos + (launch_vel * t) + (0.5 * gravity * t * t)
		if pt.y > 640.0:
			trajectory_line.add_point(pt)
			break
		trajectory_line.add_point(pt)

func _launch_projectile() -> void:
	trajectory_line.clear_points()
	var pull_vector = projectile_instance.global_position - drag_start
	if pull_vector.length() < 20.0:
		# Puxão insignificante, volta para a posição de repouso
		projectile_instance.global_position = anchor_center
		_update_slingshot_bands(anchor_center)
		return
		
	is_projectile_in_flight = true
	attempts_left -= 1
	_update_attempts_ui()
	
	AudioManager.play_sfx("shoot")
	
	# Efeito de estalo do elástico
	_update_slingshot_bands(anchor_center + Vector2(25, -15))
	get_tree().create_timer(0.08).timeout.connect(func(): _update_slingshot_bands(anchor_center))
	
	# Lança com velocidade direta sem falhas de integração
	var launch_vel = -pull_vector * launch_speed_multiplier
	projectile_instance.freeze = false
	projectile_instance.linear_velocity = launch_vel
	projectile_instance.angular_velocity = randf_range(-10.0, 10.0)
	
	# Registra colisão para tremor de câmera
	projectile_instance.body_entered.connect(_on_rock_impact)
	
	# Ciclo de espera para impacto
	get_tree().create_timer(3.5).timeout.connect(_on_projectile_cycle_complete)

func _on_rock_impact(body: Node) -> void:
	shake_camera(12.0)
	AudioManager.play_sfx("hit")

func _on_projectile_cycle_complete() -> void:
	if game_finished:
		return
		
	is_projectile_in_flight = false
	if projectile_instance and is_instance_valid(projectile_instance):
		projectile_instance.queue_free()
		projectile_instance = null
		
	_check_objective()
	
	if not game_finished:
		if attempts_left > 0:
			_spawn_ready_projectile()
		else:
			_trigger_defeat()

func _check_objective() -> void:
	if not target_totem or not is_instance_valid(target_totem):
		_trigger_victory()
		return
		
	# O totem é considerado derrubado se inclinou > 28 graus ou caiu abaixo da plataforma (Y > 580)
	var angle_deg = abs(rad_to_deg(target_totem.rotation))
	if angle_deg > 28.0 or target_totem.global_position.y > 580.0 or target_totem.global_position.x > 1150.0:
		_trigger_victory()

func _trigger_victory() -> void:
	if game_finished:
		return
	game_finished = true
	shake_camera(16.0)
	
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
	get_tree().create_timer(2.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)
