class_name ActionAudio
extends RefCounted
static func make(kind: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.55 if kind == "eat_complete" else (0.24 if kind in ["eat","bandage"] else 0.3)
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
				phase += TAU * (lerpf(165.0,65.0,b)+sin(b*TAU*3.0)*15.0) / sample_rate
				value += (sin(phase)+0.3*sin(phase*2.0)+0.12*sin(phase*3.0)) * sin(PI*b) * 0.38
			envelope = smoothstep(0.0,0.015,t) * (1.0-smoothstep(0.94,1.0,u))
		if kind == "bandage":
			filtered = lerpf(filtered,rng.randf_range(-1,1),0.35)
			value = filtered * 0.45
		elif kind == "heal":
			value = (sin(TAU*660*t)+sin(TAU*880*t)*0.5)*0.3
		if kind in ["chop","tree_fall","axe_swing"]:
			filtered = lerpf(filtered,rng.randf_range(-1,1),0.35)
			if kind == "axe_swing": value = filtered*sin(PI*u)*0.45
			else:
				value = (sin(TAU*(180.0 if kind=="chop" else 85.0)*t)*0.55+filtered*0.5)*exp(-u*7.0)
				if kind=="tree_fall": value += filtered*pow(1-u,2)*0.65
			envelope = minf(t*500,1.0)
		if kind in ["stone_hit","stone_break"]:
			filtered = lerpf(filtered,rng.randf_range(-1,1),0.7)
			value = (sin(TAU*1230*t)*0.18+sin(TAU*1870*t)*0.13+filtered*0.75)*exp(-u*(12.0 if kind=="stone_hit" else 5.0))
			envelope = minf(t*700,1.0)
		bytes.encode_s16(i*2, int(clampf(value * envelope,-1.0,1.0) * 19000))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.data = bytes
	return sound
