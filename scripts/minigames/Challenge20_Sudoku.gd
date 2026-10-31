extends Control

# Challenge20_Sudoku.gd - Desafio 20: Cofre dos Números (Sudoku Autoral)
# Grade 4x4 com números mágicos, 3 dicas (nenhuma no modo Veterano) e sem limite de tempo

var grid_size: int = 4
var hints_remaining: int = 3
var selected_row: int = -1
var selected_col: int = -1

# Quebra-cabeça 4x4 com solução válida única
var solution: Array = [
	[1, 2, 3, 4],
	[3, 4, 1, 2],
	[2, 1, 4, 3],
	[4, 3, 2, 1]
]

var player_grid: Array = []
var locked_cells: Array = [] # Células originais fixas

@onready var grid_container: GridContainer = $CenterContainer/Panel/VBox/GridContainer
@onready var hint_button: Button = $CenterContainer/Panel/VBox/HBoxHints/HintButton
@onready var hints_label: Label = $CenterContainer/Panel/VBox/HBoxHints/HintsLabel
@onready var num_buttons_container: HBoxContainer = $CenterContainer/Panel/VBox/NumberPad
@onready var victory_ui: CanvasLayer = $VictoryUI

func _ready() -> void:
	if Settings.difficulty == Settings.Difficulty.VETERANO:
		hints_remaining = 0
	else:
		hints_remaining = 3
		
	_init_grid()
	_update_hints_label()
	_setup_number_pad()
	AudioManager.play_music("village")

func _init_grid() -> void:
	player_grid = [
		[1, 0, 3, 0],
		[0, 4, 0, 2],
		[2, 0, 4, 0],
		[0, 3, 0, 1]
	]
	
	locked_cells = [
		[true, false, true, false],
		[false, true, false, true],
		[true, false, true, false],
		[false, true, false, true]
	]
	
	_render_cells()

func _render_cells() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	grid_container.columns = grid_size
	
	for r in range(grid_size):
		for c in range(grid_size):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(70, 70)
			var val = player_grid[r][c]
			btn.text = str(val) if val > 0 else ""
			btn.theme_override_font_sizes/font_size = 28
			
			if locked_cells[r][c]:
				btn.modulate = Color(0.7, 0.85, 1.0)
			else:
				btn.modulate = Color(1.0, 0.95, 0.7)
				
			btn.pressed.connect(_on_cell_clicked.bind(r, c))
			grid_container.add_child(btn)

func _setup_number_pad() -> void:
	if hint_button:
		hint_button.pressed.connect(_on_hint_pressed)
		
	for i in range(1, 5):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 50)
		btn.text = str(i)
		btn.theme_override_font_sizes/font_size = 24
		btn.pressed.connect(_on_number_selected.bind(i))
		num_buttons_container.add_child(btn)
		
	var clear_btn = Button.new()
	clear_btn.custom_minimum_size = Vector2(60, 50)
	clear_btn.text = "🗑️"
	clear_btn.pressed.connect(_on_number_selected.bind(0))
	num_buttons_container.add_child(clear_btn)

func _on_cell_clicked(r: int, c: int) -> void:
	if locked_cells[r][c]:
		return
	selected_row = r
	selected_col = c
	AudioManager.play_sfx("button_click")

func _on_number_selected(val: int) -> void:
	if selected_row != -1 and selected_col != -1 and not locked_cells[selected_row][selected_col]:
		player_grid[selected_row][selected_col] = val
		AudioManager.play_sfx("button_click")
		_render_cells()
		_check_solution()

func _on_hint_pressed() -> void:
	if hints_remaining <= 0:
		return
		
	# Preenche a primeira célula vazia com o valor correto
	for r in range(grid_size):
		for c in range(grid_size):
			if player_grid[r][c] != solution[r][c]:
				player_grid[r][c] = solution[r][c]
				hints_remaining -= 1
				AudioManager.play_sfx("coin_pickup")
				_update_hints_label()
				_render_cells()
				_check_solution()
				return

func _update_hints_label() -> void:
	if hints_label:
		hints_label.text = "Dicas Mágicas: %d" % hints_remaining
	if hint_button:
		hint_button.disabled = (hints_remaining <= 0)

func _check_solution() -> void:
	for r in range(grid_size):
		for c in range(grid_size):
			if player_grid[r][c] != solution[r][c]:
				return
				
	# Solução concluída!
	var stars = 3 if hints_remaining >= 2 else (2 if hints_remaining >= 1 else 1)
	AudioManager.play_sfx("stage_victory")
	MiniGameRunner.complete_challenge(20, {"won": true, "stars": stars})
	
	if victory_ui:
		victory_ui.show_victory(20, stars, "Mago Fidélio", 2)
