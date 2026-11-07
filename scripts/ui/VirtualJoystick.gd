extends Control

# VirtualJoystick.gd - Joystick virtual dinâmico para telas sensíveis ao toque
# Projetado para jogabilidade confortável com uma única mão no Android

signal joystick_updated(direction: Vector2)

@export var max_radius: float = 65.0
@export var deadzone: float = 0.12

var touch_id: int = -1
var center_pos: Vector2
var current_pos: Vector2
var is_dragging: bool = false
var output_direction: Vector2 = Vector2.ZERO

@onready var base_circle: Control = $Base
@onready var knob: Control = $Base/Knob

func _ready() -> void:
	center_pos = base_circle.position + (base_circle.size * 0.5)
	current_pos = center_pos
	visibility_changed.connect(func():
		if not visible:
			_reset_joystick()
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_joystick()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			# Ativa o joystick na metade esquerda da tela para facilitar uma mão só
			if event.position.x < get_viewport_rect().size.x * 0.6:
				touch_id = event.index
				is_dragging = true
				center_pos = event.position
				current_pos = event.position
				base_circle.global_position = center_pos - (base_circle.size * 0.5)
				_update_knob_position()
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
			
	elif event is InputEventScreenDrag and event.index == touch_id:
		current_pos = event.position
		_update_knob_position()
		
	elif event is InputEventMouseButton:
		# Suporte a mouse para testes no PC
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				touch_id = 999
				is_dragging = true
				center_pos = event.position
				current_pos = event.position
				base_circle.global_position = center_pos - (base_circle.size * 0.5)
				_update_knob_position()
			elif not event.pressed and touch_id == 999:
				_reset_joystick()
				
	elif event is InputEventMouseMotion and touch_id == 999:
		current_pos = event.position
		_update_knob_position()

func _process(_delta: float) -> void:
	# Pausa/fim de jogo: solta o direcional para o Rei não continuar andando sozinho.
	if GameState.is_paused or GameState.is_game_over:
		if is_dragging or output_direction != Vector2.ZERO:
			_reset_joystick()
		return
	# Fallback para teclas direcionais no PC (WASD / Setas)
	if not is_dragging:
		var key_dir = Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			key_dir.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			key_dir.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			key_dir.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			key_dir.x += 1.0
			
		if key_dir != Vector2.ZERO:
			output_direction = key_dir.normalized()
			joystick_updated.emit(output_direction)
		elif output_direction != Vector2.ZERO:
			output_direction = Vector2.ZERO
			joystick_updated.emit(output_direction)

func _update_knob_position() -> void:
	var offset = current_pos - center_pos
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
		
	var norm = offset / max_radius
	if norm.length() < deadzone:
		output_direction = Vector2.ZERO
	else:
		output_direction = norm
		
	knob.position = (base_circle.size * 0.5) + offset - (knob.size * 0.5)
	joystick_updated.emit(output_direction)

func _reset_joystick() -> void:
	touch_id = -1
	is_dragging = false
	output_direction = Vector2.ZERO
	knob.position = (base_circle.size * 0.5) - (knob.size * 0.5)
	joystick_updated.emit(output_direction)

