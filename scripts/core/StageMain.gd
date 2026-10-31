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
	GameState.start_stage(stage_id)
	AudioManager.play_music("battle")
	
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

func _on_purchase_completed(pad_type: String) -> void:
	match pad_type:
		"recruit_archer":
			_spawn_archer()
		"build_tower":
			_spawn_tower()
		"build_palisade":
			_spawn_palisade()

func _spawn_archer() -> void:
	var scene = load("res://scenes/entities/Archer.tscn")
	if scene:
		var a = scene.instantiate()
		add_child(a)
		a.global_position = archer_pad.global_position + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))

func _spawn_tower() -> void:
	var scene = load("res://scenes/entities/ArcherTower.tscn")
	if scene:
		var t = scene.instantiate()
		add_child(t)
		t.global_position = tower_pad.global_position + Vector3(0, 0, -2.5)

func _spawn_palisade() -> void:
	var scene = load("res://scenes/entities/Palisade.tscn")
	if scene:
		var p = scene.instantiate()
		add_child(p)
		p.global_position = palisade_pad.global_position + Vector3(0, 0, 2.0)
