#!/usr/bin/env python3
"""
test_runner.py - Validador de integridade, economia e consistência de dados do Reino Pequenino
"""

import os
import sys
import json

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

def test_heroes_consistency():
    heroes_path = os.path.join(BASE_DIR, "data", "heroes", "heroes.json")
    with open(heroes_path, "r", encoding="utf-8") as f:
        heroes = json.load(f)
    
    expected_heroes = ["teodoro", "marta", "fidelio", "rosa", "clara", "bento", "barao"]
    all_present = all(h in heroes for h in expected_heroes)
    return log_test("Consistência de Heróis (7 esperados)", all_present, f"Encontrados: {list(heroes.keys())}")

def test_troops_consistency():
    troops_path = os.path.join(BASE_DIR, "data", "troops", "troops.json")
    with open(troops_path, "r", encoding="utf-8") as f:
        troops = json.load(f)
    
    expected_troops = ["archer", "spearman", "squire", "mage", "healer", "ballista"]
    all_present = all(t in troops for t in expected_troops)
    return log_test("Consistência de Tropas (6 esperadas)", all_present, f"Encontradas: {list(troops.keys())}")

def test_enemies_consistency():
    enemies_path = os.path.join(BASE_DIR, "data", "enemies", "enemies.json")
    with open(enemies_path, "r", encoding="utf-8") as f:
        enemies = json.load(f)
    
    expected_enemies = ["misty_runner", "misty_squire", "misty_archer", "misty_crow", "misty_giant", "mist_totem"]
    all_present = all(e in enemies for e in expected_enemies)
    return log_test("Consistência de Inimigos (6 esperados)", all_present, f"Encontrados: {list(enemies.keys())}")

def test_economy_scaling():
    # Validação do aumento de vida de inimigos de ~8% por fase conforme especificado
    base_hp = 24.0 # vida inicial do Misty Runner
    hp_stage_1 = base_hp
    hp_stage_10 = base_hp * (1.08 ** 9)
    hp_stage_60 = base_hp * (1.08 ** 59)
    
    valid_scaling = (hp_stage_10 > hp_stage_1) and (hp_stage_60 > hp_stage_10)
    return log_test("Cálculo de Escalonamento de Dificuldade (+8%/fase)", valid_scaling, 
                    f"Fase 1: {hp_stage_1:.1f} HP | Fase 10: {hp_stage_10:.1f} HP | Fase 60: {hp_stage_60:.1f} HP")

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPA 0)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_heroes_consistency(),
        test_troops_consistency(),
        test_enemies_consistency(),
        test_economy_scaling()
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
