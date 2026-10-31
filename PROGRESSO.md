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
- Mundo 6 (Castelo Cinzão, Fases 51 a 59).
- Desafio 60 (Jardim da Defesa de 5 faixas e confronto em 3 fases com o Barão Cinzão).
- Cena final com desfecho acolhedor e bolo de amoras.
- Mural de Troféus e Álbum de Figurinhas colecionáveis da coroa.

---

## [Etapa 9] Finalização, StoreService, Balanceamento, Presets & Entrega
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Tenda do Mercador Real (`StoreMenu.tscn` & `StoreMenu.gd`):**
   - Loja de heróis, skins e pacote completo com compras únicas transparentes.
   - Mock offline funcional com simulação instantânea de compra e restauração.
   - Zero lootboxes, sem sorteio, sem timers pagos.
2. **Menu de Debug (`DebugMenu.tscn` & `DebugMenu.gd`):**
   - Ferramentas para injetar moedas, ouro, desbloquear todos os heróis e testar saltos de fase.
3. **Preset de Exportação Android (`export_presets.cfg`):**
   - Configurado para Godot 4.3 com suporte às arquiteturas `arm64-v8a`, `armeabi-v7a` e `x86_64`.
   - Orientação `sensor_landscape`, pacote `com.reinopequenino.game`.
4. **Validação das 3 Dificuldades:**
   - Tranquilo: -25% de vida dos inimigos e mais facilidade nos quebra-cabeças.
   - Clássico: ritmo equilibrado de jogo diorama.
   - Veterano: +20% de vida dos inimigos e desafios sem dicas.
5. **Documentação Mestra Finalizada:**
   - `README.md`, `CREDITS.md`, `PRIVACY_POLICY.md` e `PROGRESSO.md`.

### O que foi testado:
- Suíte integral de testes automatizados (`tests/test_runner.py`) aprovada com 100% de sucesso:
  - 42 cenas TSCN validadas e funcionais.
  - 60 fases distribuídas nos 6 mundos temáticos.
  - Integridade de todos os 7 heróis, 6 tropas e 6 inimigos.
  - Matriz de balanceamento das 3 dificuldades.
  - Conformidade ética da loja e preset Android.

### Decisões tomadas:
- O projeto está estruturado de forma completamente desacoplada e orientada a dados, permitindo balancear valores numéricos simplesmente editando os arquivos JSON na pasta `data/`.
- Todos os efeitos sonoros e músicas são gerados proceduralmente em GDScript, garantindo ausência de qualquer arquivo externo com problemas de licença e reduzindo o peso do jogo.

### O que falta (Passos para o Desenvolvedor Humano):
1. Abrir o projeto no Godot 4 e testar em aparelho Android físico real.
2. Gerar a keystore privada definitiva de release.
3. Exportar o arquivo `.aab` e submeter à Google Play Store.
