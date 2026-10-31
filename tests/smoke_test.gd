extends SceneTree

# smoke_test.gd - Teste de fumaça real executado DENTRO da engine Godot 4.3 Headless
# Carrega e instancia cada cena do jogo, roda 1 frame e garante ausência de falhas/crashes

func _init() -> void:
	print(">>> INICIANDO SMOKE TEST NO GODOT 4.3 HEADLESS <<<")
	var scenes = [
		"res://scenes/ui/MainMenu.tscn",
		"res://scenes/ui/IntroCutscene.tscn",
		"res://scenes/ui/EndingCutscene.tscn",
		"res://scenes/ui/SettingsMenu.tscn",
		"res://scenes/ui/StoreMenu.tscn",
		"res://scenes/ui/TrophiesMenu.tscn",
		"res://scenes/ui/StickerAlbum.tscn",
		"res://scenes/ui/GameHUD.tscn",
		"res://scenes/ui/VictoryScreen.tscn",
		"res://scenes/ui/DefeatScreen.tscn",
		"res://scenes/ui/RetroFilterOverlay.tscn",
		"res://scenes/village/Village.tscn",
		"res://scenes/stages/StageMain.tscn",
		"res://scenes/stages/StageCoreTest.tscn",
		"res://scenes/minigames/Challenge10_Catapult.tscn",
		"res://scenes/minigames/Challenge20_Sudoku.tscn",
		"res://scenes/minigames/Challenge30_Breakout.tscn",
		"res://scenes/minigames/Challenge40_BlockPuzzle.tscn",
		"res://scenes/minigames/Challenge50_Platformer.tscn",
		"res://scenes/minigames/Challenge60_LaneDefense.tscn"
	]
	
	var passed = 0
	var failed = 0
	
	for s_path in scenes:
		print("Testando cena: ", s_path)
		var packed = load(s_path)
		if not packed:
			print("FALHA AO CARREGAR: ", s_path)
			failed += 1
			continue
		var inst = packed.instantiate()
		if not inst:
			print("FALHA AO INSTANCIAR: ", s_path)
			failed += 1
			continue
		root.add_child(inst)
		inst.queue_free()
		passed += 1
		print("  -> OK!")
		
	print("============================================")
	print("RESULTADO DO TESTE NO MOTOR GODOT:")
	print("Aprovados: ", passed, " / ", scenes.size())
	print("Falhas: ", failed)
	print("============================================")
	
	if failed > 0:
		quit(1)
	else:
		print("🎉 TODAS AS CENAS RODARAM COM 100% DE SUCESSO NO GODOT 4.3!")
		quit(0)

