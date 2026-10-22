class_name Synth
extends RefCounted
## Tiny offline synthesizer used by tools/generate_audio.gd to render every
## sound in the game from code: sine/triangle voices, noise, pitch sweeps and
## exponential envelopes, mixed into a float buffer.

const RATE := 22050

var buffer := PackedFloat32Array()
## When true, writes past the end wrap to the start (seamless music loops).
var circular := false


func _init(seconds: float, p_circular: bool = false) -> void:
	buffer.resize(int(seconds * RATE))
	buffer.fill(0.0)
	circular = p_circular


func length() -> int:
	return buffer.size()


static func note_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## A tone with optional pitch sweep, harmonics and an attack/decay envelope.
## decay is the time constant of the exponential tail, in seconds.
func tone(start: float, duration: float, hz_from: float, hz_to: float, gain: float,
		attack: float = 0.004, decay: float = 0.1, shape: String = "sine",
		harmonics: PackedFloat32Array = PackedFloat32Array()) -> void:
	var s0 := int(start * RATE)
	var n := int(duration * RATE)
	var phase := 0.0
	var size := buffer.size()
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / maxf(n - 1, 1)
		var hz := lerpf(hz_from, hz_to, k * k * (3.0 - 2.0 * k))
		phase += TAU * hz / RATE
		var v := _wave(phase, shape)
		for h in harmonics.size():
			v += sin(phase * (h + 2)) * harmonics[h]
		var env := minf(t / maxf(attack, 0.0001), 1.0) * exp(-t / maxf(decay, 0.0001))
		# Short fade at the very end avoids clicks.
		env *= minf(float(n - i) / (0.004 * RATE), 1.0)
		var idx := s0 + i
		if circular:
			idx = posmod(idx, size)
		elif idx >= size:
			break
		buffer[idx] += v * env * gain


## A slow pad voice: sine with gentle vibrato and a long attack/release.
func pad(start: float, duration: float, hz: float, gain: float, attack: float, release: float, detune: float = 0.0) -> void:
	var s0 := int(start * RATE)
	var n := int((duration + release) * RATE)
	var size := buffer.size()
	var phase := 0.0
	var f := hz * pow(2.0, detune / 1200.0)
	for i in n:
		var t := float(i) / RATE
		phase += TAU * f * (1.0 + 0.0015 * sin(TAU * 0.21 * t)) / RATE
		var env := minf(t / attack, 1.0)
		if t > duration:
			env *= maxf(1.0 - (t - duration) / release, 0.0)
		var v := sin(phase) + 0.18 * sin(phase * 2.0) + 0.06 * sin(phase * 3.0)
		var idx := s0 + i
		if circular:
			idx = posmod(idx, size)
		elif idx >= size:
			break
		buffer[idx] += v * env * gain


## Filtered noise burst. `brightness` 0..1 sets a one-pole low-pass.
func noise(start: float, duration: float, gain: float, brightness: float, attack: float = 0.002, decay: float = 0.05, rng_seed: int = 1) -> void:
	var rng := SeededRng.new(rng_seed)
	var s0 := int(start * RATE)
	var n := int(duration * RATE)
	var size := buffer.size()
	var lp := 0.0
	var a := clampf(brightness, 0.01, 1.0)
	for i in n:
		var t := float(i) / RATE
		var white := rng.next_float() * 2.0 - 1.0
		lp += (white - lp) * a
		var env := minf(t / maxf(attack, 0.0001), 1.0) * exp(-t / maxf(decay, 0.0001))
		env *= minf(float(n - i) / (0.004 * RATE), 1.0)
		var idx := s0 + i
		if circular:
			idx = posmod(idx, size)
		elif idx >= size:
			break
		buffer[idx] += lp * env * gain


## Scales the buffer so its peak sits at `peak`.
func normalize(peak: float) -> void:
	var m := 0.0
	for v in buffer:
		m = maxf(m, absf(v))
	if m <= 0.0:
		return
	var k := peak / m
	for i in buffer.size():
		buffer[i] *= k


## Soft saturation to tame peaks without hard clipping.
func soft_clip() -> void:
	for i in buffer.size():
		var v := buffer[i]
		buffer[i] = v / (1.0 + absf(v) * 0.35)


func to_stream() -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		bytes.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s


static func _wave(phase: float, shape: String) -> float:
	match shape:
		"triangle":
			var p := fposmod(phase / TAU, 1.0)
			return 4.0 * absf(p - 0.5) - 1.0
		"soft_square":
			return tanh(sin(phase) * 3.0)
	return sin(phase)
