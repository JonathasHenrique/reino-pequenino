extends Control

# MainMenu.gd - Menu Principal do Reino Pequenino
# Ponto de entrada com estética acolhedora de brinquedo e música alegre

@onready var play_button: Button = $VBox/PlayButton
@onready var village_button: Button = $VBox/VillageButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var title_label: Label = $Header/Title
@onready var subtitle_label: Label = $Header/Subtitle
@onready var background: TextureRect = $Background

func _ready() -> void:
	AudioManager.play_music("village")
	_style_menu()
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		_style_chunky_button(play_button, Color("#FFC93C"), Color("#D99B26"), Color("#2B1B12"))
	if village_button:
		village_button.pressed.connect(_on_village_pressed)
		_style_chunky_button(village_button, Color("#3F7FE0"), Color("#2B5BA8"))
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		_style_chunky_button(settings_button, Color("#8E959E"), Color("#686F77"))
	call_deferred("_add_menu_life")

func _add_menu_life() -> void:
	if title_label and title_label.size.x > 1.0:
		title_label.pivot_offset = title_label.size * 0.5
		var pulse := create_tween().set_loops()
		pulse.tween_property(title_label, "scale", Vector2(1.05, 1.05), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(title_label, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var crown := get_node_or_null("Header/CrownIcon") as Control
	if crown:
		var base_y: float = crown.position.y
		var bob := create_tween().set_loops()
		bob.tween_property(crown, "position:y", base_y - 10.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(crown, "position:y", base_y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for btn in [play_button, village_button, settings_button]:
		if btn:
			_add_button_bounce(btn)

func _add_button_bounce(btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5
	btn.button_down.connect(func():
		create_tween().tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	)
	btn.button_up.connect(func():
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	)

func _style_menu() -> void:
	if background and background.texture is GradientTexture2D:
		var gradient_texture := background.texture as GradientTexture2D
		gradient_texture.gradient.colors = PackedColorArray([
			Color("#1B3B6F"), Color("#3F7FE0")
		])
	if title_label:
		title_label.add_theme_color_override("font_color", Color("#FFC93C"))
		title_label.add_theme_color_override("font_outline_color", Color("#2B1B12"))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		title_label.add_theme_constant_override("outline_size", 16)
		title_label.add_theme_constant_override("shadow_offset_y", 6)
		title_label.add_theme_font_size_override("font_size", 54)
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color("#FFF3D6"))
		subtitle_label.add_theme_color_override("font_outline_color", Color("#2B1B12"))
		subtitle_label.add_theme_constant_override("outline_size", 8)
		subtitle_label.add_theme_font_size_override("font_size", 20)

func _style_chunky_button(btn: Button, top_col: Color, bottom_lip_col: Color, text_col: Color = Color.WHITE) -> void:
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_stylebox_override("normal", _button_style(top_col, bottom_lip_col, 7))
	btn.add_theme_stylebox_override("hover", _button_style(top_col.lightened(0.08), bottom_lip_col.lightened(0.08), 7))
	btn.add_theme_stylebox_override("pressed", _button_style(top_col.darkened(0.08), bottom_lip_col.darkened(0.08), 3))
	btn.add_theme_stylebox_override("disabled", _button_style(Color("#686F77"), Color("#4D5359"), 3))
	btn.button_down.connect(func() -> void: _bounce_button(btn, 0.95))
	btn.button_up.connect(func() -> void: _bounce_button(btn, 1.03))

func _button_style(fill: Color, lip: Color, bottom_border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = lip
	style.set_border_width_all(3)
	style.border_width_bottom = bottom_border
	style.set_corner_radius_all(14)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _bounce_button(btn: Button, target_scale: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE * target_scale, 0.08)
	if target_scale > 1.0:
		tween.tween_property(btn, "scale", Vector2.ONE, 0.10)

func _on_play_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var unlocked = int(SaveManager.save_data.get("unlocked_stages", 1))
	if unlocked == 1 and not SaveManager.save_data.get("stage_stars", {}).has("1"):
		# Primeira vez: exibe a cena de abertura e tutorial
		get_tree().change_scene_to_file("res://scenes/ui/IntroCutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

func _on_village_pressed() -> void:
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/village/Village.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var settings_scene = load("res://scenes/ui/SettingsMenu.tscn")
	if settings_scene:
		var menu = settings_scene.instantiate()
		add_child(menu)
