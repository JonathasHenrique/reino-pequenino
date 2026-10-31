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

### O que foi feito:
1. **Desafio 10: A Catapulta do Vale (`Challenge10_Catapult.gd` & `Challenge10_Catapult.tscn`):**
   - Módulo independente de lançamento 2D com física autoral (`RigidBody2D`).
   - Mecânica de arrastar, puxar e soltar com linha de trajetória pontilhada em tempo real.
   - Estrutura de blocos de madeira e totem cinzento alvo com física de queda e tombamento.
   - Sistema de 3 a 5 tentativas com cálculo de estrelas baseado nos pedregulhos poupados.
2. **Projétil do Desafio (`CatapultRock.tscn`):**
   - Rocha de brinquedo com massa, fricção e quique calibrados para destruição satisfatória.
3. **Tela de Vitória de Desafio (`ChallengeVictoryScreen.gd` & `ChallengeVictoryScreen.tscn`):**
   - Animação festiva da recuperação da 1ª Estrela da Coroa Mãe.
   - Apresentação da nova Heroína desbloqueada: **Marta, a Ferreira** (passiva: -15% de custo em construções; ativa: conserta e reforça todas as torres).
   - Integração com `MiniGameRunner.gd`, `SaveManager.gd` (registro da estrela 1, figurinha e troféu).

### O que foi testado:
- 28 cenas TSCN validadas e funcionais.
- Mapeamento completo dos 6 desafios e heróis recompensados no `MiniGameRunner`.
- Confirmação dos atributos e passiva de desconto de Marta em `heroes.json`.

### Decisões tomadas:
- O minigame da catapulta é 100% autoral, operando em física pura do Godot 2D sem copiar qualquer asset, pássaro ou mecânica de jogos protegidos por direitos autorais.
- A contagem de tentativas é ajustada automaticamente pela dificuldade escolhida nas configurações (5 no Tranquilo, 4 no Clássico e 3 no Veterano).

### O que falta:
- Iniciar a Etapa 6: Arte e Áudio Finais do Mundo 1 (shader de Modo Retrô com scanlines CRT sutis, iluminação de diorama toon, polimento de partículas e chiptune).
