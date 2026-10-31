extends Control

# Challenge40_BlockPuzzle.gd - Desafio 40: A Muralha de Peças
# Grade 8x8 de encaixe autoral: arrastar peças poliominó; linhas e colunas completas pontuam e viram muralha

@export var target_score: int = 300
var current_score: int = 0
var grid_size: int = 8
var board: Array = [] # 8x8 booleanos
var game_finished: bool = false

@onready var grid_container: GridContainer = $CenterContainer/Panel/VBox/GridContainer
@onready var score_label: Label = $CenterContainer/Panel/VBox/ScoreLabel
@onready var pieces_container: HBoxContainer = $CenterContainer/Panel/VBox/PiecesContainer
@onready var victory_ui: CanvasLayer = $VictoryUI

# Definições de peças clássicas em matrizes 2D
var piece_templates: Array = [
	[[1, 1], [1, 1]],         # Quadrado 2x2
	[[1, 1, 1]],              # Linha 3
	[[1], [1], [1]],          # Coluna 3
	[[1, 0], [1, 1]],         # L miniatura
	[[1, 1, 1, 1]],           # Linha 4
	[[1]]                     # Ponto único
]

func _ready() -> void:
	_init_board()
	_update_score_ui()
	_spawn_piece_options()
	AudioManager.play_music("village")

func _init_board() -> void:
	board.clear()
	for r in range(grid_size):
		var row = []
		for c in range(grid_size):
			row.append(false)
		board.append(row)
		
	_render_board()

func _render_board() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	grid_container.columns = grid_size
	
	for r in range(grid_size):
		for c in range(grid_size):
			var cell = ColorRect.new()
			cell.custom_minimum_size = Vector2(42, 42)
			cell.color = Color(0.4, 0.7, 0.9) if board[r][c] else Color(0.18, 0.22, 0.28)
			grid_container.add_child(cell)

func _spawn_piece_options() -> void:
	for child in pieces_container.get_children():
		child.queue_free()
		
	for i in range(3):
		var template = piece_templates[randi() % piece_templates.size()]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 70)
		btn.text = "Peça %d" % (i + 1)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_piece_clicked.bind(template))
		pieces_container.add_child(btn)

func _on_piece_clicked(piece: Array) -> void:
	if game_finished:
		return
		
	# Tenta encaixar na primeira posição livre válida
	var placed = false
	for r in range(grid_size - piece.size() + 1):
		for c in range(grid_size - piece[0].size() + 1):
			if _can_place(piece, r, c):
				_place(piece, r, c)
				placed = true
				break
		if placed:
			break
			
	if placed:
		AudioManager.play_sfx("build")
		_clear_full_lines()
		_render_board()
		_update_score_ui()
		
		if current_score >= target_score:
			_trigger_victory()
		else:
			# Renova as opções
			_spawn_piece_options()
	else:
		AudioManager.play_sfx("button_click")

func _can_place(piece: Array, start_r: int, start_c: int) -> bool:
	for pr in range(piece.size()):
		for pc in range(piece[pr].size()):
			if piece[pr][pc] == 1:
				if board[start_r + pr][start_c + pc]:
					return false
	return true

func _place(piece: Array, start_r: int, start_c: int) -> void:
	for pr in range(piece.size()):
		for pc in range(piece[pr].size()):
			if piece[pr][pc] == 1:
				board[start_r + pr][start_c + pc] = true
	current_score += 15

func _clear_full_lines() -> void:
	var rows_to_clear = []
	for r in range(grid_size):
		if board[r].all(func(val): return val):
			rows_to_clear.append(r)
			
	for r in rows_to_clear:
		for c in range(grid_size):
			board[r][c] = false
		current_score += 60
		AudioManager.play_sfx("coin_pickup")

func _update_score_ui() -> void:
	if score_label:
		score_label.text = "Pontos da Muralha: %d / %d" % [current_score, target_score]

func _trigger_victory() -> void:
	game_finished = true
	var stars = 3
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(40, {"won": true, "stars": stars})
	
	if victory_ui:
		victory_ui.show_victory(40, stars, "Irmã Clara", 4)

