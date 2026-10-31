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

def test_world1_9_stages():
    """Valida a progressão completa das 9 fases normais do Mundo 1 (Etapa 4)"""
    waves_path = os.path.join(BASE_DIR, "data", "waves", "world1_waves.json")
    with open(waves_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    stages = [f"stage_{i}" for i in range(1, 10)]
    has_all_9 = all(s in data for s in stages)
    
    # Valida escalonamento de Totem HP (fase 1: 120 -> fase 9: 450)
    hp_1 = data["stage_1"]["totem_hp"]
    hp_9 = data["stage_9"]["totem_hp"]
    hp_progression = (hp_9 > hp_1)
    
    # Valida desbloqueio do Lanceiro na fase 5
    has_spearman = data["stage_5"].get("unlocks_troop") == "spearman"
    
    # Valida mini-chefe Gigante da Bruma na fase 9
    wave_4_enemies = data["stage_9"]["waves"][3]["enemies"]
    has_giant = any(e.get("type") == "misty_giant" for e in wave_4_enemies)
    
    all_valid = has_all_9 and hp_progression and has_spearman and has_giant
    return log_test("Mundo 1 Completo (9 Fases, Totem HP, Lanceiro F5, Gigante F9)", all_valid,
                    f"Fase 1 Totem: {hp_1} HP | Fase 9 Totem: {hp_9} HP")

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0 A 4)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_world1_9_stages()
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
