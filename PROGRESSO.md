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
- Totem de Bruma interativo com emissão de névoa e vitória na destruição.
- Gerenciador de ondas baseado em dados JSON (`world1_waves.json`).
- Torres de Vigia com arqueiros guarnecidos e paliçadas protetoras.
- Indicadores direcionais nas bordas da tela.
- Telas de Vitória (1 a 3 estrelas) e Derrota amigável sem violência.

---

## [Etapa 3] Vila do Rei, Economia & Configurações
**Data:** 31 de Outubro de 2026
- Vila Real isométrica com navegação do Rei Teodoro.
- Edifícios com melhorias instantâneas em Ouro (Quartel, Ferraria, Estábulo, Taverna, Mural da Coroa) sem timers.
- Moinho de Vento com geração passiva de Ouro offline e limite progressivo.
- Menu de Configurações completo (volume, vibração, 3 dificuldades, modo retrô, redução de efeitos e idiomas).

---

## [Etapa 4] Mundo 1 Completo: 9 Fases, Tutorial Dona Zenaide & Cena de Abertura
**Data:** 31 de Outubro de 2026
- Progressão das 9 fases do Vale dos Girassóis com escalonamento de Totens (120 a 450 HP).
- Inimigos variados, desbloqueio de Lanceiro na Fase 5 e Gigante de Névoa na Fase 9.
- Cena de abertura narrativa e tutorial progressivo nas fases 1 a 3 com diálogos da Dona Zenaide.
- Menu principal configurado.

---

## [Etapa 5] Sistema de Minigames & Desafio 10 (A Catapulta do Vale)
**Data:** 31 de Outubro de 2026
- Módulo independente de lançamento 2D com física autoral e trajetória dinâmica.
- Torre de blocos e totem tombável com estrelas baseadas nas pedras poupadas.
- Tela de vitória comemorativa resgatando a 1ª Estrela da Coroa e desbloqueando Marta, a Ferreira.

---

## [Etapa 6] Arte & Áudio Finais do Mundo 1: Estilo Diorama, Shader Retrô & Partículas
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Shader do Modo Retrô (`retro_crt.gdshader` & `RetroFilterOverlay.tscn`):**
   - Efeito nostálgico opcional inspirado em fliperama e tubo CRT: scanlines suaves horizontais, sutil dispersão cromática e tom quente.
   - Registrado como Autoload global (`RetroFilterOverlay`), ativado/desativado instantaneamente pelas configurações sem recarregar telas.
2. **Partículas Atmosféricas de Diorama:**
   - **Folhas de Girassol em Queda (`FallingLeaves.tscn`):** Sistema leve de partículas 3D (`GPUParticles3D`) simulando o clima de fim de tarde no Vale dos Girassóis.
   - **Brilho Dourado de Coleta (`CoinSparkle.tscn`):** Estrelinhas cintilantes ao coletar moedas por ímã e preencher plataformas.
3. **Acessibilidade e Desempenho:**
   - Opção "Reduzir Efeitos Visuais" em `Settings.gd` desativa partículas pesadas para garantir 60 fps em aparelhos mais modestos.
4. **Áudio Chiptune Dinâmico:**
   - O `AudioManager.gd` alterna dinamicamente o timbre das melodias de onda senoidal/triangular para onda quadrada pura (*square wave*) de 8-bits quando o Modo Retrô está ativo.

### O que foi testado:
- 31 cenas TSCN validadas e funcionais.
- Integridade do código GLSL do shader CRT.
- Validação da flag de redução de efeitos visuais para acessibilidade.

### Decisões tomadas:
- O shader opera em camada de tela independente (`layer = 100`) com `mouse_filter = 2 (IGNORE)`, garantindo que controles de toque, joysticks e botões nunca sejam bloqueados pelo filtro visual.

### O que falta:
- Iniciar a Etapa 7: Mundos 2 a 5 (cada um com 9 fases e seu respectivo desafio autoral: Sudoku Místico, Quebra-blocos de Luz, Muralha de Peças e Corrida de Biscoito 2D).
