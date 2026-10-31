# Reino Pequenino 👑

Jogo Android completo de defesa de base isométrica, formação de tropas e minigames em estilo diorama de brinquedo 3D, construído do zero em **Godot 4**.

---

## 🎮 Visão do Jogo
* **Público:** Crianças (6+) e Jovens Adultos (18-26 anos) que sentem nostalgia de fliperamas, álbuns de figurinhas, lan houses e chiptune.
* **Classificação Indicativa:** Livre a 10 anos. Sem sangue, sem violência gráfica e sem linguagem pesada. Inimigos derrotados soltam uma nuvem cinza ("puf") e moedas.
* **Controles:** Jogável confortavelmente com **uma mão** em modo paisagem (*landscape*) através de um joystick virtual dinâmico.
* **Sessões:** Partidas rápidas de 2 a 5 minutos.
* **Escala:** 60 fases distribuídas em 6 mundos temáticos (54 fases de defesa + 6 minigames autorais com chefes que devolvem as Estrelas da Coroa Mãe e liberam novos Heróis).
* **Humor em Duas Camadas:** Diálogos carinhosos e fofos para crianças, com tiradas irônicas e refinadas da vovó Dona Zenaide para adultos.

---

## 🏰 Os 6 Mundos e Seus Desafios
1. **Vale dos Girassóis** (Fases 1 a 10) — *Desafio 10: A Catapulta do Vale* (Física 2D de lançamento em alvos de blocos) ➔ **Heroína Marta, a Ferreira**.
2. **Floresta dos Cogumelos** (Fases 11 a 20) — *Desafio 20: Cofre dos Números* (Sudoku místico sem tempo) ➔ **Herói Mago Fidélio**.
3. **Penhascos de Mel** (Fases 21 a 30) — *Desafio 30: Escudo e Bola* (Quebra-blocos radiante com poderes) ➔ **Heroína Capitã Rosa**.
4. **Lago dos Espelhos** (Fases 31 a 40) — *Desafio 40: A Muralha de Peças* (Grid puzzle 8x8 de encaixe) ➔ **Heroína Irmã Clara**.
5. **Pico do Inverno** (Fases 41 a 50) — *Desafio 50: A Corrida de Biscoito* (Plataforma lateral 2D nostálgica) ➔ **Herói Bento, o Urso**.
6. **Castelo Cinzão** (Fases 51 a 60) — *Desafio 60: Jardim da Defesa* (Defesa por 5 faixas e confronto em 3 fases com o Barão Cinzão) ➔ **Herói Barão Cinzão Redimido**.

---

## ⚙️ Arquitetura e Estrutura de Pastas
```
reino-pequenino/
├── project.godot               # Configurações do motor Godot 4 (display 1280x720, sensor_landscape)
├── export_presets.cfg          # Presets de exportação Android (arm64-v8a, armeabi-v7a, x86_64)
├── icon.svg                    # Ícone vetorial oficial (Coroa dourada e diorama)
├── PROGRESSO.md                # Registro detalhado de todas as 10 etapas executadas
├── README.md                   # Documentação técnica e instruções
├── CREDITS.md                  # Licenças de assets e atribuições (100% original / CC0 / OFL)
├── PRIVACY_POLICY.md           # Política de privacidade familiar (zero anúncios, offline)
├── scenes/
│   ├── stages/                 # Cenas de gameplay isométrico (StageMain, StageCoreTest)
│   ├── minigames/              # Os 6 Desafios autorais e tela de comemoração
│   ├── ui/                     # Menus, HUD, diálogos, modo retrô, troféus e álbum
│   ├── village/                # Vila isométrica, moinho com ouro passivo e construções
│   └── entities/               # Rei Teodoro, pônei Biscoito, tropas, inimigos e totens
├── scripts/
│   ├── autoloads/              # GameState, SaveManager, AudioManager, Settings, StoreService
│   ├── core/                   # Câmera isométrica ~50°, WaveManager orientado a dados
│   ├── entities/               # Formação concêntrica, torres, paliçadas, IA dos brumosos
│   ├── ui/                     # Controladores de telas, joystick virtual e diálogos
│   └── minigames/              # Controladores desacoplados de cada desafio
├── data/                       # Arquivos JSON editáveis para balanceamento imediato
│   ├── heroes/                 # Fichas técnicas dos 7 heróis
│   ├── troops/                 # Atributos de arqueiros, lanceiros, escudeiros, magos, etc.
│   ├── enemies/                # Brumosos, corvos cinzentos, gigantes de névoa e totens
│   ├── buildings/              # Melhorias instantâneas da vila e custos
│   ├── waves/                  # 60 fases estruturadas (world1 a world6)
│   ├── trophies/               # Conquistas do reino
│   ├── stickers/               # Figurinhas colecionáveis da coroa
│   └── translations/           # Textos em pt-BR e en
├── assets/                     # Shaders (retro_crt), materiais toon e recursos
└── tests/                      # Suíte de testes automatizados integral
```

