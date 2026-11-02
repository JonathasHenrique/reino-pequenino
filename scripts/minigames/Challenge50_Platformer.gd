extends Node2D

# Challenge50_Platformer.gd - Desafio 50: A Corrida de Biscoito
# Plataforma 2D clássica com o pônei Biscoito: correr, pular, pular em Brumosos e alcançar a bandeira real

@export var move_speed: float = 320.0
@export var jump_velocity: float = -580.0
var gravity: float = 1400.0
var hearts: int = 3
var coins_collected: int = 0
var game_finished: bool = false
var jump_requested: bool = false

@onready var biscoito: CharacterBody2D = $Biscoito
@onready var flag_area: Area2D = $Flag
@onready var hud_hearts: Label = $UI/HeartsLabel
@onready var hud_coins: Label = $UI/CoinsLabel
@onready var victory_ui: CanvasLayer = $VictoryUI
@onready var jump_button: Button = $UI/JumpButton

func _ready() -> void:
	AudioManager.play_music("battle")
	_update_hud()
	if flag_area:
		flag_area.body_entered.connect(_on_flag_reached)
	if jump_button:
		jump_button.pressed.connect(jump_button_pressed)

func _input(event: InputEvent) -> void:
	if game_finished or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_SPACE, KEY_W, KEY_UP]:
		jump_requested = true

func _physics_process(delta: float) -> void:
	if game_finished or not is_instance_valid(biscoito):
		return
		
	# Gravidade
	if not biscoito.is_on_floor():
		biscoito.velocity.y += gravity * delta
		
	# Entrada direcional (teclas PC e botões touch)
	var move_x = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_x += 1.0
		
	biscoito.velocity.x = move_x * move_speed
	
	if jump_requested and biscoito.is_on_floor():
		biscoito.velocity.y = jump_velocity
		AudioManager.play_sfx("button_click")
	jump_requested = false
			
	biscoito.move_and_slide()
	
	# Verifica queda do cenário
	if biscoito.position.y > 800:
		_take_damage()

func jump_button_pressed() -> void:
	if biscoito and not game_finished:
		jump_requested = true

func _take_damage() -> void:
	hearts -= 1
	AudioManager.play_sfx("king_hit")
	_update_hud()
	
	if hearts > 0:
		biscoito.position = Vector2(100, 500)
		biscoito.velocity = Vector2.ZERO
	else:
		game_finished = true
		get_tree().create_timer(1.5).timeout.connect(func(): get_tree().reload_current_scene())

func _on_flag_reached(body: Node2D) -> void:
	if body == biscoito and not game_finished:
		_trigger_victory()

func _trigger_victory() -> void:
	game_finished = true
	var stars = hearts
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(50, {"won": true, "stars": stars})
	
	if victory_ui:
		victory_ui.show_victory(50, stars, "Bento, o Urso", 5)

func _update_hud() -> void:
	if hud_hearts:
		hud_hearts.text = "❤️ " + str(hearts)
	if hud_coins:
		hud_coins.text = "🪙 " + str(coins_collected)

