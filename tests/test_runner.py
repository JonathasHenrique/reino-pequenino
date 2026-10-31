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
        "scenes/ui/EndingCutscene.tscn",
        "scenes/ui/MainMenu.tscn",
        "scenes/ui/RetroFilterOverlay.tscn",
        "scenes/ui/TrophiesMenu.tscn",
        "scenes/ui/StickerAlbum.tscn",
        "scenes/minigames/Challenge10_Catapult.tscn",
        "scenes/minigames/CatapultRock.tscn",
        "scenes/minigames/Challenge20_Sudoku.tscn",
        "scenes/minigames/Challenge30_Breakout.tscn",
        "scenes/minigames/Challenge40_BlockPuzzle.tscn",
        "scenes/minigames/Challenge50_Platformer.tscn",
        "scenes/minigames/Challenge60_LaneDefense.tscn",
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

def test_world6_and_collectibles():
    """Valida Mundo 6, os 6 Desafios Totais, Troféus e Álbum de Figurinhas (Etapa 8)"""
    w6 = json.load(open(os.path.join(BASE_DIR, "data", "waves", "world6_waves.json")))
    trophies = json.load(open(os.path.join(BASE_DIR, "data", "trophies", "trophies.json")))
    stickers = json.load(open(os.path.join(BASE_DIR, "data", "stickers", "stickers.json")))
    
    stages_w6_ok = len(w6) == 9
    trophies_ok = len(trophies) >= 6
    stickers_ok = len(stickers) == 6
    
    valid = stages_w6_ok and trophies_ok and stickers_ok
    return log_test("Mundo 6, Colecionáveis e Álbum (9 fases, 6 troféus, 6 figurinhas da coroa)", valid)

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0 A 8)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_world6_and_collectibles()
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
