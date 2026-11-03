extends Node

# smoke_test.gd - Runner de cenas executado pela cena SmokeTest.tscn com autoloads ativos.

const SCENES: Array[String] = [
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
	"res://scenes/entities/Archer.tscn",
	"res://scenes/stages/StageMain.tscn",
	"res://scenes/stages/StageCoreTest.tscn",
	"res://scenes/minigames/Challenge10_Catapult.tscn",
	"res://scenes/minigames/Challenge20_Sudoku.tscn",
	"res://scenes/minigames/Challenge30_Breakout.tscn",
	"res://scenes/minigames/Challenge40_BlockPuzzle.tscn",
	"res://scenes/minigames/Challenge50_Platformer.tscn",
	"res://scenes/minigames/Challenge60_LaneDefense.tscn"
]

func _ready() -> void:
	call_deferred("_run_scenes")

func _run_scenes() -> void:
	print(">>> INICIANDO SMOKE TEST NO GODOT 4.3 HEADLESS <<<")
	var passed := 0
	var failed := 0
	for scene_path in SCENES:
		print("Testando cena: ", scene_path)
		var packed := load(scene_path) as PackedScene
		if not packed or not _scripts_can_instantiate(packed):
			print("FALHA AO CARREGAR/COMPILAR: ", scene_path)
			failed += 1
			continue
		var instance := packed.instantiate()
		if not instance:
			print("FALHA AO INSTANCIAR: ", scene_path)
			failed += 1
			continue
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		if scene_path == "res://scenes/stages/StageMain.tscn":
			if not _build_and_validate_palisade_ring(instance):
				print("FALHA: perímetro das paliçadas não fecha")
				failed += 1
				instance.queue_free()
				await get_tree().process_frame
				continue
		instance.queue_free()
		await get_tree().process_frame
		passed += 1
		print("  -> OK!")

	print("============================================")
	print("RESULTADO DO TESTE NO MOTOR GODOT:")
	print("Aprovados: ", passed, " / ", SCENES.size())
	print("Falhas: ", failed)
	print("============================================")
	get_tree().quit(1 if failed > 0 else 0)

func _scripts_can_instantiate(packed: PackedScene) -> bool:
	var state := packed.get_state()
	for node_index in range(state.get_node_count()):
		for property_index in range(state.get_node_property_count(node_index)):
			if state.get_node_property_name(node_index, property_index) != "script":
				continue
			var script := state.get_node_property_value(node_index, property_index) as Script
			if not script or not script.can_instantiate():
				return false
	return true

func _build_and_validate_palisade_ring(stage: Node) -> bool:
	for _index in range(8):
		stage.call("_spawn_palisade")
	var palisades: Array = stage.get("active_palisades")
	if palisades.size() != 8:
		return false

	for index in range(palisades.size()):
		var palisade := palisades[index] as Node3D
		var half_length := 4.3
		var axis := palisade.global_transform.basis.x.normalized() * half_length
		for endpoint in [palisade.global_position - axis, palisade.global_position + axis]:
			var connected := false
			for other_index in range(palisades.size()):
				if other_index == index:
					continue
				var other := palisades[other_index] as Node3D
				var other_axis := other.global_transform.basis.x.normalized() * half_length
				if endpoint.distance_to(other.global_position - other_axis) <= 0.2 or endpoint.distance_to(other.global_position + other_axis) <= 0.2:
					connected = true
					break
			if not connected:
				return false
	return true

