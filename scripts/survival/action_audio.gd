class_name ActionAudio
extends RefCounted
static func make(kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.24 if kind == "eat" else 0.3
	var count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 143
	var filtered := 0.0
	var phase := 0.0
	for i in count:
		var t := float(i) / sample_rate
		var u := float(i) / count
		var envelope := sin(PI*u) * (1-u)
		var frequency := lerpf(380, 720, u) if kind == "scope_open" else lerpf(680, 260, u)
		var value := sin(TAU*frequency*t)*0.3 + rng.randf_range(-1,1)*0.12
		if kind in ["eat", "eat_complete"]:
			# Soft, low-passed chewing pulses, then a short voiced completion burp.
			filtered = lerpf(filtered, rng.randf_range(-1,1), 0.16)
			var chew := pow(sin(PI*u),2.0) if kind == "eat" else 0.0
			value = filtered * chew * 0.65
			if kind == "eat_complete":
				var b := u
				phase += TAU * lerpf(145.0,78.0,b) / sample_rate
				value += (sin(phase)+0.3*sin(phase*2.0)+0.12*sin(phase*3.0)) * sin(PI*b) * 0.2
			envelope = smoothstep(0.0,0.015,t) * (1.0-smoothstep(0.94,1.0,u))
		bytes.encode_s16(i*2, int(value * envelope * 19000))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.data = bytes
	return sound
