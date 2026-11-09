# Relatório de Auditoria e Implementação — Reino Pequenino / Tiny Crown

**Data:** Novembro de 2026  
**Versão:** v1 (1.0.0)  
**Engine:** Godot 4.3 (GDScript, Linux / Android Mobile Target)

---

## 1. Músicas de Fundo Reais (Fim do Áudio Robótico)
- **Criação de Diretórios:** Criadas as pastas `res://assets/audio/music/` e `res://assets/audio/sfx/`.
- **Trilhas em Formato OGG Vorbis (Licença CC0 / Domínio Público):**
  - `village_theme.ogg` — *Quaint Town* por neonarkade (clima acolhedor de vila medieval com cordas e flautas acústicas).
  - `battle_theme.ogg` — *Determined Pursuit* por Emma_MA (orquestração épica dinâmica com percussão e metais).
  - `prologue_theme.ogg` — *Fantasy Orchestral Theme* por Joth (tema narrativo emocional de contação de histórias).
- **SFX de Corneta de Guerra (`war_horn.ogg`):**
  - Fanfarra heroica D4-G4-B4-D5 em camadas polifônicas para o disparo do Grito de Coragem e poderes heroicos.
- **Modernização do `AudioManager.gd`:**
  - Implementação de reprodutor duplo com interpolação de `crossfade` linear/suave (0.65s).
  - Sistema de prioridade para carregar arquivos de áudio externos em disco com fallback automático e transparente para os geradores procedurais caso algum arquivo falte.
- **Atribuições de Licença:** Atualizado o arquivo `CREDITS.md` com links, fontes e licenças CC0 completas.

---

## 2. Rebranding Comercial Global e Títulos Dinâmicos
- **Configuração do Projeto (`project.godot`):**
  - Nome principal alterado para **"Tiny Crown: Kingdom Defense"** para apelo internacional nas lojas de aplicativos.
- **Títulos e Subtítulos Dinâmicos por Idioma:**
  - **Inglês (`en`):** `TINY CROWN` — *The Quest for the Six Mother Crown Stars*
  - **Português (`pt`):** `REINO PEQUENINO` — *A Aventura das Seis Estrelas da Coroa Mãe*
  - **Espanhol (`es`):** `REINO PEQUEÑITO` — *La Aventura de las Seis Estrellas de la Corona Madre*
- **Reatividade na Interface:** Telas `MainMenu.gd` e `IntroCutscene.gd` conectadas ao sinal `I18n.language_changed`, atualizando títulos, botões e descrições instantaneamente na troca de idioma.

---

## 3. Auditoria Matemática de Heróis e Feedback Visual de Buffs
Foram auditadas e validadas todas as mecânicas passivas e ativas do elenco de heróis:

| Herói | Habilidade Ativa | Efeito Matemático / Passiva | Cor do Buff / Efeito |
| :--- | :--- | :--- | :--- |
| **Rei Teodoro** | Grito de Coragem | Tropas ganham +30% velocidade de ataque por 8s; Ímã do Rei +35% raio. | **Dourado-Fogo** (`#FFBF26`) + Texto `⚡ +30% SPEED!` |
| **Marta, a Ferreira** | Martelada Mestra | Repara instantaneamente todas as paliçadas ativas; Passiva: 15% desconto em compras de pads. | **Vermelho-Brasa** (`#FF5926`) + Reparo em área |
| **Fidélio, o Mago** | Explosão Arcana | Elimina/empurra monstros ao redor; Passiva: +10% dano base de todas as tropas aliadas. | **Azul-Mágico** (`#40A6FF`) + Onda de choque arcana |
| **Rosa, a Paladina** | Escudo Sagrado | Concede invulnerabilidade temporária ao Rei; Passiva: Tropas sofrem 15% menos dano. | **Rosa-Bravura** (`#FF66B2`) + Barreira sagrada |
| **Clara, a Druida** | Raízes Protetoras | Imobiliza monstros na arena; Passiva: Regeneração contínua de vida do Rei e aliados. | **Verde-Esmeralda** (`#59FF73`) + Cura gradual |
| **Bento, o Alquimista**| Chuva de Ouro | Converte capacetes na tela com bônus; Passiva: Aumenta em +1 o valor dos capacetes vendidos no Tobias. | **Dourado-Riqueza** (`#FFE033`) + Moedas adicionais |
| **Barão Von Brawn** | Névoa Protetora | Desacelera significativamente os monstros próximos ao Rei por 6s. | **Ciano-Névoa** (`#33E6E6`) + Retardo de movimento |

