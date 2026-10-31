extends Node

# MiniGameRunner.gd - Gerenciador desacoplado de Desafios e Minigames
# Conecta o término dos minigames às recompensas de Heróis e Estrelas da Coroa

signal challenge_started(challenge_id: int)
signal challenge_completed(challenge_id: int, result: Dictionary)

const CHALLENGE_SCENES: Dictionary = {
	10: "res://scenes/minigames/Challenge10_Catapult.tscn",
	20: "res://scenes/minigames/Challenge20_Sudoku.tscn",
	30: "res://scenes/minigames/Challenge30_Breakout.tscn",
	40: "res://scenes/minigames/Challenge40_BlockPuzzle.tscn",
	50: "res://scenes/minigames/Challenge50_Platformer.tscn",
	60: "res://scenes/minigames/Challenge60_LaneDefense.tscn"
}

const CHALLENGE_REWARDS: Dictionary = {
	10: {"hero": "marta", "star_index": 1, "name": "A Catapulta do Vale"},
	20: {"hero": "fidelio", "star_index": 2, "name": "Cofre dos Números"},
	30: {"hero": "rosa", "star_index": 3, "name": "Escudo e Bola"},
	40: {"hero": "clara", "star_index": 4, "name": "A Muralha de Peças"},
	50: {"hero": "bento", "star_index": 5, "name": "A Corrida de Biscoito"},
	60: {"hero": "barao", "star_index": 6, "name": "Jardim da Defesa"}
}

var active_challenge_id: int = 0

func launch_challenge(challenge_id: int) -> void:
	if not CHALLENGE_SCENES.has(challenge_id):
		push_error("Desafio não encontrado: " + str(challenge_id))
		return
	
	active_challenge_id = challenge_id
	challenge_started.emit(challenge_id)
	var scene_path = CHALLENGE_SCENES[challenge_id]
	get_tree().change_scene_to_file(scene_path)

func complete_challenge(challenge_id: int, result: Dictionary) -> void:
	# result deve conter: {"won": bool, "stars": int}
	var won = bool(result.get("won", false))
	var stars = int(result.get("stars", 1))
	
	if won and CHALLENGE_REWARDS.has(challenge_id):
		var rew = CHALLENGE_REWARDS[challenge_id]
		var hero_id = rew["hero"]
		var star_idx = rew["star_index"]
		
		SaveManager.unlock_hero(hero_id)
		SaveManager.unlock_crown_star(star_idx)
		SaveManager.record_stage_result(challenge_id, stars, 100 * star_idx)
		
		# Registra figurinha colecionável correspondente
		SaveManager.unlock_sticker("star_" + str(star_idx))
		SaveManager.unlock_trophy("challenge_" + str(challenge_id))
	
	challenge_completed.emit(challenge_id, result)

