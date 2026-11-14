extends Node3D

# Village.gd - Controlador da Vila Real Isométrica
# Conecta os edifícios, música relaxante e navegação do Rei

@onready var king: CharacterBody3D = $King
@onready var mill: Area3D = $Buildings/Mill
@onready var hud: CanvasLayer = $VillageHUD

func _ready() -> void:
	var dir_light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if dir_light:
		dir_light.shadow_enabled = false
	var world_env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = false
		world_env.environment.ssao_enabled = false
		world_env.environment.ssr_enabled = false
		world_env.environment.volumetric_fog_enabled = false
	for m in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
	king.global_position = decor.call("get_king_gate")
	_play_castle_intro(decor)

func _play_castle_intro(decor: Node) -> void:
	var cam := get_node_or_null("IsometricCamera") as Camera3D
	if cam == null:
		return
	var center: Vector3 = decor.call("get_castle_center")
	var spawn: Vector3 = decor.call("get_king_spawn")
	cam.set("follow_enabled", false)
	cam.set("target_node", null)
	cam.global_position = center + Vector3(17.0, 21.0, 17.0)
	cam.look_at(center + Vector3(0.0, -1.0, 1.5), Vector3.UP)
	Art.dust_puff(self, king.global_position, 12)
	var walk := create_tween()
	walk.tween_property(king, "global_position", spawn, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree() or not is_instance_valid(cam):
		return
	cam.set("target_node", king)
	cam.set("follow_enabled", true)
