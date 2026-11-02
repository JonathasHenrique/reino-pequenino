# AGENTS.md — Reino Pequenino

Leia este arquivo inteiro antes de qualquer ação. Responda sempre em português do Brasil.

## 1. O jogo em 5 linhas
- Jogo Android 3D isométrico, offline, em estilo diorama/miniatura colecionável. Godot 4.3, GDScript.
- Paisagem, jogável com UM polegar (joystick virtual flutuante; WASD/teclado no PC).
- Protagonista: Rei Teodoro no cavalo Biscoito. Mercador: Tobias. Vovó: Dona Zenaide.
- Loop de cada fase: defender o acampamento de ondas de monstros da bruma → inimigos soltam CAPACETES (nunca ouro direto) → o Rei recolhe → vende no balcão do Tobias → usa o ouro nos pads de compra (arqueiros, torres de vigia, reparo de muro/portão, Ferraria de Campo, Guilda dos Arqueiros).
- Meta-jogo: Vila do Rei (melhorias permanentes). 60 fases em 6 mundos; fases-desafio com minigames (ex.: Desafio 10 = catapulta estilo estilingue).
- Referências de sensação: Kingshot (ritmo, tropas crescendo) e Clash of Clans/Clash Royale (charme visual, clareza). Referência para "estilo", NUNCA para copiar assets.

## 2. O QUE EU QUERO (objetivo central)
Um jogo BONITO, claro e viciante, no nível de polimento de Kingshot/Clash of Clans:
1. Olhar para a tela do celular e entender em 1 segundo: onde está o Rei, aliados, inimigos, cada pad, quanto custa e quanto ouro tenho.
2. Cenário vivo e enquadrado (não um chão vazio), personagens fofos e legíveis, feedback gostoso (juice).
3. Desafio real: ondas densas estilo Plants vs Zombies; priorizar compras (consertar o muro ou contratar arqueiro?).
4. APK compilando limpo no GitHub Actions.

## 3. ESTADO REAL DO PROJETO (verificado no código — não confie em resumos antigos)
- Todo o visual é gerado por código em `scripts/core/Art.gd` com primitivas (BoxMesh, CylinderMesh, SphereMesh, PrismMesh) e `StandardMaterial3D` liso. Teto de qualidade baixo.
- `assets/models/` e `assets/textures/` estão VAZIOS.
- Existem `assets/shaders/toon_character.gdshader` e `outline_inverted_hull.gdshader`, mas NENHUMA cena/script os usa. Ou seja: o "toon + contorno" nunca foi aplicado de verdade.
- Há WorldEnvironment e DirectionalLight3D (com sombra, tonemap, glow) em `StageMain.tscn`, `StageCoreTest.tscn` e `Village.tscn`, mas sem direção de arte definida.
- Câmera (`scripts/core/IsometricCamera.gd`): distância 17.5, elevação 48° (não 38°), rotação Y 45°.
- `project.godot` não define renderer; no Android o Godot usa o renderer Mobile por padrão (verifique). SSAO/SSIL NÃO existem no Mobile — não dependa deles.
- Testes: `tests/smoke_test.gd` e `tests/test_runner.py`.
- CI: `.github/workflows/android_build.yml` gera o APK a cada push (Godot 4.3).

## 4. REGRAS INEGOCIÁVEIS
- Versão fixa em v1 (1.0.0) na branch main. NUNCA criar v1.1, v1.2, v1.5 etc.
- Tarefa visual/UX: NÃO alterar lógica de gameplay, economia, balanceamento, colisões ou dados em `data/`, a menos que eu peça.
- Offline, sem anúncios, sem rastreamento. Classificação livre (sem sangue; inimigos viram "puf" + capacete).
- Direitos autorais: só assets originais, CC0 ou OFL. Registrar fonte e licença de CADA asset em `CREDITS.md`. Os APKs de referência em `/home/jonathas/Downloads/meu jogo/` servem só para estudar estilo e composição: não extrair nem copiar modelos, texturas, sons ou código deles.
- Um commit por mudança coerente, mensagem em português. Não deixar o build do APK quebrado.
- Nunca dizer "pronto" sem evidência (ver seção 6).

