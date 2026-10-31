extends Node3D

# StageMain.gd - Controlador mestre do ciclo de fase de Reino Pequenino
# Gerencia ondas, totens, plataformas de construção e fluxo de vitória/derrota

@export var stage_id: int = 1

@onready var king: CharacterBody3D = $King
@onready var camera: Camera3D = $IsometricCamera
@onready var totem: CharacterBody3D = $MistTotem
@onready var wave_manager: Node = $WaveManager
@onready var archer_pad: Area3D = $PurchasePad_Archer
@onready var tower_pad: Area3D = $PurchasePad_Tower
@onready var palisade_pad: Area3D = $PurchasePad_Palisade

@onready var east_spawn: Marker3D = $Spawners/EastSpawn
@onready var north_spawn: Marker3D = $Spawners/NorthSpawn

func _ready() -> void:
	# CORREÇÃO: a fase vem do GameState (definida pelo menu/vitória), não do valor fixo da cena
	stage_id = GameState.current_stage
	GameState.start_stage(stage_id)
	AudioManager.play_music("battle")
	
	# O Totem fica protegido pela Bruma até a última onda ser vencida
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
		
	_trigger_stage_tutorial_if_needed()

func _trigger_stage_tutorial_if_needed() -> void:
	# Dicas da Dona Zenaide nas fases 1 a 3
	var tutorial_lines: Array[Dictionary] = []
	match stage_id:
		1:
			tutorial_lines = [
				{
					"speaker": "Dona Zenaide",
					"icon": "👵",
					"text": "Teodoro! Os inimigos derrotados derrubam Capacetes e Sucatas de batalha. Atraia-os e leve ao balcão do Mercador Tobias para trocar por muitas moedas de ouro!"
				}
			]
		2:
			tutorial_lines = [
				{
					"speaker": "Dona Zenaide",
					"icon": "👵",
					"text": "Use as moedas ganhas do Mercador para construir torres na muralha e contratar mais arqueiros. Arqueiro nenhum trabalha de graça no meu reino!"
				}
			]
		3:
			tutorial_lines = [
				{
					"speaker": "Dona Zenaide",
					"icon": "👵",
					"text": "Lá vêm os Brumosos mais cascas-grossas com tampas de barril. Construa paliçadas e mande seus arqueiros derrubarem o Totem de Bruma!"
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

func _spawn_barracks() -> void:
	var scene = load("res://scenes/entities/FieldBarracks.tscn")
	if scene:
		var b = scene.instantiate()
		add_child(b)
		b.global_position = Vector3(1.5, 0, -4.8)
		AudioManager.play_sfx("build")

func _spawn_forge() -> void:
	var scene = load("res://scenes/entities/FieldForge.tscn")
	if scene:
		var f = scene.instantiate()
		add_child(f)
		f.global_position = Vector3(5.5, 0, 4.2)
		AudioManager.play_sfx("build")

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

func _spawn_archer() -> void:
	var scene = load("res://scenes/entities/Archer.tscn")
	if scene:
		var a = scene.instantiate()
		add_child(a)
		a.global_position = archer_pad.global_position + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))

func _spawn_tower() -> void:
	# Limpa referências a torres destruídas
	active_towers = active_towers.filter(func(t): return is_instance_valid(t))
	var scene = load("res://scenes/entities/ArcherTower.tscn")
	if not scene:
		return
		
	var target_pos = tower_pad.global_position + Vector3(0, 0, -2.5)
	if active_towers.size() < tower_slots.size():
		target_pos = tower_slots[active_towers.size()]
		
	var t = scene.instantiate()
	add_child(t)
	t.global_position = target_pos
	active_towers.append(t)

func _spawn_palisade() -> void:
	# Filtra apenas paliçadas ainda vivas
	active_palisades = active_palisades.filter(func(p): return is_instance_valid(p))
	var scene = load("res://scenes/entities/Palisade.tscn")
	if not scene:
		return
		
	if active_palisades.size() < palisade_slots.size():
		var slot = palisade_slots[active_palisades.size()]
		var p = scene.instantiate()
		add_child(p)
		p.global_position = slot.pos
		p.rotation.y = slot.rot_y
		active_palisades.append(p)
	else:
		# Se o muro estiver completo, repara todas as paliçadas danificadas!
		for p in active_palisades:
			if is_instance_valid(p) and p.has_method("_update_ui"):
				p.current_hp = p.max_hp
				p._update_ui()
		AudioManager.play_sfx("hero_skill")
