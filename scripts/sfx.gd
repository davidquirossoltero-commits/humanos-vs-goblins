class_name SfxBank
extends Node

var enabled := true
var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _cursor := 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		return
	_streams = {
		"arrow": _tone(740.0, 0.06, 0),
		"orb": _sweep(380.0, 820.0, 0.16),
		"shell": _noise(0.16),
		"pop": _tone(220.0, 0.07, 2),
		"leak": _sweep(180.0, 70.0, 0.2),
		"buy": _tone(520.0, 0.05, 0),
		"error": _sweep(200.0, 90.0, 0.12),
		"wave": _tone(330.0, 0.1, 0),
		"win": _melody([523.0, 659.0, 784.0, 1046.0], 0.14),
		"lose": _melody([392.0, 330.0, 262.0, 196.0], 0.16),
		"silent": _tone(40.0, 0.02, 2),
	}
	for _i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func unlock() -> void:
	play("silent")


func play(kind: String) -> void:
	if not enabled or _players.is_empty():
		return
	var stream: AudioStream = _streams.get(kind)
	if stream == null:
		return
	var player := _players[_cursor % _players.size()]
	_cursor += 1
	player.stream = stream
	player.play()


func shoot(kind: String) -> void:
	match kind:
		"orb":
			play("orb")
		"shell":
			play("shell")
		_:
			play("arrow")


func _make(frames: PackedByteArray, rate: int = 22050) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = frames
	return stream


func _pack(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var sample := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 255
		data[i * 2 + 1] = (sample >> 8) & 255
	return data


func _tone(freq: float, dur: float, wave: int) -> AudioStreamWAV:
	var rate := 22050
	var n := maxi(int(float(rate) * dur), 1)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	var step := TAU * freq / float(rate)
	for i in n:
		var env := 1.0 - float(i) / float(n)
		var s := sin(phase)
		if wave == 0:
			s = 1.0 if sin(phase) >= 0.0 else -1.0
		elif wave == 1:
			s = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
		samples[i] = s * env * 0.18
		phase += step
	return _make(_pack(samples), rate)


func _sweep(freq_a: float, freq_b: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var n := maxi(int(float(rate) * dur), 1)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var freq := lerpf(freq_a, freq_b, t)
		phase += TAU * freq / float(rate)
		var env := 1.0 - t
		samples[i] = sin(phase) * env * 0.2
	return _make(_pack(samples), rate)


func _noise(dur: float) -> AudioStreamWAV:
	var rate := 22050
	var n := maxi(int(float(rate) * dur), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var samples := PackedFloat32Array()
	samples.resize(n)
	var acc := 0.0
	for i in n:
		var t := float(i) / float(n)
		acc = lerpf(acc, rng.randf_range(-1.0, 1.0), 0.35)
		samples[i] = acc * (1.0 - t) * 0.45
	return _make(_pack(samples), rate)


func _melody(notes: Array, note_dur: float) -> AudioStreamWAV:
	var rate := 22050
	var per := maxi(int(float(rate) * note_dur), 1)
	var samples := PackedFloat32Array()
	samples.resize(per * notes.size())
	var index := 0
	for freq in notes:
		var phase := 0.0
		var step := TAU * float(freq) / float(rate)
		for i in per:
			var env := 1.0 - float(i) / float(per)
			samples[index] = sin(phase) * env * 0.2
			phase += step
			index += 1
	return _make(_pack(samples), rate)
