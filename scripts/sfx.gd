class_name SfxBank
extends Node

## Mezcla los efectos en un generador de audio. En la web, los WAV creados
## en código no suenan; este camino sí, y se reanuda con el primer clic.

var enabled := true
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array = []
var _rate := 22050.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		set_process(false)
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = _rate
	generator.buffer_length = 0.25
	_player = AudioStreamPlayer.new()
	_player.stream = generator
	_player.volume_db = 0.0
	add_child(_player)
	_rng.seed = 17
	_ensure_playing()


func _process(_delta: float) -> void:
	if not enabled:
		return
	_ensure_playing()
	if _playback == null:
		return
	var available := _playback.get_frames_available()
	var count := mini(available, 2048)
	for _i in count:
		var sample := 0.0
		var alive: Array = []
		for voice in _voices:
			var age := float(voice.age)
			var dur := float(voice.dur)
			age += 1.0 / _rate
			voice.age = age
			if age >= dur:
				continue
			alive.append(voice)
			if age < 0.0:
				continue
			var sounded := age
			var t := sounded / dur
			var env := 1.0 - t
			if age < 0.006:
				env *= age / 0.006
			var freq := lerpf(float(voice.freq), float(voice.freq_to), t)
			var shaped := 0.0
			if int(voice.shape) == 1:
				shaped = _rng.randf_range(-1.0, 1.0)
			else:
				voice.phase = float(voice.phase) + TAU * freq / _rate
				var sine := sin(float(voice.phase))
				shaped = (1.0 if sine >= 0.0 else -1.0) if int(voice.shape) == 0 else sine
			sample += shaped * env * float(voice.amp)
		_voices = alive
		sample = clampf(sample, -1.0, 1.0)
		_playback.push_frame(Vector2(sample, sample))


func unlock() -> void:
	_resume_web_audio()
	_ensure_playing()
	_add(660.0, 740.0, 0.09, 0.42, 2, 0.0)


func set_muted(turn_off: bool) -> void:
	enabled = not turn_off
	set_process(enabled)
	if enabled:
		unlock()


func play(kind: String) -> void:
	if not enabled:
		return
	_ensure_playing()
	match kind:
		"arrow":
			_add(920.0, 420.0, 0.07, 0.38, 0, 0.0)
		"orb":
			_add(380.0, 980.0, 0.2, 0.46, 2, 0.0)
		"shell":
			_add(140.0, 70.0, 0.22, 0.62, 1, 0.0)
		"pop":
			_add(640.0, 180.0, 0.09, 0.4, 2, 0.0)
		"leak":
			_add(220.0, 70.0, 0.24, 0.5, 0, 0.0)
		"buy":
			_add(520.0, 780.0, 0.07, 0.36, 0, 0.0)
		"error":
			_add(240.0, 90.0, 0.16, 0.42, 0, 0.0)
		"wave":
			_add(392.0, 392.0, 0.12, 0.4, 2, 0.0)
			_add(523.0, 523.0, 0.16, 0.4, 2, 0.1)
		"win":
			_add(523.0, 523.0, 0.16, 0.42, 2, 0.0)
			_add(659.0, 659.0, 0.16, 0.42, 2, 0.14)
			_add(784.0, 784.0, 0.16, 0.42, 2, 0.28)
			_add(1046.0, 1046.0, 0.28, 0.46, 2, 0.42)
		"lose":
			_add(392.0, 330.0, 0.18, 0.42, 2, 0.0)
			_add(262.0, 196.0, 0.32, 0.42, 2, 0.16)
		"silent":
			pass
		_:
			_add(440.0, 440.0, 0.08, 0.35, 2, 0.0)


func shoot(kind: String) -> void:
	match kind:
		"orb":
			play("orb")
		"shell":
			play("shell")
		_:
			play("arrow")


func _ensure_playing() -> void:
	if _player == null:
		return
	if not _player.playing:
		_player.play()
	if _playback == null:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _resume_web_audio() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		try {
			if (typeof GodotAudio !== 'undefined' && GodotAudio.ctx && GodotAudio.ctx.state !== 'running') {
				GodotAudio.ctx.resume();
			}
		} catch (e) {}
	""", true)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, false)
		AudioServer.set_bus_volume_db(master, 0.0)


func _add(freq: float, freq_to: float, dur: float, amp: float, shape: int, delay: float) -> void:
	if _voices.size() > 14:
		_voices.pop_front()
	_voices.append({
		"freq": freq,
		"freq_to": freq_to,
		"dur": dur + delay,
		"amp": amp,
		"shape": shape,
		"phase": 0.0,
		"age": -delay,
	})
