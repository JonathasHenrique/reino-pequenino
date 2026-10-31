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

### O que foi feito:
1. **Cena da Vila Real Isométrica (`Village.tscn` & `Village.gd`):**
   - Cenário pacífico em maquete com gramado, luz quente de entardecer e navegação do Rei Teodoro com seu pônei Biscoito.
2. **Edifícios e Melhorias Instantâneas (`VillageBuilding.gd` & `VillageBuilding.tscn`):**
   - Quartel Real (aumenta o dano base das tropas).
   - Ferraria da Vila (reduz custo de plataformas em combate).
   - Estábulo do Biscoito (aumenta vida e velocidade do Rei).
   - Taverna dos Viajantes (seleção rápida de heróis).
   - Mural da Coroa Mãe (exibe as Estrelas da Coroa conquistadas).
   - **Zero timers de espera artificial:** melhorias funcionam instantaneamente com gasto de Ouro!
3. **Moinho e Fazenda (`Mill.gd` & `Mill.tscn`):**
   - Pás animadas girando suavemente em 3D.
   - Geração de Ouro passivo ao longo do tempo com acúmulo offline e limite máximo (Cap de 100 Ouro no nível 1, escalonando até 300).
   - Coleta instantânea de Ouro ao passar perto do moinho.
4. **Painel Completo de Configurações (`SettingsMenu.tscn` & `SettingsMenu.gd`):**
   - Sliders de volume de música e efeitos sonoros.
   - Alternância de vibração háptica no celular.
   - Seletor das 3 Dificuldades: Tranquilo, Clássico e Veterano.
   - Alternador do Modo Retrô (filtro CRT e variação chiptune) e Redução de Efeitos Visuais (acessibilidade).
   - Seletor de idioma (Português pt-BR / English en).
5. **HUD da Vila (`VillageHUD.tscn` & `VillageHUD.gd`):**
   - Monitoramento do saldo de Ouro permanente, estrelas da coroa recuperadas e acesso à batalha.

### O que foi testado:
- 22 cenas TSCN validadas e funcionais.
- Curva de progressão de custos das construções da vila estritamente crescente.
- Simulação de acumulação do Moinho: 10 minutos = 60 Ouro; 24 horas retido no teto de 100 Ouro no nível 1.
- Teste de resiliência a corrupção do arquivo de save com recuperação do backup `.bak`.

### Decisões tomadas:
- Sem esperas pagas ou timers artificiais para melhorias: o jogador investe seu Ouro e a vila evolui na hora, preservando a experiência autêntica de jogo clássico.
- O moinho grava o timestamp de coleta no savegame local, calculando os ganhos offline de forma justa sem requerer conexão de rede.

### O que falta:
- Iniciar a Etapa 4: Mundo 1 Completo (todas as 9 fases normais do Vale dos Girassóis, diálogos com humor em duas camadas com Dona Zenaide, tutorial progressivo e cena de abertura).
