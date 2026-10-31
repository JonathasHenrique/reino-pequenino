# Reino Pequenino 👑

Jogo Android completo de defesa de base, formação de tropas e minigames em estilo diorama de brinquedo 3D, desenvolvido em **Godot 4**.

---

## 🎮 Visão Geral
* **Público:** Crianças (6+) e Jovens Adultos (18-26 anos) nostálgicos.
* **Classificação Indicativa:** Livre a 10 anos (sem sangue, sem violência gráfica; inimigos viram nuvem "puf" e moedas).
* **Orientação:** Paisagem (Landscape), jogável confortavelmente com uma só mão através de joystick virtual dinâmico.
* **Sessões:** 2 a 5 minutos por fase.
* **Conteúdo:** 60 fases distribuídas em 6 mundos temáticos com 6 minigames autorais que recuperam as Estrelas da Coroa e desbloqueiam novos Heróis.
* **Humor em duas camadas:** Situações fofas e visuais infantis com diálogos irônicos e carinhosos de Dona Zenaide para o público maduro.

---

## 🏗️ Estrutura do Projeto
```
reino-pequenino/
├── project.godot               # Configurações do motor Godot 4.3
├── icon.svg                    # Ícone vetorial oficial
├── PROGRESSO.md                # Registro de etapas, testes e decisões
├── README.md                   # Documentação técnica e guia de compilação
├── CREDITS.md                  # Licenças de assets e atribuições (100% CC0/OFL)
├── PRIVACY_POLICY.md           # Política de privacidade com zero rastreamento
├── scenes/
│   ├── stages/                 # Cenas de gameplay isométrico e HUD
│   ├── minigames/              # Os 6 Desafios autorais desacoplados
│   ├── ui/                     # Menus, configurações, troféus e álbum
│   ├── village/                # Vila isométrica do Rei e construções
│   └── entities/               # Rei, tropas, inimigos, moedas e projéteis
├── scripts/
│   ├── autoloads/              # GameState, SaveManager, AudioManager, etc.
│   ├── core/                   # Câmera isométrica, pooling e spawner
│   ├── entities/               # Lógica do Rei, tropas, IA dos brumosos
│   ├── ui/                     # Controladores de HUD e menus
│   └── minigames/              # Lógica isolada de cada desafio
├── data/                       # Arquivos JSON orientados a dados
│   ├── heroes/                 # Estatísticas e habilidades dos heróis
│   ├── troops/                 # Atributos de arqueiros, lanceiros, etc.
│   ├── enemies/                # Brumosos, corvos, gigantes e totens
│   ├── buildings/              # Torres, paliçadas e melhorias da vila
│   ├── waves/                  # Configuração de hordas das 60 fases
│   └── translations/           # Dicionários de texto (pt-BR e en)
├── assets/                     # Modelos 3D, shaders, texturas e áudios
├── reference/                  # Prints de estudo de proporção/câmera
└── tests/                      # Suíte de testes automatizados
```

---

## 🧪 Como Rodar os Testes
Para validar a integridade dos dados, economia, regras de minigames e salvamento:
```bash
python3 tests/test_runner.py
```
Para executar o jogo no Godot Editor ou via linha de comando:
```bash
godot --path .
```

---

## 📦 Como Gerar o APK / AAB para Android (Google Play)
1. Abra o projeto no **Godot 4.3**.
2. Instale o modelo de build do Android em **Projeto -> Instalar Modelo de Compilação do Android**.
3. Em **Projeto -> Exportar**, selecione o preset **Android**.
4. Configure sua chave de assinatura (Keystore de Release ou Debug):
   ```bash
   keytool -genkey -v -keystore reino-pequenino.keystore -alias reinokey -keyalg RSA -keysize 2048 -validity 10000
   ```
5. Marque a opção **Export Format: Export AAB (Google Play)** ou **Export APK** para testes em aparelho via ADB.
6. Clique em **Exportar Projeto**.

---

## 💳 Integração com Google Play Billing
O jogo inclui um mock offline seguro em `scripts/autoloads/StoreService.gd`. Para ativar compras reais na Google Play:
1. Ative o plugin oficial `GodotGooglePlayBilling` na pasta `android/plugins/`.
2. No console de desenvolvedor do Google Play, cadastre os IDs de produto correspondentes (`hero_marta`, `bundle_complete_kingdom`, etc.).
3. Altere a variável `is_mock_mode = false` em `StoreService.gd`.