## 5. DIREÇÃO DE ARTE (alvo)
Paleta base (ajustar com bom senso): grama #86C232/#6FA82B · terra #D9A066 · pedra #8E959E (topo com grama) · madeira #8B5A2B · aliado azul #3F7FE0 · inimigo vermelho #D9363E · ouro #FFC93C · UI creme #FFF3D6 · contorno marrom-escuro #2B1B12 (nunca preto puro).
- Formas chunky/chibi: cabeça ~1/3 do corpo, silhueta legível pequena, poucas faces, sem textura ruidosa.
- Luz: DirectionalLight quente (~#FFE3B0), ~50°, sombras suaves; ambiente frio/azulado; tonemap filmic; glow bem leve.
- Toon: aplicar de fato o shader toon (2–3 faixas + rim light) e contorno inverted hull nos personagens e construções principais.
- Diorama: arena como laje flutuante com borda grossa sobre fundo neutro/névoa, como miniatura numa mesa.
- Cenário vivo: trilhas de terra, manchas de grama, flores, pedras, árvores, cercas e rochas enquadrando a arena; balanço leve de grama/árvores; fumaça na ferraria. Usar MultiMesh para repetições.
- Pads: ícone grande desenhado no chão (arco, torre, martelo, bigorna) numa base arredondada; preço numa pílula com moeda; verde se dá para pagar, cinza se não; anel de progresso ao ficar em cima.
- Rei com anel visível do raio de coleta; aliados e inimigos separados por cor + contorno.
- HUD no topo: pílula de ouro, contador de capacetes, barra de onda com número. Nada no centro da tela. Fonte arredondada grossa com contorno (Lilita One ou Fredoka, OFL).
- Juice: números de dano com contorno e pop; flash branco ao tomar dano; squash & stretch; capacetes quicam e são puxados em arco até o Rei; moedas voam em arco até o HUD; construção nova "pipoca" (scale com overshoot) + partículas; poeira nas patas do cavalo; banner "Onda X chegando"; screenshake leve só em impacto grande.
- Modelos: como primitivas por código têm teto baixo, a fase 0 deve avaliar e propor trocar personagens e construções por modelos glTF CC0 (ex.: kits de castelo/vila/natureza do Kenney ou Quaternius) em `assets/models/`, com material toon aplicado e estilo consistente. Eu baixo os pacotes e coloco na pasta; liste exatamente quais precisa.

## 6. COMO TRABALHAR E PROVAR QUE FUNCIONOU
- Use o modo Plan (somente leitura) para a fase 0; só depois mude para Build.
- Godot 4.3 deve estar instalado e no PATH. Para ver o jogo, gere screenshots (ex.: `godot --path . --write-movie /tmp/shots/f.png --fixed-fps 30 --quit-after 120 res://scenes/stages/StageMain.tscn`, com display ou xvfb) e olhe as imagens. Se não conseguir gerar imagens, diga isso claramente e me peça print do celular.
- Rode `tests/test_runner.py` / smoke test antes de cada commit.
- Cada fase termina com: o que mudou, screenshots antes/depois, FPS medido, commit feito.
- Orçamento de performance (Android intermediário): 60 FPS alvo, 30 mínimo; sem MSAA pesado; sombras só na luz direcional, distância curta; poucos draw calls.
- Não me pergunte o que dá para decidir sozinho: assuma, registre a suposição e siga. Pergunte só se estiver realmente bloqueado.

## 7. FASES (uma por vez, commit ao fim de cada)
0. Auditoria: screenshots do estado atual, 10 maiores problemas visuais por prioridade, plano e lista de assets CC0 necessários. NÃO mexer em código.
1. Ambiente: paleta, luz, tonemap, sombras, névoa, laje de diorama.
2. Chão e props: terreno com variação, trilhas, vegetação, cercas, rochas.
3. Personagens e construções: toon + contorno, proporções chibi (Rei, cavalo, arqueiros, inimigos, Tobias).
4. Pads e HUD: ícones no chão, preços em pílula, estados pode/não pode pagar, HUD superior.
5. Juice e VFX.
6. Performance: medir FPS e draw calls, ajustar o que passar do orçamento.

## 8. CRITÉRIOS DE ACEITE
- Em um screenshot de celular dá para identificar em 1 segundo: Rei, aliados, inimigos, cada pad, preço e ouro.
- Nenhum texto gigante nem elemento cobrindo o Rei.
- Antes/depois visivelmente melhor em cada fase.
- Sem regressão de jogabilidade; FPS dentro do orçamento; APK compila no GitHub Actions.
