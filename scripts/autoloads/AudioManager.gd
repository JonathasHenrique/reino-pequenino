extends Node

# AudioManager.gd - Gerenciador e Sintetizador Procedural de Áudio
# Gera efeitos sonoros e temas com zero dependência externa e 100% livre de direitos autorais

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_voices: int = 12

var synthesized_sfx: Dictionary = {}
var current_track: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_pregenerate_sounds()
	Settings.settings_changed.connect(_on_settings_updated)

func _setup_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	for i in range(max_sfx_voices):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	
	_on_settings_updated()

func _on_settings_updated() -> void:
	if music_player:
		music_player.volume_db = linear_to_db(Settings.music_volume)
	for p in sfx_players:
		p.volume_db = linear_to_db(Settings.sfx_volume)

# --- Gerador Procedural de Áudio WAV PCM 16-bit ---

func _pregenerate_sounds() -> void:
	synthesized_sfx["button_click"] = _generate_tone(0.06, 540.0, 720.0, 0.4, "sine")
	synthesized_sfx["coin_pickup"] = _generate_arpeggio([987.77, 1318.51], 0.12, 0.35, "sine")
	synthesized_sfx["recruit"] = _generate_arpeggio([440.0, 554.37, 659.25], 0.22, 0.4, "triangle")
	synthesized_sfx["build"] = _generate_noise_hit(0.18, 220.0, 0.45)
	synthesized_sfx["puff"] = _generate_noise_hit(0.25, 120.0, 0.35)
	synthesized_sfx["shoot"] = _generate_tone(0.1, 800.0, 300.0, 0.3, "square")
	synthesized_sfx["hit"] = _generate_tone(0.08, 220.0, 90.0, 0.5, "triangle")
	synthesized_sfx["king_hit"] = _generate_tone(0.15, 180.0, 70.0, 0.6, "saw")
	synthesized_sfx["stage_victory"] = _generate_arpeggio([523.25, 659.25, 783.99, 1046.50], 0.5, 0.5, "triangle")
	synthesized_sfx["stage_defeat"] = _generate_arpeggio([440.0, 415.30, 392.00, 349.23], 0.6, 0.5, "saw")
	synthesized_sfx["hero_skill"] = _generate_arpeggio([392.0, 523.25, 659.25, 783.99, 1046.50], 0.4, 0.5, "sine")

func _generate_tone(duration: float, start_freq: float, end_freq: float, volume: float, wave_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerpf(start_freq, end_freq, t)
		var envelope = (1.0 - t) * volume
		
		phase += (freq * TAU) / sample_rate
		var s: float = 0.0
		match wave_type:
			"sine":
				s = sin(phase)
			"square":
				s = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				s = (asin(sin(phase)) / (PI * 0.5))
			"saw":
				s = (fposmod(phase, TAU) / PI) - 1.0
		
		var sample_val = int(clampf(s * envelope, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

func _generate_arpeggio(frequencies: Array, duration: float, volume: float, wave_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var step_duration = duration / float(frequencies.size())
	var num_samples = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var current_idx = 0
	var phase: float = 0.0
	
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var note_idx = mini(int(t * frequencies.size()), frequencies.size() - 1)
		var freq = float(frequencies[note_idx])
		var note_t = fmod(float(i) / float(sample_rate), step_duration) / step_duration
		var envelope = (1.0 - (note_t * 0.7)) * volume
		
		phase += (freq * TAU) / sample_rate
		var s = sin(phase) if wave_type == "sine" else (1.0 if sin(phase) >= 0.0 else -1.0)
		var sample_val = int(clampf(s * envelope, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

func _generate_noise_hit(duration: float, center_freq: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var envelope = (1.0 - t) * (1.0 - t) * volume
		phase += (center_freq * TAU) / sample_rate
		var noise = randf_range(-0.6, 0.6)
		var tone = sin(phase) * 0.4
		var s = (noise + tone) * envelope
		var sample_val = int(clampf(s, -1.0, 1.0) * 32767.0)
		byte_data.encode_s16(i * 2, sample_val)
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

# --- Execução de Áudio ---

func play_sfx(sfx_name: String) -> void:
	if not synthesized_sfx.has(sfx_name):
		return
	
	for p in sfx_players:
		if not p.playing:
			p.stream = synthesized_sfx[sfx_name]
			p.play()
			return
	
	# Se todos estiverem ocupados, reutiliza o primeiro
	sfx_players[0].stream = synthesized_sfx[sfx_name]
	sfx_players[0].play()

func play_music(track_name: String) -> void:
	if current_track == track_name and music_player.playing:
		return
	current_track = track_name
	
	# Gera loop musical curto e agradável para a atmosfera
	var freqs = [261.63, 329.63, 392.00, 523.25, 440.0, 392.0]
	if track_name == "battle":
		freqs = [220.0, 261.63, 329.63, 440.0, 329.63, 293.66]
	elif track_name == "village":
		freqs = [261.63, 329.63, 392.00, 329.63, 349.23, 261.63]
		
	var wave = "square" if Settings.retro_mode else "triangle"
	var music_wav = _generate_arpeggio(freqs, 2.4, 0.25, wave)
	music_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_wav.loop_begin = 0
	music_wav.loop_end = music_wav.data.size() / 2
	
	music_player.stream = music_wav
	music_player.play()

func stop_music() -> void:
	music_player.stop()
	current_track = ""
