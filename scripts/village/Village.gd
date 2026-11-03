extends Node3D

# Village.gd - Controlador da Vila Real Isométrica
# Conecta os edifícios, música relaxante e navegação do Rei

@onready var king: CharacterBody3D = $King
@onready var mill: Area3D = $Buildings/Mill
@onready var hud: CanvasLayer = $VillageHUD

func _ready() -> void:
	# Garante que o estado de fim de jogo seja resetado para o rei poder se mover livremente
	GameState.is_stage_active = false
	GameState.is_game_over = false
	GameState.is_paused = false
	
	AudioManager.play_music("village")

	# Cenário decorativo (castelo de fundo, árvores e postes); não afeta a jogabilidade
	var decor := Node3D.new()
	decor.set_script(load("res://scripts/village/VillageDecor.gd"))
	add_child(decor)
