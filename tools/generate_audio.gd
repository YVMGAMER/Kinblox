extends SceneTree
## Renders every Kinblox sound from code into assets/audio/*.wav.
##   godot --headless --path . -s tools/generate_audio.gd
## Output is deterministic. Everything is in the D major pentatonic palette
## (D E F# A B) so effects and music never clash.

const OUT := "res://assets/audio/"


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	_sfx()
	_music_ambient()
	_music_zen()
	print("Audio generated in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit(0)


func _n(midi: float) -> float:
	return Synth.note_hz(midi)


func _save(s: Synth, name: String, peak: float) -> void:
	s.soft_clip()
	s.normalize(peak)
	var err := s.to_stream().save_to_wav(OUT + name + ".wav")
	print("  %s.wav (%d samples) %s" % [name, s.length(), "ok" if err == OK else "ERROR %d" % err])


func _sfx() -> void:
	var bell := PackedFloat32Array([0.32, 0.0, 0.14])

	var s := Synth.new(0.05)
	s.tone(0.0, 0.04, 1900.0, 1650.0, 0.6, 0.001, 0.012)
	s.noise(0.0, 0.02, 0.12, 0.6, 0.001, 0.006, 3)
	_save(s, "sfx_move", 0.45)

	s = Synth.new(0.04)
	s.tone(0.0, 0.035, 620.0, 480.0, 0.5, 0.001, 0.01)
	_save(s, "sfx_soft_drop", 0.3)

	s = Synth.new(0.09)
	s.tone(0.0, 0.08, _n(86), _n(85.6), 0.7, 0.001, 0.028, "sine", PackedFloat32Array([0.25]))
	s.tone(0.0, 0.05, _n(98), _n(98), 0.12, 0.001, 0.012)
	_save(s, "sfx_rotate", 0.5)

	s = Synth.new(0.14)
	s.tone(0.0, 0.13, 190.0, 95.0, 1.0, 0.002, 0.045)
	s.noise(0.0, 0.05, 0.35, 0.22, 0.001, 0.012, 5)
	_save(s, "sfx_lock", 0.6)

	s = Synth.new(0.26)
	s.tone(0.0, 0.24, 150.0, 46.0, 1.0, 0.001, 0.075)
	s.noise(0.0, 0.14, 0.55, 0.3, 0.001, 0.03, 7)
	s.tone(0.0, 0.05, 1100.0, 300.0, 0.18, 0.001, 0.015)
	_save(s, "sfx_hard_drop", 0.85)

	s = Synth.new(0.22)
	s.tone(0.0, 0.1, _n(81), _n(81), 0.6, 0.002, 0.045, "triangle")
	s.tone(0.06, 0.14, _n(86), _n(86), 0.6, 0.002, 0.06, "triangle")
	_save(s, "sfx_hold", 0.5)

	s = Synth.new(0.7)
	var arp := [86, 90, 93]
	for i in arp.size():
		s.tone(i * 0.05, 0.6, _n(arp[i]), _n(arp[i]), 0.5, 0.002, 0.17, "sine", bell)
	s.noise(0.0, 0.35, 0.1, 0.9, 0.05, 0.1, 11)
	_save(s, "sfx_clear", 0.7)

	s = Synth.new(1.1)
	var quad := [86, 90, 93, 98, 102]
	for i in quad.size():
		s.tone(i * 0.055, 0.9, _n(quad[i]), _n(quad[i]), 0.45, 0.002, 0.28, "sine", bell)
	s.tone(0.0, 1.0, _n(50), _n(50), 0.5, 0.01, 0.35, "sine", PackedFloat32Array([0.2]))
	s.noise(0.0, 0.6, 0.12, 0.95, 0.1, 0.18, 13)
	_save(s, "sfx_clear_quad", 0.8)

	# Chain: a bell plus its fifth; AudioManager pitches it up each step.
	s = Synth.new(0.6)
	s.tone(0.0, 0.55, _n(81), _n(81), 0.6, 0.002, 0.16, "sine", PackedFloat32Array([0.4, 0.0, 0.2]))
	s.tone(0.0, 0.5, _n(88), _n(88), 0.28, 0.002, 0.12, "sine", bell)
	s.tone(0.0, 0.08, _n(105), _n(105), 0.1, 0.001, 0.02)
	_save(s, "sfx_chain", 0.7)

	s = Synth.new(1.0)
	var up := [74, 81, 86, 90, 93]
	for i in up.size():
		s.tone(i * 0.075, 0.7, _n(up[i]), _n(up[i]), 0.5, 0.003, 0.2, "triangle", PackedFloat32Array([0.15]))
	_save(s, "sfx_level_up", 0.7)

	s = Synth.new(1.8)
	var down := [81, 78, 74, 69]
	for i in down.size():
		s.tone(i * 0.2, 0.9, _n(down[i]), _n(down[i]) * 0.995, 0.5, 0.004, 0.32, "sine", PackedFloat32Array([0.2, 0.05]))
	s.pad(0.0, 0.9, _n(50), 0.25, 0.08, 0.8)
	_save(s, "sfx_game_over", 0.6)

	s = Synth.new(1.3)
	s.noise(0.0, 1.2, 0.5, 0.06, 0.45, 0.5, 17)
	s.pad(0.1, 0.5, _n(74), 0.18, 0.3, 0.6)
	s.pad(0.1, 0.5, _n(81), 0.12, 0.3, 0.6)
	_save(s, "sfx_zen_sweep", 0.5)

	s = Synth.new(0.04)
	s.tone(0.0, 0.035, 1500.0, 1380.0, 0.6, 0.001, 0.01)
	_save(s, "sfx_ui_tap", 0.4)

	s = Synth.new(0.05)
	s.tone(0.0, 0.04, 1050.0, 860.0, 0.6, 0.001, 0.012)
	_save(s, "sfx_ui_back", 0.4)

	s = Synth.new(0.16)
	s.tone(0.0, 0.14, _n(81), _n(81), 0.6, 0.002, 0.05, "triangle")
	_save(s, "sfx_countdown", 0.45)


## Four 8-second chords, pads plus sparse pentatonic bells. Rendered into a
## circular buffer so release tails wrap around and the loop is seamless.
func _music_ambient() -> void:
	var chord_len := 8.0
	var chords := [
		[50, 57, 61, 64, 66],  # Dmaj9
		[47, 54, 57, 61, 62],  # Bm9
		[43, 50, 54, 57, 59],  # Gmaj9
		[45, 52, 54, 59, 62],  # A6sus
	]
	var s := Synth.new(chord_len * chords.size(), true)
	for c in chords.size():
		var start := c * chord_len
		for note: int in chords[c]:
			s.pad(start, chord_len, _n(note), 0.05, 2.5, 3.0, -5.0)
			s.pad(start, chord_len, _n(note), 0.05, 2.5, 3.0, 5.0)
		s.pad(start, chord_len, _n(chords[c][0] - 12), 0.06, 1.5, 2.0)
	_bells(s, [74, 76, 78, 81, 83, 86], 0.5, 0.45, 0.07, 101)
	_save(s, "music_ambient", 0.42)


## Slower, airier and sparser for Zen.
func _music_zen() -> void:
	var chord_len := 10.0
	var chords := [
		[62, 66, 69, 73],  # Dmaj7
		[59, 62, 66, 69],  # Bm7
		[55, 59, 62, 66],  # Gmaj7
		[57, 62, 64, 69],  # Asus4
	]
	var s := Synth.new(chord_len * chords.size(), true)
	for c in chords.size():
		var start := c * chord_len
		for note: int in chords[c]:
			s.pad(start, chord_len, _n(note), 0.045, 3.5, 4.0, -4.0)
			s.pad(start, chord_len, _n(note - 12), 0.035, 3.5, 4.0, 4.0)
	_bells(s, [81, 83, 86, 88, 90], 1.0, 0.3, 0.05, 202)
	_save(s, "music_zen", 0.36)


func _bells(s: Synth, scale: Array, step: float, chance: float, gain: float, rng_seed: int) -> void:
	var rng := SeededRng.new(rng_seed)
	var total := float(s.length()) / Synth.RATE
	var t := 0.0
	while t < total:
		if rng.next_float() < chance:
			var note: int = scale[rng.next_int(scale.size())]
			s.tone(t, 2.6, _n(note), _n(note), gain, 0.004, 0.65, "sine", PackedFloat32Array([0.22, 0.0, 0.08]))
		t += step
