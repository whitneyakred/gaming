class_name ActionAudio
extends RefCounted
static func make(kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.3 if kind != "eat" else 0.42
	var count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 143
	for i in count:
		var t := float(i) / sample_rate
		var u := float(i) / count
		var envelope := sin(PI*u) * (1-u)
		var frequency := lerpf(380, 720, u) if kind == "scope_open" else lerpf(680, 260, u)
		var value := sin(TAU*frequency*t)*0.3 + rng.randf_range(-1,1)*0.12
		if kind == "eat": value = rng.randf_range(-1,1) * pow(maxf(0,sin(t*TAU*9)),4) * 0.65
		bytes.encode_s16(i*2, int(value * envelope * 19000))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.data = bytes
	return sound
