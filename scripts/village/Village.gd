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

	# Cenário decorativo (castelo, casas de apoio, aldeões); não afeta a jogabilidade
	var decor := Node3D.new()
	decor.set_script(load("res://scripts/village/VillageDecor.gd"))
	add_child(decor)
	# O Rei sai do castelo e a câmera começa enquadrando o castelo.
	king.global_position = decor.call("get_king_spawn")
	_play_castle_intro(decor)

func _play_castle_intro(decor: Node) -> void:
	var cam := get_node_or_null("IsometricCamera") as Camera3D
	if cam == null:
		return
	var center: Vector3 = decor.call("get_castle_center")
	cam.set("follow_enabled", false)
	cam.set("target_node", null)
	cam.global_position = center + Vector3(11.0, 15.0, 11.0)
	cam.look_at(center, Vector3.UP)
	Art.dust_puff(self, king.global_position, 12)
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree() or not is_instance_valid(cam):
		return
	cam.set("target_node", king)
	cam.set("follow_enabled", true)
