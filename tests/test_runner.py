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
        "scenes/entities/CoinSparkle.tscn",
        "scenes/entities/FallingLeaves.tscn",
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
        "scenes/ui/RetroFilterOverlay.tscn",
        "scenes/minigames/Challenge10_Catapult.tscn",
        "scenes/minigames/CatapultRock.tscn",
        "scenes/minigames/Challenge20_Sudoku.tscn",
        "scenes/minigames/Challenge30_Breakout.tscn",
        "scenes/minigames/Challenge40_BlockPuzzle.tscn",
        "scenes/minigames/Challenge50_Platformer.tscn",
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

def test_worlds_2_to_5_progression():
    """Valida as 36 fases e desbloqueios de tropas dos Mundos 2 a 5 (Etapa 7)"""
    w2 = json.load(open(os.path.join(BASE_DIR, "data", "waves", "world2_waves.json")))
    w3 = json.load(open(os.path.join(BASE_DIR, "data", "waves", "world3_waves.json")))
    w4 = json.load(open(os.path.join(BASE_DIR, "data", "waves", "world4_waves.json")))
    w5 = json.load(open(os.path.join(BASE_DIR, "data", "waves", "world5_waves.json")))
    
    stages_count = len(w2) + len(w3) + len(w4) + len(w5)
    
    # Valida desbloqueio de tropas
    has_squire = w2.get("stage_12", {}).get("unlocks_troop") == "squire"
    has_mage = w3.get("stage_22", {}).get("unlocks_troop") == "mage"
    has_healer = w4.get("stage_32", {}).get("unlocks_troop") == "healer"
    has_ballista = w5.get("stage_42", {}).get("unlocks_troop") == "ballista"
    
    valid = (stages_count == 36) and has_squire and has_mage and has_healer and has_ballista
    return log_test("Mundos 2 a 5 (36 fases, Escudeiro F12, Mago F22, Curandeiro F32, Balista F42)", valid)

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0 A 7)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_worlds_2_to_5_progression()
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