---

## 🧪 Como Rodar os Testes
Para rodar a suíte completa de testes automatizados (validando dados, economia, 60 fases, 3 dificuldades e cenas):
```bash
python3 tests/test_runner.py
```

---

## 📱 Como Abrir e Jogar no Godot 4
1. Abra o **Godot 4.3** (ou superior).
2. Clique em **Importar**, aponte para a pasta `reino-pequenino` e selecione `project.godot`.
3. Pressione **F5** para iniciar o jogo diretamente no menu principal.

---

## 📦 Como Gerar o APK de Debug e o AAB Assinado para Google Play

### 1. Pré-requisitos
- Godot 4 instalado com os modelos de exportação Android (*Android Export Templates*).
- Android SDK e JDK 17 configurados nas configurações do Godot (**Editor -> Configurações do Editor -> Exportar -> Android**).

### 2. Gerar Chave de Assinatura (Keystore de Release)
```bash
keytool -genkey -v -keystore reino-pequenino.keystore -alias reinokey -keyalg RSA -keysize 2048 -validity 10000
```

### 3. Gerar o APK de Debug
1. No menu superior do Godot, clique em **Projeto -> Exportar...**
2. Selecione o preset **Android**.
3. Clique em **Exportar Projeto...**
4. Escolha o caminho de destino (ex: `reino_pequenino_debug.apk`) e desmarque "Exportar com Depuração" se desejar build de teste rápido.

### 4. Gerar o AAB Assinado (Google Play Store)
1. No preset **Android**, preencha os campos de Release Keystore:
   - **Caminho da Keystore:** `/caminho/para/reino-pequenino.keystore`
   - **Usuário da Keystore:** `reinokey`
   - **Senha da Keystore:** `sua_senha`
2. Marque a opção **Export Format: Export AAB (Google Play)**.
3. Clique em **Exportar Projeto...** e salve como `reino_pequenino.aab`.

---

## 💳 Integração com Google Play Billing
O jogo inclui um mock offline seguro em `scripts/autoloads/StoreService.gd`.
Para habilitar cobranças reais na conta de produção da Google Play:
1. No Play Console, configure os produtos in-app correspondentes:
   - `hero_marta`, `hero_fidelio`, `hero_rosa`, `hero_clara`, `hero_bento`
   - `skin_crown_vintage`, `skin_pony_rainbow`
   - `bundle_complete_kingdom`
2. Instale o plugin oficial `GodotGooglePlayBilling`.
3. Em `scripts/autoloads/StoreService.gd`, configure `is_mock_mode = false`.

---

## 📋 Lista do que Deve ser Feito por um Humano
1. **Teste em Aparelho Físico Real:** Instalar o APK em um celular Android para validar a resposta do toque e o conforto do polegar na jogabilidade com uma mão só.
2. **Assinatura de Produção:** Criar a keystore privada definitiva de release com senha segura.
3. **Google Play Console:** Criar a ficha do aplicativo, fazer upload do arquivo `reino_pequenino.aab` e enviar para revisão da Google Play Families Policy.
