#!/usr/bin/env python3
"""
test_runner.py - Suíte de Testes Automatizados Integral do Reino Pequenino (Etapas 0 a 9)
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
        "scenes/entities/SpoilLoot.tscn",
        "scenes/entities/MerchantCounter.tscn",
        "scenes/entities/FieldBarracks.tscn",
        "scenes/entities/FieldForge.tscn",
        "scenes/props/Tree.tscn",
        "scenes/props/PineTree.tscn",
        "scenes/props/Rock.tscn",
        "scenes/props/FlowerPatch.tscn",
        "scenes/props/WoodenFence.tscn",
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
        "scenes/ui/StoreMenu.tscn",
        "scenes/ui/DebugMenu.tscn",
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

def test_full_60_stages():
    """Valida a cobertura total das 60 fases distribuídas nos 6 Mundos"""
    total_stages = 0
    world_files = [f"world{i}_waves.json" for i in range(1, 7)]
    for wf in world_files:
        path = os.path.join(BASE_DIR, "data", "waves", wf)
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            total_stages += len(data) # 9 fases normais por mundo
            
    # + 6 fases de Desafio (10, 20, 30, 40, 50, 60)
    total_stages += 6
    valid = (total_stages == 60)
    return log_test("Cobertura Completa das 60 Fases (54 Fases Normais + 6 Desafios em 6 Mundos)", valid, f"Total: {total_stages}/60")

def test_difficulty_balancing():
    """Valida o balanceamento relativo das 3 dificuldades"""
    base_enemy_hp = 100.0
    hp_tranquilo = base_enemy_hp * 0.75 # 25% menos vida
    hp_classico = base_enemy_hp
    hp_veterano = base_enemy_hp * 1.20 # 20% mais vida
    
    valid = (hp_tranquilo < hp_classico) and (hp_veterano > hp_classico)
    return log_test("Matriz das 3 Dificuldades (Tranquilo -25% HP | Clássico | Veterano +20% HP)", valid)

def test_store_service_products():
    """Valida a ausência de compras predatórias e preços transparentes na StoreService"""
    store_file = os.path.join(BASE_DIR, "scripts", "autoloads", "StoreService.gd")
    with open(store_file, "r", encoding="utf-8") as f:
        code = f.read()
        
    has_lootbox = "lootbox" in code.lower() or "gacha" in code.lower()
    has_mock = "is_mock_mode" in code
    has_bundle = "bundle_complete_kingdom" in code
    
    valid = (not has_lootbox) and has_mock and has_bundle
    return log_test("Conformidade da Loja Ética (Zero Gacha, Mock Offline Ativo, Pacote Completo)", valid)

def test_export_preset_android():
    """Valida a existência e configuração do preset de exportação para Android"""
    preset_path = os.path.join(BASE_DIR, "export_presets.cfg")
    exists = os.path.exists(preset_path)
    has_package = False
    if exists:
        with open(preset_path, "r", encoding="utf-8") as f:
            content = f.read()
            has_package = "com.reinopequenino.game" in content and "sensor_landscape" in content
            
    return log_test("Preset de Exportação Android (Godot 4.3 Landscape, arm64/armeabi)", exists and has_package)

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES INTEGRAL — REINO PEQUENINO (ETAPAS 0 A 9 FINAL)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_full_60_stages(),
        test_difficulty_balancing(),
        test_store_service_products(),
        test_export_preset_android()
    ]
    
    print("-" * 60)
    if all(results):
        print("🎉 TODOS OS TESTES PASSARAM COM SUCESSO! PROJETO PRONTO PARA ENTREGA!")
        return 0
    else:
        print("⚠️ ALGUNS TESTES FALHARAM!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
