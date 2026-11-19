class_name FishingAudio
extends Node
## Original synthesized effects; uses the user's Effects volume and focus mute.
var voice: AudioStreamPlayer
var reel: AudioStreamPlayer
var sounds: Dictionary = {}
func _ready() -> void:
	voice = AudioStreamPlayer.new()
	voice.bus = "Effects"
	add_child(voice)
	reel = AudioStreamPlayer.new()
	reel.bus = "Effects"
	add_child(reel)
	for kind in ["cast", "splash", "bite", "catch", "snap", "reel"]:
		sounds[kind] = synthesize(kind)
	reel.stream = sounds.reel

func play(kind: String) -> void:
	voice.stream = sounds[kind]
	voice.play()

func set_reeling(value: bool, tension: float = 0.5) -> void:
	reel.pitch_scale = 0.85 + tension * 0.45
	if value and not reel.playing:
		reel.play()
	elif not value:
		reel.stop()

func synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = {"cast": 0.24, "splash": 0.38, "bite": 0.42, "catch": 0.65, "snap": 0.3, "reel": 0.16}[kind]
	var count := int(duration * 22050)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1729
	for i in count:
		var t := float(i) / 22050.0
		var p := float(i) / count
		var env := minf(t / 0.006, 1.0) * pow(1.0 - p, 2.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := 0.0
		match kind:
			"cast": sample = (noise * 0.45 + sin(TAU * (600.0 * t - 800.0 * t * t)) * 0.2) * sin(PI * p) * 0.25
			"splash": sample = (noise * 0.7 + sin(TAU * (170.0 * t - 130.0 * t * t)) * 0.3) * env * 0.32
			"bite": sample = sin(TAU * (880.0 if p < 0.45 else 1174.66) * t) * env * 0.24
			"catch":
				var note: float = [523.25, 659.25, 783.99, 1046.5][mini(3, int(p * 4))]
				sample = (sin(TAU * note * t) + 0.2 * sin(TAU * note * 2.0 * t)) * env * 0.25
			"snap": sample = (noise * exp(-t * 40.0) + sin(TAU * (420.0 * t - 500.0 * t * t)) * env * 0.4) * 0.4
			"reel": sample = (noise * 0.5 + sin(TAU * 1500.0 * t) * 0.5) * exp(-fmod(t, 0.04) * 240.0) * 0.15
		bytes.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	if kind == "reel":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func _exit_tree() -> void:
	voice.stop()
	reel.stop()
	voice.stream = null
	reel.stream = null
	sounds.clear()
