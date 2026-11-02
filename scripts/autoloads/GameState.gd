extends Node

# GameState.gd - Estado em tempo real da partida atual no Reino Pequenino
# Gerencia moedas voláteis, vida do rei, tropas ativas e status da fase

signal coins_changed(new_amount: int)
signal spoils_changed(new_amount: int)
signal king_hp_changed(current_hp: int, max_hp: int)
signal wave_started(wave_number: int, total_waves: int)
signal wave_completed(wave_number: int)
signal totem_hp_changed(current_hp: int, max_hp: int)
signal stage_completed(stars: int, gold_earned: int)
signal stage_failed()
signal hero_ability_used(hero_id: String)
signal troop_count_changed(count: int)

const HERO_ABILITY_COOLDOWN_SECONDS: float = 30.0

var current_stage: int = 1
var current_world: int = 1
var stage_coins: int = 0
var stage_spoils: int = 0
var stage_gold_reward: int = 0
var stage_timer: float = 0.0

var king_hp: int = 100
var king_max_hp: int = 100
var king_node: Node3D = null

var is_paused: bool = false
var is_stage_active: bool = false
var is_game_over: bool = false
var hero_ability_ready: bool = true
var hero_ability_active: bool = false
var hero_ability_cooldown_remaining: float = 0.0
var hero_shield_remaining: float = 0.0

var active_troops: Array = []
var active_enemies: Array = []
var active_buildings: Array = []

var debug_mode: bool = false

func start_stage(stage_id: int) -> void:
	current_stage = stage_id
	current_world = int((stage_id - 1) / 10) + 1
	stage_coins = 15 # Moedas iniciais da fase para contratar o 1º arqueiro
	stage_spoils = 0
	stage_timer = 0.0
	is_stage_active = true
	is_game_over = false
	is_paused = false
	hero_ability_ready = true
	hero_ability_active = false
	hero_ability_cooldown_remaining = 0.0
	hero_shield_remaining = 0.0
	
	active_troops.clear()
	active_enemies.clear()
	active_buildings.clear()
	
	# Vida inicial baseada em upgrades da vila
	var stable_lvl = SaveManager.save_data.get("village_buildings", {}).get("stable", 1)
	king_max_hp = 100 + (stable_lvl - 1) * 20
	king_hp = king_max_hp
	
	coins_changed.emit(stage_coins)
	king_hp_changed.emit(king_hp, king_max_hp)

func _process(delta: float) -> void:
	hero_shield_remaining = maxf(0.0, hero_shield_remaining - delta)
	if hero_ability_ready or not is_stage_active:
		return
	hero_ability_cooldown_remaining = maxf(0.0, hero_ability_cooldown_remaining - delta)
	if hero_ability_cooldown_remaining <= 0.0:
		hero_ability_ready = true

func add_stage_coins(amount: int) -> void:
	stage_coins += amount
	coins_changed.emit(stage_coins)
	AudioManager.play_sfx("coin_pickup")

func spend_stage_coins(amount: int) -> bool:
	if stage_coins >= amount:
		stage_coins -= amount
		coins_changed.emit(stage_coins)
		return true
	return false

func add_stage_spoils(amount: int) -> void:
	stage_spoils += amount
	spoils_changed.emit(stage_spoils)

func spend_stage_spoils(amount: int) -> bool:
	if stage_spoils >= amount:
		stage_spoils -= amount
		spoils_changed.emit(stage_spoils)
		return true
	return false

func register_troop(troop: Node3D) -> void:
	if not active_troops.has(troop):
		active_troops.append(troop)
		troop_count_changed.emit(active_troops.size())

func unregister_troop(troop: Node3D) -> void:
	active_troops.erase(troop)
	troop_count_changed.emit(active_troops.size())

func register_enemy(enemy: Node3D) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)

func unregister_enemy(enemy: Node3D) -> void:
	active_enemies.erase(enemy)

func damage_king(amount: int) -> void:
	if is_game_over or not is_stage_active:
		return
	var applied_damage := ceili(float(amount) * 0.5) if hero_shield_remaining > 0.0 else amount
	king_hp = maxi(0, king_hp - applied_damage)
	king_hp_changed.emit(king_hp, king_max_hp)
	AudioManager.play_sfx("king_hit")
	
	if Settings.vibration_enabled:
		Input.vibrate_handheld(60)
		
	if king_hp <= 0:
		fail_stage()

func heal_king(amount: int) -> void:
	king_hp = mini(king_max_hp, king_hp + amount)
	king_hp_changed.emit(king_hp, king_max_hp)

func fail_stage() -> void:
	if is_game_over:
		return
	is_game_over = true
	is_stage_active = false
	AudioManager.play_sfx("stage_defeat")
	stage_failed.emit()

func complete_stage(totem_destroyed: bool = true) -> void:
	if is_game_over:
		return
	is_game_over = true
	is_stage_active = false
	
	# Cálculo de Estrelas (1 a 3):
	# 3 estrelas: rei com > 70% de vida e tempo bom
	# 2 estrelas: rei com > 30% de vida
	# 1 estrela: vitória sobrevivente
	var stars: int = 1
	var hp_ratio: float = float(king_hp) / float(king_max_hp)
	if hp_ratio >= 0.7:
		stars = 3
	elif hp_ratio >= 0.35:
		stars = 2
	
	# Ouro permanente ganho no fim da fase
	var base_gold = 20 + current_stage * 5
	var gold_earned = base_gold * stars
	stage_gold_reward = gold_earned
	
	SaveManager.record_stage_result(current_stage, stars, gold_earned)
	AudioManager.play_sfx("stage_victory")
	stage_completed.emit(stars, gold_earned)

func use_hero_ability() -> void:
	if not hero_ability_ready or is_game_over or not is_stage_active:
		return
	var hero_id = SaveManager.save_data.get("selected_hero", "teodoro")
	hero_ability_ready = false
	hero_ability_cooldown_remaining = HERO_ABILITY_COOLDOWN_SECONDS
	hero_ability_active = hero_id == "teodoro"
	hero_ability_used.emit(hero_id)
	AudioManager.play_sfx("hero_skill")
	if hero_ability_active:
		get_tree().create_timer(8.0, false).timeout.connect(func(): hero_ability_active = false)
	elif hero_id == "rosa":
		hero_shield_remaining = 8.0
	elif hero_id == "clara":
		heal_king(king_max_hp)
		for troop in active_troops:
			if is_instance_valid(troop):
				troop.current_hp = troop.hp