### Feedback Visível e Audível ao Usar o Poder:
1. Disparo de SFX potente de `war_horn` via `AudioManager`.
2. Onda de choque cilíndrica 3D luminosa expandindo a partir do Rei.
3. Leve tremor de câmera dinâmico (`camera.shake(0.22, 0.35)`).
4. Aplicação de `material_overlay` emissivo pulsante nas tropas aliadas + anel luminoso aos pés com fade-out gradual após 8 segundos.
5. Emissão de texto flutuante estilizado acima de cada tropa (`"⚡ +30% SPEED!"` / `"⚡ +30% VELOCIDADE!"`).
6. Atualização em tempo real do botão no HUD:
   - Durante o buff: `"🔥 8s..."` com contagem regressiva;
   - Em recarga: `"⏳ 15s"` com indicador de cooldown;
   - Quando pronto: Nome localizado da habilidade com destaque dourado.

---

## 4. Retratos de Diálogo e Integração das Melhorias da Vila
- **Substituição de Letras Soltas por Retratos Estilizados:**
  - Criados avatares de alta resolução (256x256 com anel dourado e alfa) em `assets/ui/portraits/` para:
    * `zenaide.png` (Dona Zenaide — conselheira real com sorriso acolhedor);
    * `teodoro.png` (Rei Teodoro — jovem soberano com coroa reluzente);
    * `tobias.png` (Tobias — mercador esperto com boina e ouro);
    * `marta.png` (Marta — ferreira e caçadora de capuz);
    * `barao.png` (Barão — nobre com cartola e monóculo).
  - Atualizada a cena `DialogueBox.tscn` com `TextureRect` dedicado (`PortraitImage`).
  - Atualizado `DialogueBox.gd` para mapear automaticamente os retratos por interlocutor e ocultar totalmente o label de texto antigo, garantindo que letras como `"Z"` nunca mais apareçam na interface.
- **Validação das Melhorias da Vila (`SaveManager.village_buildings`):**
  - **Quartel (`barracks`):** Concede +10% de dano base por nível a todas as tropas aliadas geradas (`FollowerTroop.gd`).
  - **Estábulo (`stable`):** Concede +20 de vida máxima ao Rei e +0.25 de velocidade de deslocamento por nível (`GameState.gd` e `King.gd`).
  - **Ferreiro (`blacksmith`):** Concede 5% de desconto cumulativo por nível em todas as plataformas de compra (`PurchasePad.gd`) para contratações e reparos, combinando perfeitamente com a passiva da heroína Marta.
  - **Muralha da Coroa (`crown_wall`):** Aumenta as moedas iniciais de cada fase (`23 + 6 + 4 * (nível - 1)`) e vida do Rei.

---

## 5. Layout e Prevenção de Sobreposições no HUD
- A caixa de diálogo (`DialogueBox.gd`) agora possui elevação calculada em relação à base da tela (`offset_bottom = -135.0`), mantendo uma área limpa de segurança para os botões de ação e toque móvel no canto inferior direito.
- Diálogos pausam e ocultam notificações temporárias para evitar poluição visual durante tutoriais e avisos da história.

---

## 6. Melhorias Estruturais e Validação Visual com Screenshots (Outubro/Novembro 2026)

