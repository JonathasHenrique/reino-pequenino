extends Node3D

# Village.gd - Controlador da Vila Real Isométrica
# Conecta os edifícios, música relaxante e navegação do Rei

@onready var king: CharacterBody3D = $King
@onready var mill: Area3D = $Buildings/Mill
@onready var hud: CanvasLayer = $VillageHUD

func _ready() -> void:
	GameState.is_stage_active = false
	AudioManager.play_music("village")

