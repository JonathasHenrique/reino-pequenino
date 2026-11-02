# PLANO DE EXECUÇÃO — REINO PEQUENINO (Overhaul Visual Kingshot / Clash of Clans)

> **Instrução para o Agente OpenCode:**
> Leia este documento junto com o `AGENTS.md` na raiz do projeto. Execute as tarefas abaixo na ordem estipulada, mantendo a versão `1.0.0` (nunca altere a numeração de versão), sem quebrar a lógica de gameplay/economia e rodando `python3 tests/test_runner.py` após cada etapa para validar a integridade do projeto.

---

## TAREFA 1: Corrigir Entidades Andando de Costas (Rei, Tropas e Inimigos)

### Diagnóstico Técnico
Em `scripts/core/Art.gd`, todos os personagens (`build_king`, `build_archer`, `build_mist_runner`, etc.) foram modelados com a frente (rosto, olhos, focinho do cavalo) apontando para o eixo **+Z** e as costas/rabo apontando para **-Z**.
Porém, no Godot, `look_at()` e `atan2(-x, -z)` alinham o eixo **-Z** com a direção do movimento, fazendo o cavalo Biscoito, os arqueiros e os monstros andarem de costas.

### O que alterar:
1. **`scripts/entities/King.gd`**:
   - Na função `_physics_process`, localize o cálculo de `target_angle` (aprox. linha 74).
   - Substitua:
     ```gdscript
     var target_angle := atan2(-move_dir.x, -move_dir.z)
     ```
   - Por:
     ```gdscript
     var target_angle := atan2(move_dir.x, move_dir.z)
     ```

2. **`scripts/entities/FollowerTroop.gd`**:
   - Onde houver `visual.look_at(global_position + dir, Vector3.UP)` ou `visual.look_at(target_pos, Vector3.UP)`, inverta o vetor alvo para que o eixo `+Z` do `visual` olhe para o destino:
     ```gdscript
     var look_dir := (target_pos - global_position)
     look_dir.y = 0.0
     if look_dir.length_squared() > 0.001:
         visual.rotation.y = lerp_angle(visual.rotation.y, atan2(look_dir.x, look_dir.z), delta * 12.0)
     ```

3. **`scripts/entities/Enemy.gd`**:
   - Da mesma forma, substitua o `look_at` que faz os inimigos olharem em `-Z` por rotação em `Y` usando `atan2(dir.x, dir.z)` com `lerp_angle`, garantindo que os olhos do monstro fiquem virados para a direção em que ele avança.

---

## TAREFA 2: Ativar Toon Shader Real + Contorno (Outline) em `Art.gd`

### Diagnóstico Técnico
Os shaders `assets/shaders/toon_character.gdshader` e `assets/shaders/outline_inverted_hull.gdshader` existem no projeto, mas `scripts/core/Art.gd` instancia apenas `StandardMaterial3D` comum na função `toon_mat()`, deixando o jogo com aspecto de plástico sem contorno.

### O que alterar em `scripts/core/Art.gd`:
1. Adicione o pré-carregamento dos shaders no topo do script:
   ```gdscript
   const TOON_SHADER = preload("res://assets/shaders/toon_character.gdshader")
   const OUTLINE_SHADER = preload("res://assets/shaders/outline_inverted_hull.gdshader")
   ```
2. Crie uma função auxiliar estática para o material de contorno:
   ```gdscript
   static func get_outline_mat(width: float = 0.024) -> ShaderMaterial:
       var key := "outline_%.3f" % width
       if _mat_cache.has(key):
           return _mat_cache[key]
       var mat := ShaderMaterial.new()
       mat.shader = OUTLINE_SHADER
       mat.set_shader_parameter("outline_color", C_OUTLINE) # Color("#2B1B12")
       mat.set_shader_parameter("outline_width", width)
       _mat_cache[key] = mat
       return mat
   ```
3. Atualize `toon_mat()` para usar `ShaderMaterial` com `TOON_SHADER` e `next_pass = get_outline_mat(0.024)` quando `emission_energy <= 0.0`. Para materiais emissivos (`emission_energy > 0.0`), mantenha o `StandardMaterial3D` com emissão ativa.
4. Certifique-se de que a paleta base em `Art.gd` respeite as cores vibrantes estilo *Kingshot* / *Clash of Clans*:
   - Grama: `#86C232` e `#6FA82B`
   - Terra: `#D9A066`
   - Pedra: `#8E959E`
   - Madeira: `#8B5A2B`
   - Aliado Azul: `#3F7FE0`
   - Inimigo Vermelho: `#D9363E`
   - Ouro: `#FFC93C`
   - Contorno: `#2B1B12` (marrom escuro, nunca preto puro).

---

## TAREFA 3: Reformular a Tela Inicial (`MainMenu.gd` e `MainMenu.tscn`)

### Diagnóstico Técnico
A tela inicial atual (`MainMenu.tscn`) usa um `ColorRect` escuro estático e botões padrão do Godot sem `StyleBox`, parecendo um menu de debug.

### O que alterar em `scripts/ui/MainMenu.gd`:
1. **Fundo Vibrante e Nostálgico**:
   - Substitua o fundo escuro por um `TextureRect` em tela cheia com `GradientTexture2D` vertical indo de Azul Real Profundo (`#1B3B6F`) no topo até Azul Celeste Vibrante (`#3F7FE0`) na base, com uma faixa inferior quente ou vinheta suave.
