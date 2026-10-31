extends CanvasLayer

# DebugMenu.gd - Menu de Ferramentas de Desenvolvimento e Testes
# Permite testar economia, saltos de fase e heróis instantaneamente

@onready var add_coins_btn: Button = $Panel/VBox/Grid/AddCoinsBtn
@onready var add_gold_btn: Button = $Panel/VBox/Grid/AddGoldBtn
@onready var unlock_heroes_btn: Button = $Panel/VBox/Grid/UnlockHeroesBtn
@onready var skip_stage_btn: Button = $Panel/VBox/Grid/SkipStageBtn
@onready var close_btn: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	if add_coins_btn:
		add_coins_btn.pressed.connect(_on_add_coins)
	if add_gold_btn:
		add_gold_btn.pressed.connect(_on_add_gold)
	if unlock_heroes_btn:
		unlock_heroes_btn.pressed.connect(_on_unlock_heroes)
	if skip_stage_btn:
		skip_stage_btn.pressed.connect(_on_skip_stage)
	if close_btn:
		close_btn.pressed.connect(func(): queue_free())

func _on_add_coins() -> void:
	GameState.add_stage_coins(100)
	AudioManager.play_sfx("coin_pickup")

func _on_add_gold() -> void:
	SaveManager.add_gold(500)
	AudioManager.play_sfx("coin_pickup")

func _on_unlock_heroes() -> void:
	for h in ["marta", "fidelio", "rosa", "clara", "bento", "barao"]:
		SaveManager.unlock_hero(h)
	AudioManager.play_sfx("stage_victory")

func _on_skip_stage() -> void:
	GameState.complete_stage(true)
	queue_free()

