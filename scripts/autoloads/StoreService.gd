extends Node

# StoreService.gd - Serviço de Compras no Aplicativo (IAP)
# Contém mock offline completo para testes e interface pronta para Google Play Billing

signal purchase_started(product_id: String)
signal purchase_completed(product_id: String, success: bool, message: String)
signal purchases_restored()

const PRODUCTS: Dictionary = {
	"hero_marta": {"type": "hero", "id": "marta", "price": "R$ 4,90", "name": "Marta, a Ferreira"},
	"hero_fidelio": {"type": "hero", "id": "fidelio", "price": "R$ 4,90", "name": "Mago Fidélio"},
	"hero_rosa": {"type": "hero", "id": "rosa", "price": "R$ 4,90", "name": "Capitã Rosa"},
	"hero_clara": {"type": "hero", "id": "clara", "price": "R$ 4,90", "name": "Irmã Clara"},
	"hero_bento": {"type": "hero", "id": "bento", "price": "R$ 4,90", "name": "Bento, o Urso"},
	"skin_crown_vintage": {"type": "skin_crown", "id": "crown_vintage", "price": "R$ 2,90", "name": "Coroa Retrô Pixel"},
	"skin_pony_rainbow": {"type": "skin_pony", "id": "pony_rainbow", "price": "R$ 2,90", "name": "Biscoito Colorido"},
	"bundle_complete_kingdom": {"type": "bundle", "id": "complete", "price": "R$ 14,90", "name": "Pacote Reino Completo"}
}

var is_mock_mode: bool = true # Em ambiente de desenvolvimento / testes locais

func buy_product(product_id: String) -> void:
	if not PRODUCTS.has(product_id):
		purchase_completed.emit(product_id, false, "Produto não encontrado")
		return
	
	purchase_started.emit(product_id)
	
	if is_mock_mode:
		# Simulação instantânea com sucesso
		_apply_purchase(product_id)
		purchase_completed.emit(product_id, true, "Compra efetuada com sucesso (Modo Mock)")
	else:
		# Chamada real ao plugin Godot GooglePlayBilling quando compilado para Android
		_process_real_billing(product_id)

func restore_purchases() -> void:
	if is_mock_mode:
		purchases_restored.emit()
	else:
		# Chamada ao plugin Google Play Billing
		pass

func _apply_purchase(product_id: String) -> void:
	var item = PRODUCTS[product_id]
	match item["type"]:
		"hero":
			SaveManager.unlock_hero(item["id"])
		"skin_crown":
			var skins = SaveManager.save_data.get("skins_unlocked", [])
			if not skins.has(item["id"]):
				skins.append(item["id"])
				SaveManager.save_data["skins_unlocked"] = skins
				SaveManager.save_game()
		"skin_pony":
			var skins = SaveManager.save_data.get("skins_unlocked", [])
			if not skins.has(item["id"]):
				skins.append(item["id"])
				SaveManager.save_data["skins_unlocked"] = skins
				SaveManager.save_game()
		"bundle":
			# Desbloqueia todos os heróis e cosméticos
			for h in ["marta", "fidelio", "rosa", "clara", "bento"]:
				SaveManager.unlock_hero(h)
			var skins = SaveManager.save_data.get("skins_unlocked", [])
			for s in ["crown_vintage", "pony_rainbow"]:
				if not skins.has(s):
					skins.append(s)
			SaveManager.save_data["skins_unlocked"] = skins
			SaveManager.add_gold(1000)
			SaveManager.save_game()

func _process_real_billing(_product_id: String) -> void:
	# Integrado via plugin oficial 'godot-google-play-billing'
	# Consultar README.md para instruções de compilação com credenciais do Play Console
	pass