2. **Tipografia Estilo Clash of Clans no Título**:
   - No `TitleLabel`: cor `#FFC93C` (Ouro), `font_outline_color` = `#2B1B12`, `outline_size` = `16`, `shadow_color` = `Color(0, 0, 0, 0.65)`, `shadow_offset_y` = `6`, `font_size` = `54`.
   - No `SubtitleLabel`: cor `#FFF3D6` (Creme), `font_outline_color` = `#2B1B12`, `outline_size` = `8`, `font_size` = `20`.
3. **Botões "Chunky Toy UI" (Estilo Mobile Profissional)**:
   - Crie uma função `_style_chunky_button(btn: Button, top_col: Color, bottom_lip_col: Color, text_col: Color = Color.WHITE)` que aplique `StyleBoxFlat` em `normal`, `hover`, `pressed` e `disabled`:
     - Cantos arredondados (`corner_radius = 14`).
     - Borda lateral/superior de `3px` e **borda inferior de `7px`** (`border_width_bottom = 7`) com cor escurecida para criar efeito físico 3D.
     - No estado `pressed`, reduza `border_width_bottom` para `3px` para simular o clique físico.
     - Adicione animação de *bounce* (`scale` via `Tween`) nos sinais `button_down` (`0.95`) e `button_up` (`1.03` -> `1.0`).
   - Cores dos botões:
     - **Continuar**: Verde Esmeralda (`#58CC02` / `#46A302`)
     - **Novo Jogo**: Amarelo Ouro (`#FFC93C` / `#D99B26`)
     - **Vila do Rei**: Azul Real (`#3F7FE0` / `#2B5BA8`)
     - **Troféus e Figurinhas**: Creme (`#FFF3D6` / `#D9C398`) com texto `#2B1B12`
     - **Loja**: Laranja Vibrante (`#FF9600` / `#CC7800`)
     - **Configurações**: Cinza Pedra (`#8E959E` / `#686F77`)
     - **Sair**: Vermelho Rubi (`#D9363E` / `#A6242B`)

---

## TAREFA 4: Pads de Compra no Chão Estilo Kingshot (`PurchasePad.gd`)

### Diagnóstico Técnico
No *Kingshot*, os pads no chão são placas quadradas com cantos arredondados coladas ao solo, com borda branca/dourada, ícone claro desenhado no centro e fundo que fica **verde vivo** quando o jogador tem moedas suficientes para comprar, ou **cinza/bege** quando não pode pagar.

### O que alterar em `scripts/entities/PurchasePad.gd` e `PurchasePad.tscn`:
1. **Geometria e Altura**:
   - Deixe o pad bem rente ao chão (`height = 0.04`) em formato de placa quadrada chanfrada/arredondada com moldura externa clara.
2. **Feedback Visual de "Pode Pagar" vs "Sem Ouro"**:
   - Conecte ou monitore o ouro atual em `GameState`.
   - Quando `GameState.session_gold >= cost`: mude a cor do interior do pad para **Verde Brilhante (`#2ECC71`)**.
   - Quando `GameState.session_gold < cost`: mude a cor do interior do pad para **Cinza/Terra Escuro (`#7F8C8D`)**.
3. **Legibilidade de Preço e Ícone**:
   - O `cost_label` deve ficar posicionado na base do pad, inclinado para a câmera isométrica (`rotation_degrees.x = -65`), com texto grande, cor dourada/branca e contorno escuro grosso (`outline_size = 12`, `modulate = Color("#FFC93C")`), acompanhado de um pequeno cilindro/ícone dourado de moeda ao lado do número.
   - Não deixe textos altos flutuando que cubram o Rei Teodoro quando ele passa por cima do pad.

---

## TAREFA 5: HUD de Partida (`GameHUD.gd` e `GameHUD.tscn`) e Iluminação

### O que alterar:
1. **`GameHUD.gd` / `GameHUD.tscn`**:
   - Organize o topo da tela em **pílulas arredondadas** (`StyleBoxFlat` com `corner_radius = 20`, fundo `#2B1B12` com transparência `0.80` e borda dourada `#FFC93C` de `3px`):
     - Pílula 1 (Direita Superior, estilo Kingshot): Ícone de Moeda Dourada + Contador de Ouro grande com contorno.
     - Pílula 2 (Esquerda Superior): Contador de Capacetes carregados (`x/Max`).
     - Centro Superior: Barra de Progresso da Onda atual limpa e legível.
   - Remova qualquer poluição visual do centro da tela para que o Rei e o combate fiquem 100% visíveis.

2. **Iluminação Quente (`StageMain.tscn` e `Village.tscn`)**:
   - Ajuste a `DirectionalLight3D` para luz solar da manhã quente (`light_color = Color("#FFE3B0")`, `light_energy = 1.25`, inclinação ~50°).
   - No `WorldEnvironment`, use luz ambiente azulada suave (`ambient_light_color = Color("#8AB4F8")`, `ambient_light_sky_contribution = 0.3`) para dar contraste quente/frio estilo Supercell, com `tonemap_mode = Filmic`.

---

## TAREFA 6: Validação e Testes Automatizados

Após implementar cada tarefa acima:
1. Execute o runner de testes:
   ```bash
   python3 tests/test_runner.py
   ```
2. Verifique se não há erros de compilação GDScript ou referências nulas em modo *headless*.
3. Faça commits separados em português para cada fase concluída, mantendo a branch `main` limpa e pronta para compilar o APK no GitHub Actions.