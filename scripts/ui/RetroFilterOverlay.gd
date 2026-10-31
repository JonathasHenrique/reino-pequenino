extends CanvasLayer

# RetroFilterOverlay.gd - Filtro de pós-processamento do Modo Retrô
# Escuta o sinal de Settings e ativa o shader CRT/Pixel vintage sem queda de performance

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	layer = 100
	visible = Settings.retro_mode
	Settings.retro_mode_toggled.connect(_on_retro_toggled)

func _on_retro_toggled(enabled: bool) -> void:
	visible = enabled

