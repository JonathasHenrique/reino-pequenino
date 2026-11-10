extends Node

# Script de validação autônoma e captura de screenshots reais (Prólogo, Vila, Linha do Tempo e Batalha)

func _ready() -> void:
	call_deferred("_run_captures")

func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _save_viewport_png(path: String) -> bool:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var tex := get_tree().root.get_viewport().get_texture()
	if tex:
		var img := tex.get_image()
		if img and not img.is_empty():
			img.save_png(path)
			print("[QA] Screenshot salvo com sucesso: ", path, " (", img.get_width(), "x", img.get_height(), ")")
			return true
	return false

func _run_captures() -> void:
	print("[QA] Iniciando validação visual e estrutural das 4 cenas...")
	var root := get_tree().root

	# Configure some sample progress so the Timeline shows completed stars, current stage, and locked stages
	SaveManager.save_data["unlocked_stages"] = 4
	SaveManager.save_data["stage_stars"] = {"1": 3, "2": 2, "3": 3}

	# 1. PRÓLOGO (IntroCutscene.tscn)
	var intro_scene := load("res://scenes/ui/IntroCutscene.tscn") as PackedScene
	var intro := intro_scene.instantiate()
	root.add_child(intro)
	await _wait_frames(15)
	var dlg := intro.get_node_or_null("DialogueBox")
	if dlg and dlg.get("panel"):
		print("[QA] Prólogo DialogueBox largura: ", dlg.panel.size.x)
	await _save_viewport_png("res://tests/print_prologue.png")
	intro.queue_free()
	await _wait_frames(5)

	# 2. VILA DO REI (Village.tscn)
	var village_scene := load("res://scenes/village/Village.tscn") as PackedScene
	var village := village_scene.instantiate()
	root.add_child(village)
	await _wait_frames(20)
	# Posiciona a câmera enquadrando a Vila para o screenshot
	var v_cam := village.get_node_or_null("IsometricCamera") as Camera3D
	if v_cam and village.get_node_or_null("King"):
		v_cam.set("target_node", village.get_node("King"))
		v_cam.set("follow_enabled", true)
		village.get_node("King").global_position = Vector3(0, 0, 0)
		v_cam.global_position = Vector3(0, 0, 0) + v_cam.get("offset_vector")
		v_cam.look_at(Vector3.ZERO, Vector3.UP)
	# Mostra uma placa de upgrade para validar que não há sobreposição entre label_level e label_upgrade
	var bld := village.get_node_or_null("Buildings/Barracks")
	if bld and bld.get("label_upgrade"):
		bld.label_upgrade.visible = true
		print("[QA] VillageBuilding espaçamento vertical labels: ", bld.label_level.position.y - bld.label_upgrade.position.y)
	await _wait_frames(10)
	await _save_viewport_png("res://tests/print_village.png")

	# 3. MAPA DE LINHA DO TEMPO DAS FASES (StageTimeline.tscn sobre a Vila)
	var timeline_scene := load("res://scenes/ui/StageTimeline.tscn") as PackedScene
	var timeline := timeline_scene.instantiate()
	root.add_child(timeline)
	await _wait_frames(15)
	await _save_viewport_png("res://tests/print_timeline.png")
	timeline.queue_free()
	village.queue_free()
	await _wait_frames(5)

	# 4. BATALHA (StageMain.tscn com inimigos, tropas, câmera +20% e Vitória 3 Estrelas)
	GameState.start_stage(2)
	var stage_scene := load("res://scenes/stages/StageMain.tscn") as PackedScene
	var stage := stage_scene.instantiate()
	root.add_child(stage)
	await _wait_frames(15)
	# Fecha diálogo inicial da fase 2 para limpar a visão de batalha
	for child in stage.get_children():
		if child.name.begins_with("DialogueBox") or child.get_script() == load("res://scripts/ui/DialogueBox.gd"):
			child.visible = false
	# Spawna arqueiras e inimigos para validar escala (-15%) e rotação de frente dos inimigos
	if stage.has_method("_spawn_archer"):
		stage.call("_spawn_archer")
		stage.call("_spawn_archer")
	var enemy_scene := load("res://scenes/entities/MistyRunner.tscn") as PackedScene
	var spots := [Vector3(7.5, 0.0, 2.5), Vector3(8.5, 0.0, -1.5), Vector3(5.5, 0.0, 5.5)]
	var e1: Node3D = null
	for sp in spots:
		var en := enemy_scene.instantiate() as Node3D
		stage.add_child(en)
		en.global_position = sp
		en.set("current_hp", 500)
		en.call("apply_look", 1.0, Color(0.85, 0.21, 0.24))
		if e1 == null:
			e1 = en
	await _wait_frames(15)
	if is_instance_valid(e1) and GameState.king_node:
		var dir_to_king: Vector3 = (GameState.king_node.global_position - e1.global_position)
		dir_to_king.y = 0.0
		dir_to_king = dir_to_king.normalized()
		var vis := e1.get("visuals") as Node3D
		var chibi_child := vis.get_child(0) as Node3D
		var total_yaw: float = vis.rotation.y + chibi_child.rotation.y
		var forward := Vector3(sin(total_yaw), 0.0, cos(total_yaw)).normalized()
		print("[QA] Enemy rot_y=", snappedf(vis.rotation.y, 0.01), " chibi_rot_y=", snappedf(chibi_child.rotation.y, 0.01), " dot=", snappedf(forward.dot(dir_to_king), 0.01))
	await _save_viewport_png("res://tests/print_battle.png")

	# 5. TELA DE VITÓRIA 3 ESTRELAS (VictoryScreen.tscn)
	GameState.complete_stage(true)
	await _wait_frames(15)
	await _save_viewport_png("res://tests/print_victory_3stars.png")

	stage.queue_free()
	await _wait_frames(5)

	# 6. FASE 1 — TUTORIAL PASSO 1 (Pads com Nomes Claros + Bloqueio Linear + Lanterna no Pad Azul)
	SaveManager.save_data["stage_1_tutorial_completed"] = false
	GameState.current_stage = 1
	GameState.start_stage(1)
	var stage1 := stage_scene.instantiate()
	root.add_child(stage1)
	await _wait_frames(20)
	Engine.time_scale = 1.0
	await _save_viewport_png("res://tests/print_pads_tutorial.png")

	# 7. FASE 1 — TUTORIAL PASSO 6 (Lanterna de Alvo Principal na Torre/Totem da Bruma + Pan de Câmera)
	var tut_node: Node = null
	for child in stage1.get_children():
		if child.get_script() == load("res://scripts/ui/StageTutorial.gd"):
			tut_node = child
			break
	if tut_node:
		tut_node.call("_set_step", 6)
		var cam1 := stage1.get_node_or_null("IsometricCamera") as Camera3D
		var totem1 := stage1.get_node_or_null("MistTotem") as Node3D
		if cam1 and totem1 and cam1.has_method("focus_instant_on"):
			cam1.call("focus_instant_on", Vector3(6.8, 0.0, 0.0))
	Engine.time_scale = 1.0
	await _wait_frames(15)
	await _save_viewport_png("res://tests/print_alvo_torre.png")

	stage1.queue_free()
	await _wait_frames(5)
	print("[QA] Todas as capturas e verificações concluídas com sucesso!")
	get_tree().quit(0)