1. **Orientação dos Inimigos e Escala do Mapa (`Enemy.gd`, `FollowerTroop.gd`, `IsometricCamera.gd`, `StageMain.tscn`, `StageCoreTest.tscn`):**
   - Corrigida a rotação das malhas de inimigos (`visuals.rotation.y` com `atan2(dir.x, dir.z) + PI` e pivô `ChibiPivot` dedicado com `rotate_pi = true`), garantindo que todos os inimigos da bruma olhem e corram de frente para o Rei e para as defesas.
   - `Camera3D` afastada em ~20% (`camera_distance` de `19.5` para `23.4` em `StageMain.tscn`/`IsometricCamera.gd` e de `17.5` para `21.0` em `StageCoreTest.tscn`) e escala de tropas e inimigos reduzida em ~15%.

2. **Sistema Real de 3 Estrelas na Vitória (`GameState.gd`, `Palisade.gd`, `VictoryScreen.gd/.tscn`):**
   - Cálculo de estrelas atualizado para refletir o desempenho real na batalha:
     * **1 Estrela:** Vencer a fase.
     * **2 Estrelas:** Vencer mantendo o HP do Rei >= 50%.
     * **3 Estrelas:** Vencer mantendo o HP do Rei >= 85% sem perder defesas principais (`lost_main_defense == false`).
   - Critérios das 3 estrelas exibidos na tela de Vitória (`VictoryScreen.tscn`) e traduzidos em `pt`, `en` e `es`.

3. **Reformulação da Vila (`VillageBuilding.gd`, `Village.tscn`, `VillageDecor.gd`):**
   - Espaçamento vertical ampliado entre `label_level` (`top + 1.5`) e `label_upgrade` (`top - 1.6`) nos edifícios para eliminar qualquer sobreposição.
   - Gramado (`PlaneMesh_ground` e `BoxShape3D_floor`) expandido em 3x (`80x80` -> `240x240`), perímetro fechado por um anel organizado de 38 paliçadas (`PerimeterPalisades`) e edifício superior (`Blacksmith`) reposicionado para `(-13, 0, -9.5)` longe da barra superior do HUD.

4. **Mapa de Linha do Tempo das Fases (`StageTimeline.gd/.tscn`, `VillageHUD.gd`):**
   - O botão `Battle` na Vila abre a Linha do Tempo das Fases com os 10 nós do mundo atual conectados por trilha tracejada, estrelas conquistadas (`★`/`☆`), emblema de coroa na fase atual, cadeados nas fases bloqueadas e abas para os 6 mundos.

5. **Ilustrações do Prólogo e Cortina de Bruma (`IntroCutscene.gd`, `SceneTransition.gd`):**
   - Exibição das ilustrações `res://assets/ui/illustrations/prologue_1.png`, `prologue_2.png` e `prologue_3.png` no fundo do Prólogo com transição suave a cada fala da Dona Zenaide, `ShaderMaterial` (`story_illustration.gdshader`) e `DialogueBox` centralizada em 940px.
   - Transição suave com cortina de bruma e fade (`CanvasLayer` + `Tween` em `SceneTransition.gd`) entre Prólogo, Vila e Fases.

6. **Screenshots Gerados e Inspecionados via Godot 4.3:**
   - `tests/print_prologue.png` (Prólogo com ilustração, shader e retrato da Dona Zenaide)
   - `tests/print_village.png` (Vila com gramado 3x, anel de paliçadas e textos espaçados)
   - `tests/print_timeline.png` (Mapa de Linha do Tempo das Fases com trilha tracejada, estrelas e cadeados)
   - `tests/print_battle.png` (Batalha com câmera afastada em 20%, tropas/inimigos reduzidos em 15% e inimigos encarando o Rei de frente)
   - `tests/print_victory_3stars.png` (Tela de Vitória com os critérios reais das 3 estrelas)

---
*Relatório compilado para a equipe de QA e Engenharia de Software.*

