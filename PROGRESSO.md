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
- Câmera Isométrica (~50°) com foco suave.
- Joystick Virtual dinâmico responsivo a toque com uma mão e teclado.
- Rei Teodoro com ímã de moedas acelerado e pilha de moedas 3D empilhada verticalmente.
- Plataforma de compra gradual com progresso de preenchimento.
- Tropas seguidoras em anéis concêntricos com mira automática e disparo de projéteis.
- Inimigo Brumoso original com olhos de lanterna e chapéu de panela, emitindo 'puf' e moedas ao ser abatido.

---

## [Etapa 2] Fase Completa: Ondas, Torres, Paliçadas, Totem de Bruma, HUD, Vitória & Derrota
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Totem de Bruma (`MistTotem.gd` & `MistTotem.tscn`):**
   - Pilar de pedra esculpida com orbe de névoa brilhante e barra de vida.
   - Ao ser destruído, emite efeito sonoro 'puf', solta chuva de moedas e dispara o evento de vitória.
2. **Gerenciador de Ondas Baseado em Dados (`WaveManager.gd` & `data/waves/world1_waves.json`):**
   - Fases 1 a 3 com dados estruturados de tempo de preparação, hordas e spawners cardeais.
   - Transição automática entre contagem regressiva e combate.
3. **Construções de Campo:**
   - **Torre de Arqueiros (`ArcherTower.gd` & `ArcherTower.tscn`):** Plataforma elevada de madeira. Até 3 arqueiros sobem automaticamente e ganham alcance (+35%) e dano (+25%).
   - **Paliçada de Carvalho (`Palisade.gd` & `Palisade.tscn`):** Barreira física resistente (220 HP) que bloqueia brumosos.
4. **Setas de Borda de Tela (`EdgeIndicators.gd`):**
   - Rastreamento dos inimigos fora do viewport da câmera, projetando setas de aviso com rotação orientada nas bordas da tela.
5. **Telas de Desfecho:**
   - **Tela de Vitória (`VictoryScreen.gd` & `VictoryScreen.tscn`):** Avaliação de 1 a 3 estrelas baseada na integridade do Rei Teodoro, concessão de Ouro permanente e botões de fluxo.
   - **Tela de Derrota Amigável (`DefeatScreen.gd` & `DefeatScreen.tscn`):** Tom cômico e afetuoso, permitindo reiniciar a partida imediatamente sem perda de progresso.
6. **Cena Integrada da Fase (`StageMain.tscn` & `StageMain.gd`):**
   - Montagem do ciclo completo jogável com todas as plataformas e sistemas ativos.

### O que foi testado:
- Carregamento e validação de 17 cenas TSCN.
- Teste da lógica de cálculo de 1 a 3 estrelas:
  - 85% de HP -> 3 Estrelas (75 Ouro na fase 1)
  - 50% de HP -> 2 Estrelas (50 Ouro)
  - 20% de HP -> 1 Estrela (25 Ouro)
- Validação estrutural do arquivo de ondas `world1_waves.json`.

### Decisões tomadas:
- A derrota no jogo é 100% não violenta: o Rei apenas descansa brevemente enquanto o pônei Biscoito o acorda com uma lambida amigável, alinhando com a classificação indicativa Livre a 10 anos.
- As torres atraem os arqueiros mais próximos automaticamente quando o Rei se aproxima com sua formação, sem necessidade de menus complexos ou múltiplos toques.

### O que falta:
- Iniciar a Etapa 3: Vila do Rei e Economia Permanente (edifícios da vila com melhorias instantâneas sem timers, Moinho gerador de ouro passivo, tela de configurações com modo retrô e salvamento local).
