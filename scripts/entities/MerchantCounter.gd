extends Area3D

# MerchantCounter.gd - Balcão do Mercador Tobias
# Compra os capacetes e sucatas coletados dos inimigos e paga em pilhas de moedas de ouro

@export var coin_payout_per_spoil: int = 4
var is_trading: bool = false

@onready var label_sign: Label3D = $Label3D
@onready var speech_label: Label3D = $SpeechBubble

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_sign()

func _update_sign() -> void:
	if label_sign:
		label_sign.text = "🏪 MERCADOR TOBIAS\n(Venda Capacetes: 🪖 = 🪙 %d)" % coin_payout_per_spoil

func _on_body_entered(body: Node3D) -> void:
	if body == GameState.king_node or body.is_in_group("king"):
		_trade_spoils()

func _trade_spoils() -> void:
	var spoils = GameState.stage_spoils
	if spoils <= 0:
		_show_speech("Traga capacetes dos inimigos para trocar por moedas!")
		return
		
	if GameState.spend_stage_spoils(spoils):
		var total_coins = spoils * coin_payout_per_spoil
		GameState.add_stage_coins(total_coins)
		AudioManager.play_sfx("coin_pickup")
		
		# Feedback visual e sonoro vibrante
		_show_speech("Negócio fechado, Majestade! +%d Moedas!" % total_coins)
		
		# Efeito de moedas voando para o Rei
		var coin_scene = load("res://scenes/entities/Coin.tscn")
		if coin_scene:
			for i in range(min(spoils * 2, 8)):
				var c = coin_scene.instantiate()
				get_parent().add_child(c)
				c.global_position = global_position + Vector3(randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6))
				if c.has_method("attract_to") and GameState.king_node:
					c.attract_to(GameState.king_node)

func _show_speech(text: String) -> void:
	if speech_label:
		speech_label.text = text
		speech_label.visible = true
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if is_instance_valid(speech_label):
				speech_label.visible = false
		)
