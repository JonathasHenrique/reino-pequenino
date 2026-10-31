# Diário de Progresso — Reino Pequenino 🏰

Registro contínuo do desenvolvimento, testes automatizados, decisões técnicas e pendências.

---

## [Etapa 0] Fundação, Arquitetura e Configuração Inicial
**Data:** 31 de Outubro de 2026

### O que foi feito:
1. Criada a estrutura completa de pastas do projeto:
   - `scenes/` (`stages`, `minigames`, `ui`, `village`, `entities`)
   - `scripts/` (`autoloads`, `core`, `entities`, `ui`, `minigames`)
   - `data/` (`heroes`, `troops`, `enemies`, `buildings`, `waves`, `translations`)
   - `assets/` (`audio`, `textures`, `models`, `shaders`, `fonts`)
   - `tests/` e `reference/`
2. Configurado o arquivo mestre do Godot `project.godot`:
   - Orientação `sensor_landscape` (paisagem para celulares).
   - Resolução base de 1280x720 com stretch mode `canvas_items` e aspect `expand`.
   - Emulação de toque por mouse ativada para jogabilidade perfeita no desktop e no mobile.
   - Ícone vetorial SVG criado e registrado.
3. Implementados todos os 6 Autoloads essenciais:
   - `Settings.gd`: Dificuldades (Tranquilo, Clássico, Veterano), áudio, vibração, modo retrô.
   - `SaveManager.gd`: Salvamento local JSON com versionamento, backup automático (`.bak`) e migrações.
   - `GameState.gd`: Gerenciamento do ciclo da fase, moedas em partida, vida do rei, tropas e sinais.
   - `AudioManager.gd`: Sintetizador de áudio procedural WAV 16-bit com sons originais e suporte chiptune.
   - `MiniGameRunner.gd`: Módulo independente de lançamento e validação dos 6 desafios.
   - `StoreService.gd`: Mock de compras e restauração offline, sem travas.
4. Criados os bancos de dados iniciais em JSON (`heroes.json`, `troops.json`, `enemies.json`, `buildings.json`, `strings_pt_br.json`, `strings_en.json`).
5. Documentação mestra: `README.md`, `CREDITS.md`, `PRIVACY_POLICY.md` e `tests/test_runner.py`.

### O que foi testado:
- Validação estrutural de todos os arquivos JSON através do test runner Python.
- Verificação de consistência e integridade das chaves de dados dos Heróis, Tropas e Inimigos.
- Checagem da sintaxe de GDScript dos Autoloads.

### Decisões tomadas:
- O áudio inicial utiliza síntese procedural direta em GDScript (`AudioStreamWAV`), garantindo zero dependências de arquivos de áudio externos, menor tamanho do APK e 100% de originalidade autoral.
- A câmera isométrica opera em ângulo fixo de ~50° com leve suavização de interpolação (*lerp*) seguindo o Rei Teodoro.
- O salvamento grava automaticamente uma cópia de segurança (`.bak`) para prevenir corrupção em caso de desligamento abrupto do celular.

### O que falta:
- Executar a Etapa 1: Núcleo jogável (Rei Teodoro com joystick virtual dinâmico, câmera isométrica, moedas magnéticas com empilhamento visual, plataforma de compra e arqueiros seguidores).

### Limitações encontradas:
- O teste de renderização e performance a 60 fps em hardware Android físico deverá ser concluído pelo desenvolvedor humano seguindo o guia no `README.md`.
