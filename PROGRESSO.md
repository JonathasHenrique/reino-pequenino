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
- Shader de pós-processamento retrô CRT com scanlines e dispersão cromática.
- Partículas 3D diorama de folhas de girassol e brilho dourado de moedas.
- Alternância dinâmica para melodia em onda quadrada (chiptune).

---

## [Etapa 7] Mundos 2 a 5 & Seus 4 Desafios Autorais
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Mundos 2 a 5 Baseados em Dados (36 novas fases):**
   - `world2_waves.json`: Floresta dos Cogumelos (Fases 11 a 19). Desbloqueia o **Escudeiro de Carvalho** na Fase 12.
   - `world3_waves.json`: Penhascos de Mel (Fases 21 a 29). Desbloqueia o **Mago Aprendiz** na Fase 22.
   - `world4_waves.json`: Lago dos Espelhos (Fases 31 a 39). Desbloqueia o **Curandeiro de Campo** na Fase 32.
   - `world5_waves.json`: Pico do Inverno (Fases 41 a 49). Desbloqueia a **Balista de Rodas** na Fase 42.
2. **Desafio 20: Cofre dos Números (`Challenge20_Sudoku.tscn`):**
   - Sudoku místico com grade 4x4, numpad na tela, 3 dicas no Clássico (0 no Veterano) e sem timer.
   - Desbloqueia a 2ª Estrela da Coroa e o **Mago Fidélio**.
3. **Desafio 30: Escudo e Bola (`Challenge30_Breakout.tscn`):**
   - Quebra-blocos autoral com escudo na base, bola radiante, 32 blocos e 3 vidas.
   - Desbloqueia a 3ª Estrela da Coroa e a **Capitã Rosa**.
4. **Desafio 40: A Muralha de Peças (`Challenge40_BlockPuzzle.tscn`):**
   - Grade 8x8 de encaixe autoral, eliminação de linhas completas e meta de 300 pontos.
   - Desbloqueia a 4ª Estrela da Coroa e a **Irmã Clara**.
5. **Desafio 50: A Corrida de Biscoito (`Challenge50_Platformer.tscn`):**
   - Plataforma 2D nostálgica com física de corrida, pulo, coleta de moedas e chegada à bandeira real.
   - Desbloqueia a 5ª Estrela da Coroa e o **Urso Bento**.

### O que foi testado:
- 35 cenas TSCN validadas e funcionais.
- Integridade das 36 fases e desbloqueios de tropas nos Mundos 2, 3, 4 e 5.

### Decisões tomadas:
- Cada minigame funciona como uma cena autocontida com sua própria interface e mecânica, garantindo total isolamento de bugs e variedade máxima de jogabilidade.

### O que falta:
- Iniciar a Etapa 8: Mundo 6 (Castelo Cinzão), Desafio 60 (Jardim da Defesa com 5 faixas e luta em 3 fases contra o Barão Cinzão), desfecho da história (festa com bolo em vez de derrota bélica), Troféus do Reino e Álbum de Figurinhas colecionáveis.
