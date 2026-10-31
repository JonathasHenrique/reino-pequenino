extends Node2D

# Challenge30_Breakout.gd - Desafio 30: Escudo e Bola (Quebra-Blocos de Luz)
# Escudo móvel na base, bola radiante destrói blocos cinzentos, 3 vidas

@export var paddle_speed: float = 650.0
var lives: int = 3
var ball_speed: float = 460.0
var ball_dir: Vector2 = Vector2(0.6, -0.8).normalized()
var is_ball_active: bool = false
var game_finished: bool = false
var total_blocks: int = 0
var destroyed_blocks: int = 0

@onready var paddle: CharacterBody2D = $Paddle
@onready var ball: Area2D = $Ball
@onready var blocks_container: Node2D = $Blocks
@onready var lives_label: Label = $UI/LivesLabel
@onready var victory_ui: CanvasLayer = $VictoryUI

func _ready() -> void:
	AudioManager.play_music("battle")
	_generate_blocks()
	_reset_ball()
	_update_lives_label()

func _generate_blocks() -> void:
	var rows = 4
	var cols = 8
	var start_x = 220
	var start_y = 120
	var block_w = 100
	var block_h = 35
	
	for r in range(rows):
		for c in range(cols):
			var b = Area2D.new()
			b.add_to_group("breakout_blocks")
			b.position = Vector2(start_x + c * (block_w + 10), start_y + r * (block_h + 10))
			
			var col = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(block_w, block_h)
			col.shape = shape
			b.add_child(col)
			
			var rect = ColorRect.new()
			rect.size = Vector2(block_w, block_h)
			rect.position = -Vector2(block_w * 0.5, block_h * 0.5)
			# Cores alternadas em tons suaves de mel e cinza
			rect.color = Color(0.9, 0.75, 0.3) if r % 2 == 0 else Color(0.48, 0.52, 0.6)
			b.add_child(rect)
			
			blocks_container.add_child(b)
			total_blocks += 1

func _reset_ball() -> void:
	is_ball_active = false
	ball.position = paddle.position + Vector2(0, -25)
	ball_dir = Vector2(randf_range(-0.5, 0.5), -1.0).normalized()

func _input(event: InputEvent) -> void:
	if game_finished:
		return
		
	if not is_ball_active and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if event.pressed:
			is_ball_active = true
			
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		paddle.position.x = clampf(event.position.x, 100, 1180)
		if not is_ball_active:
			ball.position.x = paddle.position.x

func _process(delta: float) -> void:
	if game_finished:
		return
		
	# Teclas direcionais PC
	var move_x = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_x += 1.0
	if move_x != 0.0:
		paddle.position.x = clampf(paddle.position.x + move_x * paddle_speed * delta, 100, 1180)
		if not is_ball_active:
			ball.position.x = paddle.position.x
			
	if is_ball_active:
		ball.position += ball_dir * ball_speed * delta
		_handle_ball_collisions()

func _handle_ball_collisions() -> void:
	var r = 12.0
	# Paredes
	if ball.position.x <= r:
		ball.position.x = r
		ball_dir.x *= -1
		AudioManager.play_sfx("button_click")
	elif ball.position.x >= 1280 - r:
		ball.position.x = 1280 - r
		ball_dir.x *= -1
		AudioManager.play_sfx("button_click")
		
	if ball.position.y <= r:
		ball.position.y = r
		ball_dir.y *= -1
		AudioManager.play_sfx("button_click")
	elif ball.position.y >= 740:
		# Bola caiu
		_on_ball_lost()
		return
		
	# Colisão com o Escudo (Paddle)
	var p_rect = Rect2(paddle.position.x - 70, paddle.position.y - 15, 140, 30)
	if p_rect.has_point(ball.position):
		ball_dir.y = -abs(ball_dir.y)
		var hit_offset = (ball.position.x - paddle.position.x) / 70.0
		ball_dir.x = hit_offset * 1.2
		ball_dir = ball_dir.normalized()
		AudioManager.play_sfx("button_click")
		
	# Colisão com os Blocos
	for b in blocks_container.get_children():
		var b_rect = Rect2(b.position.x - 50, b.position.y - 17.5, 100, 35)
		if b_rect.has_point(ball.position):
			b.queue_free()
			ball_dir.y *= -1
			destroyed_blocks += 1
			AudioManager.play_sfx("hit")
			if destroyed_blocks >= total_blocks:
				_trigger_victory()
			break

func _on_ball_lost() -> void:
	lives -= 1
	AudioManager.play_sfx("king_hit")
	_update_lives_label()
	
	if lives > 0:
		_reset_ball()
	else:
		game_finished = true
		get_tree().create_timer(1.5).timeout.connect(func(): get_tree().reload_current_scene())

func _update_lives_label() -> void:
	if lives_label:
		lives_label.text = "Vidas do Escudo: %d" % lives

func _trigger_victory() -> void:
	game_finished = true
	var stars = lives
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(30, {"won": true, "stars": stars})
	
	if victory_ui:
		victory_ui.show_victory(30, stars, "Capitã Rosa", 3)

