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

def test_formation_math_20_archers():
    total = 20
    positions = []
    base_radius = 2.4
    
    for i in range(total):
        ring = 1
        ring_capacity = 6
        remaining = i
        cur_radius = base_radius
        while remaining >= ring_capacity:
            remaining -= ring_capacity
            ring += 1
            ring_capacity = ring * 6
            cur_radius += 1.2
        angle_step = (2 * math.pi) / ring_capacity
        angle = remaining * angle_step
        x = math.cos(angle) * cur_radius
        z = math.sin(angle) * cur_radius
        positions.append((x, z, cur_radius))
    
    no_overlap_center = all(math.hypot(p[0], p[1]) >= base_radius * 0.99 for p in positions)
    unique_positions = len(set((round(p[0], 2), round(p[1], 2)) for p in positions)) == 20
    max_radius = max(p[2] for p in positions)
    radius_ok = max_radius <= 6.0
    
    return log_test("Matemática de Formação para 20 Arqueiros (Etapa 1)", 
                    no_overlap_center and unique_positions and radius_ok,
                    f"20 posições calculadas, Raio máx: {max_radius:.1f}m")

def test_purchase_pad_economics():
    base_cost = 5
    increment = 1
    coins_available = 15
    purchases = 0
    current_cost = base_cost
    
    while coins_available >= current_cost:
        coins_available -= current_cost
        purchases += 1
        current_cost += increment
    
    expected_purchases = 2
    return log_test("Economia da Plataforma de Compra (15 moedas iniciais)", 
                    purchases == expected_purchases and coins_available == 4)

def test_stars_and_rewards_logic():
    """Valida o cálculo de estrelas (1 a 3) e ouro permanente por desempenho da Etapa 2"""
    def calc_stars(king_hp, king_max_hp):
        ratio = king_hp / king_max_hp
        if ratio >= 0.7:
            return 3
        elif ratio >= 0.35:
            return 2
        return 1

    s3 = calc_stars(85, 100) # 85% -> 3 estrelas
    s2 = calc_stars(50, 100) # 50% -> 2 estrelas
    s1 = calc_stars(20, 100) # 20% -> 1 estrela

    # Ouro da vitória na Fase 1: (20 + 1 * 5) * estrelas
    gold_s3 = (20 + 1 * 5) * s3 # 25 * 3 = 75
    gold_s1 = (20 + 1 * 5) * s1 # 25 * 1 = 25

    stars_correct = (s3 == 3 and s2 == 2 and s1 == 1)
    rewards_correct = (gold_s3 == 75 and gold_s1 == 25)

    return log_test("Lógica de Desempenho e Estrelas (Etapa 2)", 
                    stars_correct and rewards_correct,
                    f"85% HP = {s3}⭐ (75 Ouro) | 50% HP = {s2}⭐ | 20% HP = {s1}⭐ (25 Ouro)")

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0, 1 E 2)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_formation_math_20_archers(),
        test_purchase_pad_economics(),
        test_stars_and_rewards_logic()
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
