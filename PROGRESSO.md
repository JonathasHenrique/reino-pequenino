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
- Fases 11 a 49 estruturadas em dados com escalonamento equilibrado.
- Desafios 20 (Sudoku), 30 (Quebra-blocos), 40 (Muralha de Peças) e 50 (Corrida de Biscoito 2D).
- Desbloqueio das Estrelas 2, 3, 4 e 5 e seus heróis respectivos.

---

## [Etapa 8] Mundo 6, Batalha Final, Desfecho Redentor, Troféus & Álbum de Figurinhas
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Mundo 6: Castelo Cinzão (`world6_waves.json`):**
   - 9 fases avançadas (Fases 51 a 59) no castelo de pedra cinzenta que ganha cor conforme Teodoro e seu exército avançam.
2. **Desafio 60: Jardim da Defesa (`Challenge60_LaneDefense.tscn`):**
   - Minigame autoral de 5 faixas defensivas sem cópia de jogos comerciais.
   - Estrelas cadentes caem e o jogador toca na tela para coletar faíscas estelares.
   - Posicionamento tático de arqueiros, lanceiros, barris de mel desaceleradores e magos.
   - Batalha contra o chefe final **Barão Cinzão** em 3 fases climáticas.
   - Desbloqueia a 6ª e última Estrela da Coroa e o **Barão Cinzão (Redimido)** como Herói selecionável.
3. **Cena Final da Festa do Reino (`EndingCutscene.tscn` & `EndingCutscene.gd`):**
   - O Barão Cinzão é acolhido com bolo de amoras e chapéu festivo colorido pela Dona Zenaide e pelo jovem Rei Teodoro em vez de violência.
4. **Mural de Troféus do Reino (`TrophiesMenu.tscn` & `TrophiesMenu.gd`):**
   - Sistema de conquistas (`first_victory`, `catapult_master`, `sudoku_wizard`, `shield_hero`, `village_architect`, `full_crown`).
5. **Álbum de Figurinhas Colecionável (`StickerAlbum.tscn` & `StickerAlbum.gd`):**
   - Coleção das 6 Estrelas da Coroa em cartões nostálgicos com descrição e raridade.

### O que foi testado:
- 40 cenas TSCN validadas e funcionais.
- Integridade do Mundo 6 (Fases 51 a 59).
- Total de 6 Troféus e 6 Figurinhas da Coroa validados no banco de dados JSON.

### Decisões tomadas:
- O desfecho consolida a filosofia do jogo: classificação indicativa Livre a 10 anos com afeto, sem derrotas humilhantes ou violência gráfica.

### O que falta:
- Iniciar a Etapa 9: Finalização (StoreService integrado com UI da loja de heróis e cosméticos, balanceamento fino das 3 dificuldades, menu de debug, documentação final e instruções de empacotamento do APK/AAB).
