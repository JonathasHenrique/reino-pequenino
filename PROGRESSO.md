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
- Suíte integral de testes automatizados (`tests/test_runner.py`) aprovada com 100% de sucesso.
- Validação real no motor Godot 4.3 headless (`tests/smoke_test.gd`): 20/20 cenas e nós principais instanciados e executados sem falhas.
- Execução do loop principal (`MainMenu.tscn`, `StageMain.tscn`, `Village.tscn`) com término limpo (código 0).
- Workflow de CI/CD para GitHub Actions (`.github/workflows/android_build.yml`) configurado com Godot 4.3 export templates, Java 17, Android SDK e geração automatizada de APK de debug como artefato para download.

### Decisões tomadas:
- O projeto está estruturado de forma completamente desacoplada e orientada a dados, permitindo balancear valores numéricos simplesmente editando os arquivos JSON na pasta `data/`.
- Todos os efeitos sonoros e músicas são gerados proceduralmente em GDScript via síntese de ondas puras (chiptune / som FM nostálgico), garantindo ausência de qualquer arquivo externo com problemas de licença e reduzindo o peso do jogo para poucos megabytes.
- Pipeline de integração contínua (CI) implementado para compilar automaticamente o APK do Android a cada push na branch `main`.

---

## [Etapa 10] Overhaul Visual Diorama, Economia de Pilhagem & Ajustes de Jogabilidade
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. **Loop de Construção e Pilhagem em Tempo Real na Fase:**
   - Inimigos derrotados soltam sucatas e capacetes (`SpoilLoot.tscn`), atraídos pelo ímã do Rei.
   - Rei Teodoro agora empilha duas colunas visuais 3D: à esquerda moedas de ouro (`CoinStack`), à direita capacetes de inimigos (`SpoilStack`) empilhados no alforje do pônei Biscoito.
   - Balcão do Mercador Tobias (`MerchantCounter.tscn`) instalado na base da fase: o Rei entrega os capacetes acumulados e recebe 4 moedas de ouro por peça, com jatos animados de moedas e balões de diálogo temáticos.
   - Construções de apoio em campo: Guilda de Arqueiros (`FieldBarracks.tscn`) treina tropas adicionais periodicamente; Ferraria de Campo (`FieldForge.tscn`) concede bônus temporário de +30% de dano.
2. **Cercamento Perimetral do Acampamento:**
   - Paliçadas (`Palisade.tscn`) agora se organizam em 8 slots perimetrais ordenados, cercando e protegendo a base em arco contra o avanço dos Brumosos.
   - Compras adicionais de paliçada restauram a vida das paliçadas danificadas.
3. **Upgrades Gráficos para Estilo Diorama Vivo:**
   - Criação de props 3D estilizados: Árvore Frondosa de Carvalho (`Tree.tscn`), Pinheiro Cônico em Camadas (`PineTree.tscn`), Rochedos com Musgo (`Rock.tscn`), Cercas Rústicas de Madeira (`WoodenFence.tscn`) e Canteiros de Flores Silvestres (`FlowerPatch.tscn`).
   - Torre de Arqueiros reformulada com 4 pilares de sustentação de madeira, sapatas de pedra, guarda-corpo, toldo e bandeira real tremulando.
   - Rei Teodoro e Pônei Biscoito remodelados em 3D detalhado (patas, arreios, sela de couro, capa real esvoaçante e coroa dourada com rubi).
   - Inclusão de trilhas de terra batida e gramado delimitado na fase principal e praça de paralelepípedos na Vila do Rei.
4. **Resolução de Fronteiras e Movimentação:**
   - Adicionadas barreiras físicas (`Boundaries`) em ambos os mapas (`StageMain` e `Village`) nas quatro bordas (±27) para impedir que o Rei caia no abismo.
   - `King.gd` com `clamp` de coordenadas em `-26.0` a `26.0`.
   - Correção total da movimentação na Vila do Rei: conexão do joystick virtual restaurada e limpeza de sinal de derrota.
5. **Legibilidade Móvel e Polimento Narrativo:**
   - Todas as etiquetas 3D (`Label3D`) nas plataformas de compra, totens, torres, balcão e edifícios foram ampliadas para tamanhos entre 70 e 80, com contornos escuros de alta densidade e ícones visuais para identificação imediata na tela do celular.
   - Remoção de qualquer ambiguidade de texto; telas de derrota e diálogos agora enfatizam a comédia acolhedora entre Teodoro, a avó estrategista Dona Zenaide e as maçãs do pônei guloso Biscoito.

