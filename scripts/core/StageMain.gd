extends Node3D

# StageMain.gd - Controlador mestre do ciclo de fase de Reino Pequenino
# Gerencia ondas, totens, plataformas de construção com limites claros e fluxo de vitória/derrota

@export var stage_id: int = 1

@onready var king: CharacterBody3D = $King
@onready var camera: Camera3D = $IsometricCamera
@onready var totem: CharacterBody3D = $MistTotem
@onready var wave_manager: Node = $WaveManager

@onready var archer_pad: Area3D = $PurchasePad_Archer
@onready var tower_pad: Area3D = $PurchasePad_Tower
@onready var palisade_pad: Area3D = $PurchasePad_Palisade
@onready var barracks_pad: Area3D = $PurchasePad_Barracks
@onready var forge_pad: Area3D = $PurchasePad_Forge
@onready var merchant: Area3D = $MerchantCounter

@onready var east_spawn: Marker3D = $Spawners/EastSpawn
@onready var north_spawn: Marker3D = $Spawners/NorthSpawn

const MAX_ARCHERS: int = 10
const MAX_TOWERS: int = 3
const MAX_PALISADES: int = 8

var palisade_slots: Array[Dictionary] = [
	{"pos": Vector3(12.0, 0, -1.8), "rot_y": 0.0},
	{"pos": Vector3(12.0, 0, 1.8), "rot_y": 0.0},
	{"pos": Vector3(10.2, 0, 5.2), "rot_y": 0.785},
	{"pos": Vector3(7.0, 0, 8.5), "rot_y": 1.571},
	{"pos": Vector3(3.2, 0, 10.5), "rot_y": 1.571},
	{"pos": Vector3(-0.6, 0, 10.5), "rot_y": 1.571},
	{"pos": Vector3(12.0, 0, -5.4), "rot_y": 0.0},
	{"pos": Vector3(9.2, 0, -8.8), "rot_y": -0.785}
]
var active_palisades: Array = []

var tower_slots: Array[Vector3] = [
	Vector3(12.0, 0, -3.8),
	Vector3(8.5, 0, 7.0),
	Vector3(1.2, 0, 10.5)
]
var active_towers: Array = []
var barracks_built: bool = false
var forge_built: bool = false

func _ready() -> void:
	stage_id = GameState.current_stage
	GameState.start_stage(stage_id)
	AudioManager.play_music("battle")
	
	# Totem protegido até o final de todas as ondas
	if totem and wave_manager:
		wave_manager.all_waves_spawned.connect(totem.remove_shield)
	
	if wave_manager:
		wave_manager.stage_id = stage_id
		var spawners = {
			"east": east_spawn,
			"north": north_spawn
		}
		wave_manager.setup_spawn_points(spawners)
	
	if archer_pad:
		archer_pad.purchase_completed.connect(_on_purchase_completed)
	if tower_pad:
		tower_pad.purchase_completed.connect(_on_purchase_completed)
	if palisade_pad:
		palisade_pad.purchase_completed.connect(_on_purchase_completed)
	if barracks_pad:
		barracks_pad.purchase_completed.connect(_on_purchase_completed)
	if forge_pad:
		forge_pad.purchase_completed.connect(_on_purchase_completed)
		
	GameState.troop_count_changed.connect(func(_c): _update_pad_statuses())
	_update_pad_statuses()
	_start_interactive_tutorial_if_needed()
	get_tree().create_timer(0.2).timeout.connect(func():
		print("[PERF] FPS Alvo: 60 | Objetos no Frame: %d | Draw Calls: %d" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		])
	)

func _update_pad_statuses() -> void:
	active_towers = active_towers.filter(func(t): return is_instance_valid(t))
	active_palisades = active_palisades.filter(func(p): return is_instance_valid(p))
	
	if archer_pad:
		archer_pad.set_status(GameState.active_troops.size(), MAX_ARCHERS)
		
	if tower_pad:
		tower_pad.set_status(active_towers.size(), MAX_TOWERS)
		
	if palisade_pad:
		var has_damaged = false
		for p in active_palisades:
			if is_instance_valid(p) and p.current_hp < p.max_hp:
				has_damaged = true
				break
		var count = active_palisades.size()
		var is_repair = (count >= MAX_PALISADES and has_damaged)
		palisade_pad.set_status(count, MAX_PALISADES, is_repair, 10)
		
	if barracks_pad:
		barracks_pad.set_status(1 if barracks_built else 0, 1)
		
	if forge_pad:
		forge_pad.set_status(1 if forge_built else 0, 1)

