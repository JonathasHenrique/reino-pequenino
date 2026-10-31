extends Node3D

# Village.gd - Controlador da Vila Real Isométrica
# Conecta os edifícios, música relaxante e navegação do Rei

@onready var king: CharacterBody3D = $King
@onready var mill: Area3D = $Buildings/Mill
@onready var hud: CanvasLayer = $VillageHUD
@onready var joystick: Control = $VirtualJoystick

func _ready() -> void:
	# Garante que o estado de fim de jogo seja resetado para o rei poder se mover
	GameState.is_stage_active = false
	GameState.is_game_over = false
	GameState.is_paused = false
	
	AudioManager.play_music("village")
	
	# Conecta o joystick virtual ao Rei Teodoro na Vila
	if joystick and king:
		joystick.joystick_updated.connect(king.set_input_direction)


