extends Node3D

# StageCoreTest.gd - Controlador da cena de validação do núcleo da Fase
# Valida movimentação, coleta magnética, compra de tropas e combate

@export var initial_enemies: int = 3

@onready var king: CharacterBody3D = $King
@onready var camera: Camera3D = $IsometricCamera
@onready var purchase_pad: Area3D = $PurchasePad
@onready var spawn_point: Marker3D = $EnemySpawnPoint

func _ready() -> void:
	GameState.start_stage(1)
	AudioManager.play_music("battle")
	
	if purchase_pad:
		purchase_pad.purchase_completed.connect(_on_purchase_completed)
	
	# Espalha algumas moedas iniciais pelo chão para teste imediato de ímã
	_spawn_initial_coins()
	
	# Invoca os primeiros inimigos
	for i in range(initial_enemies):
		_spawn_enemy(Vector3(12.0 + i * 2.0, 0, randf_range(-4.0, 4.0)))

func _spawn_initial_coins() -> void:
	var coin_scene = load("res://scenes/entities/Coin.tscn")
	if not coin_scene:
		return
		
	var offsets = [
		Vector3(2.5, 0.2, 1.5),
		Vector3(3.2, 0.2, -1.8),
		Vector3(-2.8, 0.2, 2.2),
		Vector3(-3.5, 0.2, -2.5),
		Vector3(1.2, 0.2, 4.0)
	]
	
	for off in offsets:
		var c = coin_scene.instantiate()
		add_child(c)
		c.global_position = king.global_position + off

func _on_purchase_completed(pad_type: String) -> void:
	if "recruit" in pad_type:
		_recruit_archer()

func _recruit_archer() -> void:
	var archer_scene = load("res://scenes/entities/Archer.tscn")
	if not archer_scene:
		return
		
	var archer = archer_scene.instantiate()
	add_child(archer)
	# Spawna próximo à plataforma de compra
	archer.global_position = purchase_pad.global_position + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))

func _spawn_enemy(pos: Vector3) -> void:
	var enemy_scene = load("res://scenes/entities/MistyRunner.tscn")
	if not enemy_scene:
		return
		
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = pos
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Node3D) -> void:
	# Spawna outro após breve intervalo para manter o ciclo de combate ativo no teste
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(self) and not GameState.is_game_over:
			_spawn_enemy(Vector3(14.0, 0, randf_range(-5.0, 5.0)))
	)

# Método para teste de estresse de 20 arqueiros
func spawn_20_archers_stress_test() -> void:
	for i in range(20):
		_recruit_archer()

