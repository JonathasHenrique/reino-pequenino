extends CanvasLayer

# StoreMenu.gd - Tenda do Mercador (Loja de Heróis e Cosméticos)
# Compras justas e diretas: sem gacha, sem espera paga e com mock offline para testes

@onready var products_container: VBoxContainer = $Panel/VBox/Scroll/ProductsContainer
@onready var restore_button: Button = $Panel/VBox/HBox/RestoreButton
@onready var close_button: Button = $Panel/VBox/HBox/CloseButton
@onready var status_label: Label = $Panel/VBox/StatusLabel

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(func():
			AudioManager.play_sfx("button_click")
			queue_free()
		)
	if restore_button:
		restore_button.pressed.connect(_on_restore_pressed)
		
	StoreService.purchase_completed.connect(_on_purchase_completed)
	_populate_store()

func _populate_store() -> void:
	for child in products_container.get_children():
		child.queue_free()
		
	for p_id in StoreService.PRODUCTS.keys():
		var item = StoreService.PRODUCTS[p_id]
		var panel = PanelContainer.new()
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		panel.add_child(hbox)
		
		var icon_lbl = Label.new()
		icon_lbl.text = "👑" if "crown" in p_id else ("🦄" if "pony" in p_id else "🛡️")
		icon_lbl.theme_override_font_sizes/font_size = 32
		hbox.add_child(icon_lbl)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = item.get("name", "")
		name_lbl.theme_override_font_sizes/font_size = 18
		vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = "Compra única permanente. Sem surpresas."
		desc_lbl.theme_override_font_sizes/font_size = 13
		desc_lbl.modulate = Color(0.7, 0.7, 0.7)
		vbox.add_child(desc_lbl)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(120, 46)
		buy_btn.text = item.get("price", "R$ 4,90")
		buy_btn.pressed.connect(_on_buy_pressed.bind(p_id))
		hbox.add_child(buy_btn)
		
		products_container.add_child(panel)

func _on_buy_pressed(p_id: String) -> void:
	AudioManager.play_sfx("button_click")
	StoreService.buy_product(p_id)

func _on_purchase_completed(_p_id: String, success: bool, message: String) -> void:
	if status_label:
		status_label.text = message
		status_label.modulate = Color(0.4, 0.9, 0.4) if success else Color(0.9, 0.4, 0.4)
	if success:
		AudioManager.play_sfx("stage_victory")

func _on_restore_pressed() -> void:
	AudioManager.play_sfx("button_click")
	StoreService.restore_purchases()
	if status_label:
		status_label.text = "Compras restauradas com sucesso!"
		status_label.modulate = Color(0.4, 0.9, 0.4)