### O que foi testado:
- Suíte integral de testes com 51 cenas e arquivos de dados: 100% aprovado.
- Teste de compilação e execução real em motor Godot 4.3 headless (60 frames em `StageMain.tscn` e `Village.tscn`): 0 erros, saída limpa.
- Integração contínua (CI) no GitHub Actions: compilação do APK do Android validada com sucesso.

---

## [Etapa 11] Fim da Poluição Visual, Limites de Compra, Catapulta 2.0 & Evolução da Vila
**Data:** 1 de Novembro de 2026

### O que foi feito:
1. **Economia de Campo Ajustada (Somente Capacetes):**
   - Inimigos comuns abatidos agora dropam **exclusivamente Capacetes de Bruma (`SpoilLoot`)**. O jogador precisa recolhê-los e levar ao Mercador Tobias para converter em moedas de ouro.
   - Moedas em campo são obtidas apenas com Tobias e na destruição final do Totem como recompensa comemorativa.
2. **Fim da Poluição Visual de Textos:**
   - Remoção completa dos rótulos de texto flutuantes gigantes individuais (`🪵 220/220`) sobre cada pedaço de cerca.
   - Implementação do componente dinâmico `HealthBar3D`: as barras de vida ficam 100% ocultas com vida cheia (deixando o diorama limpo e bonito) e só aparecem com gradiente verde/amarelo/vermelho quando uma estrutura sofre dano.
3. **Plataformas de Compra com Limites e Feedback Claro:**
   - Limites rígidos aplicados: Arqueiros (máx. 10), Torres (máx. 3), Muros (máx. 8), Guilda (máx. 1), Ferraria (máx. 1).
   - Indicação em tempo real de contagem (ex: `🏹 ARQUEIRO (3/10)` e `(COMPLETO)` ao atingir o limite, impedindo desperdício de moedas).
   - Quando o muro de 8 paliçadas é completado e sofre dano, a plataforma muda automaticamente para `🛠️ REPARAR MUROS (🪙 10)`.
4. **Desafio 10 (A Catapulta do Vale) Totalmente Reformulado:**
   - Reconstrução completa da física 2D: agora utiliza velocidade direta com impulso potente (12.5x), arremesso em arco alto sem falhas e câmera com tremor dinâmico nos impactos.
   - Gráficos no estilo arcade cartoon: cenário com colinas verdes, nuvens fofas, estilingue de madeira em Y com elástico duplo animado que estica até a pedra, mira parabólica tracejada e fortaleza de blocos empilhados com destruição satisfatória.
5. **Dificuldade e Ritmo de Invasão (Estilo Plants vs Zombies):**
   - Ondas do Mundo 1 rebalanceadas para 3 a 4 ondas progressivas por fase, com invasões vindas do Leste e do Norte.
   - O Totem permanece invulnerável durante o ataque; ao vencer a última onda, a blindagem mágica quebra com confetes e poeira para o assalto final.
6. **Evolução Visual das Casas da Vila (Estilo Clash of Clans):**
   - Cada edifício agora se transforma visualmente em 3D conforme sobe de nível:
     - Nível 1: Cabana de madeira com telhado rústico.
     - Nível 2: Casa de alvenaria e pedra sólida, telhado vermelho e chaminé.
     - Nível 3+: Castelo fortificado com torreões de canto, ameias de fortaleza e estandarte com brasão dourado.
   - Placa de informações transparente detalhando o benefício exato do nível atual e o bônus da próxima melhoria.
7. **Shader de Chão Procedural Diorama:**
   - Criação de `assets/shaders/ground.gdshader` com grama estilizada multitonal, pequenos detalhes de pedrinhas/flores em coordenadas de mundo e sombras suaves.

### O que foi testado:
- Suíte integral de testes com 51 cenas e dados: 100% aprovado (`tests/test_runner.py`).
- Execução headless no Godot 4.3 de todas as cenas centrais (`StageMain.tscn`, `Village.tscn`, `Challenge10_Catapult.tscn`, `MainMenu.tscn`): 0 erros de GDScript, loop fluído.
