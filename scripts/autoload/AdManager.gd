extends Node

# AdManager.gd - Gerenciador de Anúncios Recompensados Não-Intrusivos (Google Play / AdMob)
# 100% voluntário (zero anúncios forçados), classificação familiar ("G") e modo de teste integrado.

signal ad_reward_earned(reward_type: String, amount: int)
signal ad_closed(reward_type: String, rewarded: bool)

const TEST_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"
const MAX_AD_CONTENT_RATING: String = "G"
const VILLAGE_CHEST_COOLDOWN_SEC: float = 180.0

var _admob_singleton: Object = null
var _active_overlay: CanvasLayer = null
var _pending_reward_type: String = ""
var _pending_amount: int = 0
var _was_tree_paused: bool = false
var _village_chest_cooldown_remaining: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_native_admob()

func _process(delta: float) -> void:
	if _village_chest_cooldown_remaining > 0.0:
		_village_chest_cooldown_remaining = maxf(0.0, _village_chest_cooldown_remaining - delta)

func _init_native_admob() -> void:
	for singleton_name in ["PoingGodotAdMob", "AdMob", "GodotAdMob"]:
		if Engine.has_singleton(singleton_name):
			_admob_singleton = Engine.get_singleton(singleton_name)
			break
	if _admob_singleton:
		# Configura classificação livre/familiar ("G") para conformidade com Google Play
		if _admob_singleton.has_method("initialize"):
			_admob_singleton.call("initialize")
		if _admob_singleton.has_method("set_request_configuration"):
			_admob_singleton.call("set_request_configuration", {
				"max_ad_content_rating": MAX_AD_CONTENT_RATING,
				"tag_for_child_directed_treatment": 1,
				"tag_for_under_age_of_consent": 1
			})

func is_village_chest_ready() -> bool:
	return _village_chest_cooldown_remaining <= 0.0

func get_village_chest_cooldown_remaining() -> float:
	return _village_chest_cooldown_remaining

func start_village_chest_cooldown(seconds: float = VILLAGE_CHEST_COOLDOWN_SEC) -> void:
	_village_chest_cooldown_remaining = maxf(0.0, seconds)

func show_rewarded_ad(reward_type: String, amount: int = 0) -> void:
	if _active_overlay and is_instance_valid(_active_overlay):
		return
	_pending_reward_type = reward_type
	_pending_amount = amount

	# Se o plugin nativo Android estiver acoplado e com anúncio pronto, utiliza-o:
	if _admob_singleton and _admob_singleton.has_method("show_rewarded_ad"):
		_admob_singleton.call("show_rewarded_ad", TEST_REWARDED_ID)
		return

	# Fallback / Modo de Teste Oficial (Editor e APK de teste sem binário nativo acoplado)
	_show_test_ad_overlay(reward_type, amount)

func _show_test_ad_overlay(reward_type: String, amount: int) -> void:
	_was_tree_paused = get_tree().paused
	get_tree().paused = true

	var overlay := CanvasLayer.new()
	overlay.name = "AdMobTestOverlay"
	overlay.layer = 120
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_active_overlay = overlay

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.04, 0.06, 0.10, 0.92)
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 320)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.15, 0.22, 0.98)
	style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var badge_lbl := Label.new()
	badge_lbl.text = "🎬 Google Play AdMob • Test Rewarded Ad (Rating: G)"
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 15)
	badge_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
	I18n.protect(badge_lbl)
	vbox.add_child(badge_lbl)

	var id_lbl := Label.new()
	id_lbl.text = "Unit ID: " + TEST_REWARDED_ID
	id_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_lbl.add_theme_font_size_override("font_size", 13)
	id_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	I18n.protect(id_lbl)
	vbox.add_child(id_lbl)

	var countdown_lbl := Label.new()
	countdown_lbl.name = "CountdownLabel"
	countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_lbl.add_theme_font_size_override("font_size", 24)
	countdown_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	I18n.protect(countdown_lbl)
	vbox.add_child(countdown_lbl)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(420, 20)
	progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress.min_value = 0.0
	progress.max_value = 3.0
	progress.value = 0.0
	progress.show_percentage = false
	vbox.add_child(progress)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)

	var cancel_btn := Button.new()
	cancel_btn.custom_minimum_size = Vector2(150, 46)
	cancel_btn.text = _tr_ad("Cancelar", "Cancel", "Cancelar")
	I18n.protect(cancel_btn)
	btn_hbox.add_child(cancel_btn)

	var claim_btn := Button.new()
	claim_btn.name = "ClaimButton"
	claim_btn.custom_minimum_size = Vector2(250, 46)
	claim_btn.disabled = true
	var claim_style := StyleBoxFlat.new()
	claim_style.bg_color = Color(0.20, 0.68, 0.32, 1.0)
	claim_style.border_color = Color(0.95, 0.85, 0.30, 1.0)
	claim_style.set_border_width_all(2)
	claim_style.set_corner_radius_all(12)
	claim_btn.add_theme_stylebox_override("normal", claim_style)
	claim_btn.text = _tr_ad("Aguarde 3s...", "Wait 3s...", "Espera 3s...")
	I18n.protect(claim_btn)
	btn_hbox.add_child(claim_btn)

	get_tree().root.add_child(overlay)

	cancel_btn.pressed.connect(func():
		AudioManager.play_sfx("button_click")
		_close_test_overlay(false, reward_type, amount)
	)
	claim_btn.pressed.connect(func():
		AudioManager.play_sfx("coin_pickup")
		_close_test_overlay(true, reward_type, amount)
	)

	_run_countdown(overlay, countdown_lbl, progress, claim_btn, reward_type, amount)

func _run_countdown(overlay: CanvasLayer, countdown_lbl: Label, progress: ProgressBar, claim_btn: Button, _reward_type: String, _amount: int) -> void:
	var duration: float = 3.0
	var elapsed: float = 0.0
	while elapsed < duration:
		if not is_instance_valid(overlay):
			return
		var remaining: int = maxi(1, ceili(duration - elapsed))
		countdown_lbl.text = _tr_ad(
			"Anúncio de Teste Google Play: %ds..." % remaining,
			"Google Play Test Ad: %ds..." % remaining,
			"Anuncio de Prueba Google Play: %ds..." % remaining
		)
		progress.value = elapsed
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if not is_instance_valid(overlay):
		return
	progress.value = duration
	countdown_lbl.text = _tr_ad(
		"✅ Anúncio de Teste Concluído!",
		"✅ Test Ad Completed!",
		"✅ ¡Anuncio de Prueba Completado!"
	)
	claim_btn.disabled = false
	claim_btn.text = _tr_ad(
		"🎁 Fechar e Resgatar",
		"🎁 Close & Claim Reward",
		"🎁 Cerrar y Reclamar"
	)

func _close_test_overlay(rewarded: bool, reward_type: String, amount: int) -> void:
	if _active_overlay and is_instance_valid(_active_overlay):
		_active_overlay.queue_free()
	_active_overlay = null
	get_tree().paused = _was_tree_paused
	if rewarded:
		if reward_type == "village_chest":
			start_village_chest_cooldown(VILLAGE_CHEST_COOLDOWN_SEC)
		ad_reward_earned.emit(reward_type, amount)
	ad_closed.emit(reward_type, rewarded)

func _tr_ad(pt_text: String, en_text: String, es_text: String) -> String:
	var lang: String = I18n.language if I18n else "pt_BR"
	if lang == "en":
		return en_text
	if lang == "es":
		return es_text
	return pt_text
