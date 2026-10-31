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

### O que foi feito:
1. **Configuração Integral das 9 Fases do Mundo 1 (`world1_waves.json`):**
   - Curva suave de aprendizado e escalonamento de vida dos totens (de 120 HP na Fase 1 até 450 HP na Fase 9).
   - Inimigos variados introduzidos progressivamente: Brumoso Corredor, Brumoso Escudeiro, Arqueiro de Névoa, Corvo Cinzento voador e o mini-chefe Gigante da Bruma na Fase 9.
   - Desbloqueio da tropa do Lanceiro na Fase 5.
2. **Cena de Abertura Narrativa (`IntroCutscene.tscn` & `IntroCutscene.gd`):**
   - Apresentação da história das 6 Estrelas da Coroa Mãe e o Barão Cinzão amuado por não ter sido chamado para o baile.
   - Humor em duas camadas: fofura para crianças e ironia madura para jovens adultos.
3. **Caixa de Diálogo Reutilizável (`DialogueBox.tscn` & `DialogueBox.gd`):**
   - Retrato expressivo de Dona Zenaide, avanço por toque na tela ou botão e efeitos sonoros de clique.
4. **Tutorial Progressivo nas Fases 1 a 3:**
   - Fase 1: Movimento com joystick e atração magnética de moedas.
   - Fase 2: Uso das plataformas de compra gradual para contratar arqueiros.
   - Fase 3: Táticas de defesa com paliçadas e foco na destruição do Totem.
5. **Menu Principal do Jogo (`MainMenu.tscn` & `MainMenu.gd`):**
   - Ponto de entrada com logo da coroa dourada, acesso à jornada, à vila e aos ajustes.

### O que foi testado:
- 25 cenas TSCN validadas e funcionais.
- Integridade das 9 fases de ondas do Mundo 1.
- Verificação do desbloqueio do Lanceiro na Fase 5 e surgimento do Gigante na Fase 9.

### Decisões tomadas:
- O botão "Pular História" na introdução permite aos jogadores retornarem rapidamente ao combate caso reiniciem o jogo.
- O diálogo do tutorial aparece apenas nas primeiras fases para não interromper a fluidez de ritmo nas fases avançadas.

### O que falta:
- Iniciar a Etapa 5: Sistema de Minigames & Desafio 10 (A Catapulta do Vale com física 2D de lançamento em alvos de blocos cinzentos, desbloqueio da 1ª Estrela da Coroa e da Heroína Marta, a Ferreira).
