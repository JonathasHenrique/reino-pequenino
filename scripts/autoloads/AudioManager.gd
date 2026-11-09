extends Node

# AudioManager.gd - Gerenciador e Sintetizador Procedural de Áudio
# Gera efeitos sonoros e temas com zero dependência externa e 100% livre de direitos autorais

var music_player: AudioStreamPlayer
var music_player_alt: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_voices: int = 12

var synthesized_sfx: Dictionary = {}
var current_track: String = ""
var _music_cache: Dictionary = {}
var _music_tasks: Dictionary = {}
var _music_results: Dictionary = {}
var _wanted_track: String = ""
var _crossfade_tween: Tween = null
var _active_player_is_primary: bool = true

const REAL_MUSIC_FILES := {
	"village": "res://assets/audio/music/village_theme.ogg",
	"battle": "res://assets/audio/music/battle_theme.ogg",
	"boss": "res://assets/audio/music/battle_theme.ogg",
	"menu": "res://assets/audio/music/village_theme.ogg",
	"prologue": "res://assets/audio/music/prologue_theme.ogg",
}

const REAL_SFX_FILES := {
	"war_horn": "res://assets/audio/sfx/war_horn.ogg",
	"hero_skill": "res://assets/audio/sfx/war_horn.ogg",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_pregenerate_sounds()
	Settings.settings_changed.connect(_on_settings_updated)

func _setup_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	music_player_alt = AudioStreamPlayer.new()
	music_player_alt.bus = "Master"
	add_child(music_player_alt)
	
	for i in range(max_sfx_voices):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	
	_on_settings_updated()

func _on_settings_updated() -> void:
	var base_db = linear_to_db(Settings.music_volume)
	if _crossfade_tween == null or not _crossfade_tween.is_valid():
		var cur = _get_active_music_player()
		if cur:
			cur.volume_db = base_db
	for p in sfx_players:
		p.volume_db = linear_to_db(Settings.sfx_volume)

func _get_active_music_player() -> AudioStreamPlayer:
	return music_player if _active_player_is_primary else music_player_alt

func _get_inactive_music_player() -> AudioStreamPlayer:
	return music_player_alt if _active_player_is_primary else music_player

# --- Gerador Procedural de Áudio WAV PCM 16-bit ---

func _load_audio_file(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res := load(path) as AudioStream
		if res:
			return res
	if FileAccess.file_exists(path) and path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	return null

func _pregenerate_sounds() -> void:
	synthesized_sfx["button_click"] = _generate_pluck(660.0, 0.09, 0.30)
	synthesized_sfx["coin_pickup"] = _generate_pluck_sequence([1046.50, 1318.51, 1567.98], 0.06, 0.30)
	synthesized_sfx["recruit"] = _generate_horn([392.0, 523.25, 659.25], 0.30, 0.30)
	synthesized_sfx["build"] = _generate_wood_hit(0.20, 0.55)
	synthesized_sfx["puff"] = _generate_noise_hit(0.25, 120.0, 0.30)
	synthesized_sfx["shoot"] = _generate_whoosh(0.14, 0.32)
	synthesized_sfx["hit"] = _generate_wood_hit(0.12, 0.48)
	synthesized_sfx["king_hit"] = _generate_drum(0.28, 0.65)
	synthesized_sfx["stage_victory"] = _generate_horn([392.0, 523.25, 659.25, 783.99], 0.85, 0.36)
	synthesized_sfx["stage_defeat"] = _generate_arpeggio([440.0, 415.30, 392.00, 349.23], 0.6, 0.5, "triangle")
	synthesized_sfx["hero_skill"] = _generate_harp_gliss()
	for sfx_key in REAL_SFX_FILES:
		var path: String = REAL_SFX_FILES[sfx_key]
		var res = _load_audio_file(path)
		if res:
			synthesized_sfx[sfx_key] = res

func _sound_wav(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var byte_data := PackedByteArray()
	byte_data.resize(samples.size() * 2)
	for i in range(samples.size()):
		byte_data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

func _hash_noise(seed_value: float) -> float:
	var n := sin(seed_value * 12.9898) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0

func _instrument(kind: String, freq: float, t: float, dur: float) -> float:
	match kind:
		"pluck":
			var attack := minf(t / 0.006, 1.0)
			var body := sin(TAU * freq * t) + 0.45 * sin(TAU * freq * 2.0 * t) * exp(-t * 9.0) + 0.18 * sin(TAU * freq * 3.0 * t) * exp(-t * 13.0)
			return body * attack * exp(-t * 5.2)
		"flute":
			var env := minf(t / 0.09, 1.0) * clampf((dur - t) / 0.14, 0.0, 1.0)
			var vib := 1.0 + 0.006 * sin(TAU * 5.2 * t)
			return (sin(TAU * freq * vib * t) + 0.12 * sin(TAU * freq * 2.0 * t)) * env
		"bass":
			return sin(TAU * freq * t) * minf(t / 0.02, 1.0) * exp(-t * 1.1)
		"drum":
			var f := 82.0 * exp(-t * 3.2) + 46.0
			return (sin(TAU * f * t) * 0.85 + _hash_noise(t * 900.0) * 0.22) * exp(-t * 15.0)
		"shaker":
			return _hash_noise(t * 2600.0) * exp(-t * 42.0) * 0.5
		"horn":
			var env := minf(t / 0.07, 1.0) * clampf((dur - t) / 0.18, 0.0, 1.0)
			var vib2 := 1.0 + 0.004 * sin(TAU * 4.6 * t)
			return (0.7 * sin(TAU * freq * vib2 * t) + 0.3 * sin(TAU * freq * 2.0 * t) + 0.12 * sin(TAU * freq * 3.0 * t)) * env
	return 0.0

func _render_events(events: Array, duration: float, sample_rate: int = 22050) -> AudioStreamWAV:
	var sr := sample_rate
	var total := int(duration * sr)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for ev in events:
		var start := int(float(ev["start"]) * sr)
		var count := int(float(ev["len"]) * sr)
		for i in range(count):
			var idx := start + i
			if idx >= total:
				break
			var t := float(i) / float(sr)
			buf[idx] += _instrument(str(ev["f"]), float(ev["freq"]), t, float(ev["len"])) * float(ev["vol"])
	var peak := 0.0
	for i in range(total):
		peak = maxf(peak, absf(buf[i]))
	if peak > 0.001:
		var gain := 0.88 / peak
		for i in range(total):
			buf[i] = clampf(buf[i] * gain, -1.0, 1.0)
	return _sound_wav(buf, sr)

func _generate_pluck(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(duration * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for i in range(total):
		arr[i] = _instrument("pluck", freq, float(i) / float(sr), duration) * volume
	return _sound_wav(arr)

func _generate_pluck_sequence(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(note_duration * freqs.size() * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for n in range(freqs.size()):
		var base := int(n * note_duration * sr)
		for i in range(int(note_duration * sr)):
			var idx := base + i
			if idx >= total:
				break
			arr[idx] += _instrument("pluck", float(freqs[n]), float(i) / float(sr), note_duration) * volume
	return _sound_wav(arr)

func _generate_horn(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(note_duration * freqs.size() * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for n in range(freqs.size()):
		var base := int(n * note_duration * sr)
		for i in range(int(note_duration * sr)):
			var idx := base + i
			if idx >= total:
				break
			arr[idx] += _instrument("horn", float(freqs[n]), float(i) / float(sr), note_duration) * volume
	return _sound_wav(arr)

func _generate_wood_hit(duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(duration * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for i in range(total):
		var t := float(i) / float(sr)
		var f := 165.0 * exp(-t * 18.0) + 72.0
		var thump := sin(TAU * f * t) * exp(-t * 22.0) * 0.85
		arr[i] = (thump + randf_range(-0.25, 0.25) * exp(-t * 34.0)) * volume
	return _sound_wav(arr)

func _generate_whoosh(duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(duration * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	var lp := 0.0
	for i in range(total):
		var t := float(i) / float(sr)
		lp = lp * 0.86 + randf_range(-1.0, 1.0) * 0.14
		var sweep := sin(TAU * (900.0 * exp(-t * 9.0) + 120.0) * t) * 0.25
		arr[i] = (lp + sweep) * exp(-t * 16.0) * volume
	return _sound_wav(arr)

func _generate_drum(duration: float, volume: float) -> AudioStreamWAV:
	var sr := 22050
	var total := int(duration * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for i in range(total):
		arr[i] = _instrument("drum", 0.0, float(i) / float(sr), duration) * volume
	return _sound_wav(arr)

func _generate_harp_gliss() -> AudioStreamWAV:
	var notes := [392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
	var sr := 22050
	var total := int(0.7 * sr)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for n in range(notes.size()):
		var base := int(n * 0.045 * sr)
		for i in range(int(0.5 * sr)):
			var idx := base + i
			if idx >= total:
				break
			arr[idx] += _instrument("pluck", float(notes[n]), float(i) / float(sr), 0.5) * 0.28
	return _sound_wav(arr)

func _generate_medieval_track(track_name: String) -> AudioStreamWAV:
	if track_name == "menu":
		return _generate_menu_theme()
	var events: Array = []
	var duration := 7.6
	if track_name == "battle":
		duration = 7.2
		var bar := 1.8
		var ostinato := [261.63, 392.0, 523.25, 659.25, 392.0, 659.25, 523.25, 392.0]
		for b in range(4):
			events.append({"f": "bass", "freq": 65.41, "start": b * bar, "len": bar, "vol": 0.42})
			for k in range(8):
				events.append({"f": "pluck", "freq": ostinato[k], "start": b * bar + k * bar / 8.0, "len": bar / 8.0 * 0.95, "vol": 0.44})
			for beat in range(4):
				events.append({"f": "drum", "freq": 0.0, "start": b * bar + beat * bar / 4.0, "len": 0.2, "vol": 0.46})
			for k in range(8):
				events.append({"f": "shaker", "freq": 0.0, "start": b * bar + k * bar / 8.0 + 0.04, "len": 0.07, "vol": 0.12})
		var fanfare := [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25, 523.25, 392.0]
		for k in range(fanfare.size()):
			events.append({"f": "horn", "freq": fanfare[k], "start": k * 0.9, "len": 0.82, "vol": 0.30})
	else:
		var bar := 1.9
		var chords := [
			[261.63, 329.63, 392.00],
			[392.00, 493.88, 587.33],
			[440.00, 523.25, 659.25],
			[349.23, 440.00, 523.25],
		]
		for b in range(4):
			for k in range(4):
				events.append({"f": "pluck", "freq": chords[b][k % 3] * 2.0, "start": b * bar + k * bar / 4.0, "len": bar / 4.0 * 0.95, "vol": 0.40})
			events.append({"f": "bass", "freq": chords[b][0] / 2.0, "start": b * bar, "len": bar, "vol": 0.34})
			for k in range(4):
				events.append({"f": "shaker", "freq": 0.0, "start": b * bar + k * bar / 4.0 + 0.09, "len": 0.07, "vol": 0.08})
		var melody := [523.25, 587.33, 659.25, 783.99, 659.25, 587.33, 523.25, 440.00, 523.25, 659.25, 783.99, 1046.50]
		for k in range(melody.size()):
			events.append({"f": "flute", "freq": melody[k], "start": k * 0.6, "len": 0.55, "vol": 0.26})
	return _render_events(events, duration, 16000)

func _generate_menu_theme() -> AudioStreamWAV:
	var events: Array = []
	var duration := 16.0
	var bar := 16.0 / 6.0
	var chords := [
		[130.81, 164.81, 196.00],
		[98.00, 123.47, 146.83],
		[110.00, 130.81, 164.81],
		[87.31, 110.00, 130.81],
		[130.81, 164.81, 196.00],
		[98.00, 123.47, 146.83],
	]
	for b in range(6):
		var chord: Array = chords[b]
		events.append({"f": "bass", "freq": float(chord[0]) * 0.5, "start": b * bar, "len": bar, "vol": 0.30})
		events.append({"f": "horn", "freq": float(chord[0]), "start": b * bar, "len": bar * 0.95, "vol": 0.10})
		if b % 2 == 0:
			events.append({"f": "pluck", "freq": float(chord[0]) * 4.0, "start": b * bar, "len": 1.2, "vol": 0.06})
		for k in range(4):
			var tone: float = float(chord[k % 3]) * 2.0
			events.append({"f": "pluck", "freq": tone, "start": b * bar + k * bar / 4.0, "len": bar / 4.0 * 0.95, "vol": 0.24})
	var melody := [523.25, 659.25, 587.33, 523.25, 440.00, 392.00, 523.25, 659.25, 783.99, 698.46, 659.25, 523.25]
	for k in range(melody.size()):
		events.append({"f": "flute", "freq": melody[k], "start": k * 1.333, "len": 1.2, "vol": 0.22})
	return _render_events(events, duration, 16000)

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
	if DisplayServer.get_name() == "headless":
		return
	if current_track == track_name and _get_active_music_player().playing:
		return
	_wanted_track = track_name
	
	# 1. Prioriza reprodução de arquivos reais em assets/audio/music/ (.ogg)
	var real_path: String = REAL_MUSIC_FILES.get(track_name, "")
	if real_path != "":
		var stream = _load_audio_file(real_path)
		if stream:
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			_crossfade_to_stream(track_name, stream)
			return
			
	# 2. Fallback procedural de segurança
	if _music_cache.has(track_name):
		_crossfade_to_stream(track_name, _music_cache[track_name])
		return
	if not _music_tasks.has(track_name):
		var task_id := WorkerThreadPool.add_task(func(): _music_results[track_name] = _generate_medieval_track(track_name))
		_music_tasks[track_name] = task_id

func _process(_delta: float) -> void:
	for track in _music_tasks.keys():
		if WorkerThreadPool.is_task_completed(_music_tasks[track]):
			WorkerThreadPool.wait_for_task_completion(_music_tasks[track])
			_music_tasks.erase(track)
			var wav: AudioStreamWAV = _music_results.get(track)
			if wav == null:
				continue
			_music_cache[track] = wav
			if _wanted_track == str(track):
				_crossfade_to_stream(str(track), wav)

func _crossfade_to_stream(track_name: String, stream: AudioStream) -> void:
	current_track = track_name
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	
	var active_p := _get_active_music_player()
	var next_p := _get_inactive_music_player()
	var target_db := linear_to_db(Settings.music_volume)
	
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
		
	next_p.stream = stream
	next_p.volume_db = -60.0
	next_p.play()
	
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	if active_p.playing:
		_crossfade_tween.tween_property(active_p, "volume_db", -60.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_crossfade_tween.tween_property(next_p, "volume_db", target_db, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_crossfade_tween.chain().tween_callback(func():
		active_p.stop()
		active_p.volume_db = target_db
	)
	_active_player_is_primary = not _active_player_is_primary

func stop_music() -> void:
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if music_player:
		music_player.stop()
	if music_player_alt:
		music_player_alt.stop()
	current_track = ""

func _exit_tree() -> void:
	for track in _music_tasks.keys():
		WorkerThreadPool.wait_for_task_completion(_music_tasks[track])
	_music_tasks.clear()

