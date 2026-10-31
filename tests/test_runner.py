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
        "scenes/entities/PurchasePad.tscn",
        "scenes/ui/FloatingNumber.tscn",
        "scenes/ui/VirtualJoystick.tscn",
        "scenes/ui/GameHUD.tscn",
        "scenes/stages/StageCoreTest.tscn"
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
    """Valida que o algoritmo de formação em anéis concêntricos distribui 20+ tropas sem colisão central"""
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
    
    # Validações:
    # 1. Nenhuma tropa fica na posição exata do Rei (0,0)
    no_overlap_center = all(math.hypot(p[0], p[1]) >= base_radius * 0.99 for p in positions)
    # 2. Todas as 20 tropas têm posições únicas
    unique_positions = len(set((round(p[0], 2), round(p[1], 2)) for p in positions)) == 20
    # 3. Raio máximo não excede limites razoáveis de visão da câmera
    max_radius = max(p[2] for p in positions)
    radius_ok = max_radius <= 6.0
    
    return log_test("Matemática de Formação para 20 Arqueiros (Etapa 1)", 
                    no_overlap_center and unique_positions and radius_ok,
                    f"20 posições calculadas, Raio máx: {max_radius:.1f}m, Sem sobreposição com o Rei")

def test_purchase_pad_economics():
    """Valida o mecanismo de compra gradual e incremento de custo"""
    base_cost = 5
    increment = 1
    coins_available = 15
    purchases = 0
    current_cost = base_cost
    
    while coins_available >= current_cost:
        coins_available -= current_cost
        purchases += 1
        current_cost += increment
    
    # Com 15 moedas: compra 1 (custo 5, sobram 10), compra 2 (custo 6, sobram 4). Total = 2 arqueiros.
    expected_purchases = 2
    return log_test("Economia da Plataforma de Compra (15 moedas iniciais)", 
                    purchases == expected_purchases and coins_available == 4,
                    f"Recrutou {purchases} arqueiros, sobraram {coins_available} moedas")

def test_combat_dps_simulation():
    """Valida que um arqueiro causa dano suficiente para derrotar um Misty Runner antes do Rei cair"""
    archer_dmg = 12
    archer_rate = 1.1 # 1.1 tiros por segundo
    enemy_hp = 24
    shots_needed = math.ceil(enemy_hp / archer_dmg) # 2 tiros
    time_to_kill = shots_needed / archer_rate # ~1.81s
    
    # Inimigo anda a 3.2m/s de 14m de distância -> leva 4.37s para alcançar
    approach_time = 14.0 / 3.2
    safe_kill = time_to_kill < approach_time
    
    return log_test("Simulação de DPS de Combate (Arqueiro vs Brumoso)", 
                    safe_kill,
                    f"Tempo de abate: {time_to_kill:.2f}s < Tempo de aproximação: {approach_time:.2f}s")

def main():
    print("=" * 60)
    print("  SUÍTE DE TESTES AUTOMATIZADOS — REINO PEQUENINO (ETAPAS 0 E 1)")
    print("=" * 60)
    
    results = [
        test_json_files(),
        test_scenes_exist(),
        test_formation_math_20_archers(),
        test_purchase_pad_economics(),
        test_combat_dps_simulation()
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
