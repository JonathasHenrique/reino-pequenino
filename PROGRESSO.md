# Diário de Progresso — Reino Pequenino 🏰

Registro contínuo do desenvolvimento, testes automatizados, decisões técnicas e pendências.

---

## [Etapa 0] Fundação, Arquitetura e Configuração Inicial
**Data:** 31 de Outubro de 2026
- Estrutura completa de pastas criada.
- `project.godot` configurado para landscape, canvas_items, touch emulation.
- 6 Autoloads implementados: Settings, SaveManager, GameState, AudioManager, MiniGameRunner, StoreService.
- JSONs base criados (`heroes.json`, `troops.json`, `enemies.json`, `buildings.json`, `strings_pt_br.json`, `strings_en.json`).
- Documentação e suíte de testes inicial aprovada.

---

## [Etapa 1] Núcleo Jogável: Rei, Joystick, Câmera, Moedas, Plataforma & Arqueiros
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Câmera Isométrica (`IsometricCamera.gd`):**
   - Configurada em ~50° de elevação e 45° de rotação com interpolação suave (*lerp*) seguindo o Rei.
2. **Joystick Virtual Dinâmico (`VirtualJoystick.gd` & `VirtualJoystick.tscn`):**
   - Suporte completo a tela de toque (uma mão só) e teclas WASD/setas no PC.
3. **Rei Teodoro & Biscoito (`King.gd` & `King.tscn`):**
   - Movimentação projetada no plano isométrico.
   - Ímã magnético de moedas (`Area3D`) com atração acelerada.
   - Coluna de moedas 3D empilhada verticalmente sobre a sela (`CoinStack.gd`).
   - Aura circular translúcida projetada no chão indicando raio de formação.
4. **Moedas Magnéticas (`Coin.gd` & `Coin.tscn`):**
   - Rotação suave, detecção por ímã e transferência para a carteira da fase.
5. **Plataforma de Compra (`PurchasePad.gd` & `PurchasePad.tscn`):**
   - Gasto gradual por presença no quadrado (1 moeda a cada 0.12s), preenchimento visual proporcional e incremento de custo por unidade recrutada.
6. **Tropas Seguidoras & Arqueiros (`FollowerTroop.gd`, `Archer.tscn`, `Arrow.tscn`):**
   - Algoritmo de formação em anéis concêntricos sem colisão central.
   - Disparo automático de flechas contra o inimigo mais próximo no alcance.
   - Suporte para subir em torres de vigia.
7. **Inimigo Brumoso (`Enemy.gd`, `MistyRunner.tscn`, `PuffEffect.tscn`, `FloatingNumber.tscn`):**
   - IA de perseguição ao Rei e paliçadas.
   - Olhos amarelos de lanterna e chapéu de panela (100% original, sem sangue).
   - Ao ser derrotado: solta nuvem cinza ("puf"), números de dano flutuantes e 2 moedas.
8. **HUD de Combate (`GameHUD.gd` & `GameHUD.tscn`):**
   - Exibição de moedas, barra de vida, contador de tropas, botão de habilidade do herói e contador de FPS.
9. **Cena de Teste de Núcleo (`StageCoreTest.tscn`):**
   - Cenário de diorama com luz de entardecer, sombras suaves, moedas e geração contínua de inimigos.

### O que foi testado:
- Teste de formação matemática com 20 arqueiros: raio máximo contido em 4.8m sem sobreposição central.
- Simulação de DPS: Arqueiro (12 dano, 1.1 atk/s) abate o Brumoso (24 HP) em 1.82s antes que o inimigo alcance o Rei (4.38s).
- Validação econômica da plataforma de compra com saldo inicial de 15 moedas.
- Teste de sintaxe e presença de todas as 11 cenas TSCN.

### Decisões tomadas:
- A rotação do joystick converte o vetor de entrada em 45 graus para corresponder perfeitamente à perspectiva isométrica da câmera, tornando a movimentação natural no polegar do jogador.
- As tropas utilizam anéis hexagonais/concêntricos calculados dinamicamente para permitir até dezenas de unidades na tela sem perda de performance.

### O que falta:
- Iniciar a Etapa 2: Ciclo de Fase Completo (gerenciador de ondas `WaveManager`, Totem de Bruma, torres elevadas, paliçadas de madeira, setas de borda e telas de vitória/derrota com 1 a 3 estrelas).

### Limitações:
- O teste de framerate em hardware físico Android depende da execução no dispositivo do usuário conforme guia do README.