func _start_interactive_tutorial_if_needed() -> void:
	if stage_id == 1 and not SaveManager.save_data.get("stage_1_tutorial_completed", false):
		var tutorial_script = load("res://scripts/ui/StageTutorial.gd")
		if tutorial_script:
			var tutorial = tutorial_script.new()
			add_child(tutorial)
			tutorial.setup(self, king, merchant, wave_manager, [archer_pad, tower_pad, palisade_pad, barracks_pad, forge_pad])
		return
	_trigger_stage_tutorial_if_needed()

func _trigger_stage_tutorial_if_needed() -> void:
	var tutorial_lines: Array[Dictionary] = []
	match stage_id:
		1:
			return
		2:
			tutorial_lines = [
				{
					"speaker": "Dona Zenaide",
					"icon": "👵",
					"text": "Agora os inimigos vêm em maior número! Suba arqueiros nas Torres de Vigia para atirarem com maior alcance e mais dano."
				}
			]
		3:
			tutorial_lines = [
				{
					"speaker": "Dona Zenaide",
					"icon": "👵",
					"text": "Brumosos com tampas de barril e arqueiros de carvão à vista! Use a Ferraria de Campo para aumentar o dano de todo o exército."
				}
			]
			
	if not tutorial_lines.is_empty():
		var dlg_scene = load("res://scenes/ui/DialogueBox.tscn")
		if dlg_scene:
			var dlg = dlg_scene.instantiate()
			add_child(dlg)
			dlg.show_dialogue(tutorial_lines)

func _on_purchase_completed(pad_type: String) -> void:
	match pad_type:
		"recruit_archer":
			_spawn_archer()
		"build_tower":
			_spawn_tower()
		"build_palisade":
			_spawn_palisade()
		"build_barracks":
			_spawn_barracks()
		"build_forge":
			_spawn_forge()
	_update_pad_statuses()

func _spawn_barracks() -> void:
	if barracks_built:
		return
	barracks_built = true
	var scene = load("res://scenes/entities/FieldBarracks.tscn")
	if scene:
		var b = scene.instantiate()
		add_child(b)
		b.global_position = Vector3(-6.5, 0, -4.5)
		Art.pop_in(b)
		Art.dust_puff(self, b.global_position, 18)

func _spawn_forge() -> void:
	if forge_built:
		return
	forge_built = true
	var scene = load("res://scenes/entities/FieldForge.tscn")
	if scene:
		var f = scene.instantiate()
		add_child(f)
		f.global_position = Vector3(-6.5, 0, 4.5)
		Art.pop_in(f)
		Art.dust_puff(self, f.global_position, 18)

func _spawn_archer() -> void:
	if GameState.active_troops.size() >= MAX_ARCHERS:
		return
	var scene = load("res://scenes/entities/Archer.tscn")
	if scene:
		var a = scene.instantiate()
		add_child(a)
		a.global_position = archer_pad.global_position + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		Art.pop_in(a)

func _spawn_tower() -> void:
	active_towers = active_towers.filter(func(t): return is_instance_valid(t))
	if active_towers.size() >= MAX_TOWERS:
		return
		
	var scene = load("res://scenes/entities/ArcherTower.tscn")
	if not scene:
		return
		
	var target_pos = tower_slots[active_towers.size()]
	var t = scene.instantiate()
	add_child(t)
	t.global_position = target_pos
	active_towers.append(t)
	Art.pop_in(t)
	Art.dust_puff(self, target_pos, 16)

func _spawn_palisade() -> void:
	active_palisades = active_palisades.filter(func(p): return is_instance_valid(p))
	var scene = load("res://scenes/entities/Palisade.tscn")
	if not scene:
		return
		
	if active_palisades.size() < MAX_PALISADES:
		var slot = palisade_slots[active_palisades.size()]
		var p = scene.instantiate()
		add_child(p)
		p.global_position = slot.pos
		p.rotation.y = slot.rot_y
		active_palisades.append(p)
		Art.pop_in(p)
		Art.dust_puff(self, slot.pos, 10)
	else:
		# Repara todas as paliçadas danificadas!
		for p in active_palisades:
			if is_instance_valid(p) and p.has_method("repair_fully"):
				p.repair_fully()
		AudioManager.play_sfx("hero_skill")
		Art.dust_puff(self, palisade_pad.global_position, 12)
