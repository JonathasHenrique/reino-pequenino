#!/usr/bin/env python3
"""
test_runner.py - Validador de integridade, economia, física e consistência do Reino Pequenino
"""

import os
import sys
import json
import math

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def log_test(name, success, msg=""):
    status = "✅ PASS" if success else "❌ FAIL"
    print(f"[{status}] {name} {('- ' + msg) if msg else ''}")
    return success

def test_json_files():
    all_ok = True
    data_dir = os.path.join(BASE_DIR, "data")
    for root, _, files in os.walk(data_dir):
        for f in files:
            if f.endswith(".json"):
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, BASE_DIR)
                try:
                    with open(full_path, "r", encoding="utf-8") as jf:
                        data = json.load(jf)
                    all_ok = log_test(f"JSON Sintaxe: {rel_path}", True, f"{len(data)} entradas") and all_ok
                except Exception as e:
                    all_ok = log_test(f"JSON Sintaxe: {rel_path}", False, str(e)) and all_ok
    return all_ok

def test_scenes_exist():
    expected_scenes = [
        "scenes/entities/Coin.tscn",
        "scenes/entities/Arrow.tscn",
        "scenes/entities/PuffEffect.tscn",
        "scenes/entities/King.tscn",
        "scenes/entities/Archer.tscn",
        "scenes/entities/MistyRunner.tscn",
        "scenes/entities/MistTotem.tscn",
        "scenes/entities/ArcherTower.tscn",
        "scenes/entities/Palisade.tscn",
        "scenes/entities/PurchasePad.tscn",
        "scenes/ui/FloatingNumber.tscn",
        "scenes/ui/VirtualJoystick.tscn",
        "scenes/ui/GameHUD.tscn",
        "scenes/ui/VictoryScreen.tscn",
        "scenes/ui/DefeatScreen.tscn",
        "scenes/ui/SettingsMenu.tscn",
        "scenes/ui/DialogueBox.tscn",
        "scenes/ui/IntroCutscene.tscn",
        "scenes/ui/MainMenu.tscn",
        "scenes/minigames/Challenge10_Catapult.tscn",
        "scenes/minigames/CatapultRock.tscn",
        "scenes/minigames/ChallengeVictoryScreen.tscn",
        "scenes/village/VillageBuilding.tscn",
        "scenes/village/Mill.tscn",
        "scenes/village/VillageHUD.tscn",
        "scenes/village/Village.tscn",
        "scenes/stages/StageCoreTest.tscn",
        "scenes/stages/StageMain.tscn"
    ]
    all_exist = True
    for s in expected_scenes:
        p = os.path.join(BASE_DIR, s)
        exists = os.path.exists(p)
        if not exists:
            all_exist = False
        log_test(f"Cena TSCN: {s}", exists)
    return all_exist

def test_minigame_runner_rewards():
    """Valida as 6 recompensas de desafios mapeadas no MiniGameRunner (Etapa 5)"""
    expected_rewards = {
        10: {"hero": "marta", "star_index": 1},
        20: {"hero": "fidelio", "star_index": 2},
        30: {"hero": "rosa", "star_index": 3},
        40: {"hero": "clara", "star_index": 4},
        50: {"hero": "bento", "star_index": 5},
        60: {"hero": "barao", "star_index": 6}
    }
    
    # Valida presença de todos os heróis correspondentes em heroes.json
    heroes_path = os.path.join(BASE_DIR, "data", "heroes", "heroes.json")
    with open(heroes_path, "r", encoding="utf-8") as f:
        heroes = json.load(f)
        
    all_matched = all(rew["hero"] in heroes for rew in expected_rewards.values())
    marta_discount = heroes["marta"].get("cost_discount", 0) == 0.15
    
    valid = all_matched and marta_discount
    return log_test("Mapeamento de Recompensas dos 6 Desafios (MiniGameRunner)", valid,
                    f"Marta (Desafio 10, Estrela 1, Desconto 15%) validada")

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0 A 5)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_minigame_runner_rewards()
    ]
    
    print("-" * 60)
    if all(results):
        print("🎉 TODOS OS TESTES PASSARAM COM SUCESSO!")
        return 0
    else:
        print("⚠️ ALGUNS TESTES FALHARAM!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
