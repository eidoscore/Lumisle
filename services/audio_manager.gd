extends Node
## AudioManager (autoload) — T2.6. Pool AudioStreamPlayer + SFX gameplay.
## Spec: docs/04-tdd-arsitektur.md §13.
##
## CATATAN: Fase 2 belum punya aset .ogg final (art/audio = paralel). Supaya juice
## bisa diuji SEKARANG tanpa file, SFX dibuat PROSEDURAL (AudioStreamGenerator-free:
## kita sintesis PCM ke AudioStreamWAV sekali saat init). Saat aset final masuk
## (T8.7), cukup ganti _make_* dengan load(".ogg") — API play_sfx tidak berubah.

const POOL_SIZE := 12
const MIX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _sfx: Dictionary = {}          # id -> AudioStreamWAV
var _enabled := true


func _ready() -> void:
	set_process(false)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_build_sfx()


func set_enabled(on: bool) -> void:
	_enabled = on


## Mainkan SFX by id. pitch_scale untuk variasi (mis. naik per tingkat cascade).
func play_sfx(sfx_id: String, pitch_scale: float = 1.0) -> void:
	if not _enabled:
		return
	if not _sfx.has(sfx_id):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[sfx_id]
	p.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	p.play()


## STUB musik latar — diisi T8.7 (butuh aset). API stabil.
func play_music(_music_id: String) -> void:
	pass


# ---------------------------------------------------------------------------
# Sintesis SFX prosedural (placeholder sampai aset .ogg final, T8.7).
# ---------------------------------------------------------------------------

func _build_sfx() -> void:
	# match: blip naik singkat. special: whoosh. combo: dentum. menang: arpeggio.
	_sfx["match"] = _make_blip(660.0, 0.10, 0.35)
	_sfx["special"] = _make_blip(440.0, 0.18, 0.4, 1.6)   # sweep naik
	_sfx["combo"] = _make_noise_thud(0.22, 0.5)
	_sfx["win"] = _make_arpeggio([523.0, 659.0, 784.0, 1046.0], 0.5)
	_sfx["lose"] = _make_arpeggio([392.0, 330.0, 262.0], 0.45)
	_sfx["invalid"] = _make_blip(180.0, 0.08, 0.25)
	_sfx["tap"] = _make_blip(880.0, 0.05, 0.22)


## Nada sederhana (sine) dengan envelope decay. freq_mul>1 → sweep naik.
func _make_blip(freq: float, dur: float, vol: float, freq_mul: float = 1.0) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var prog: float = float(i) / float(n)
		var f: float = freq * lerpf(1.0, freq_mul, prog)
		var env: float = (1.0 - prog)           # linear decay
		var s: float = sin(TAU * f * t) * env * vol
		_write_s16(data, i, s)
	return _wav_from(data)


## Dentum: noise + low sine, decay cepat (untuk combo/ledakan).
func _make_noise_thud(dur: float, vol: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var prog: float = float(i) / float(n)
		var env: float = pow(1.0 - prog, 2.0)
		var noise: float = rng.randf_range(-1.0, 1.0)
		var low: float = sin(TAU * 90.0 * t)
		var s: float = (low * 0.7 + noise * 0.3) * env * vol
		_write_s16(data, i, s)
	return _wav_from(data)


## Arpeggio beberapa nada berurutan (untuk menang/kalah).
func _make_arpeggio(freqs: Array, total_dur: float) -> AudioStreamWAV:
	var n: int = int(MIX_RATE * total_dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var seg: int = maxi(1, int(n / max(1, freqs.size())))
	for i in range(n):
		var t: float = float(i) / MIX_RATE
		var idx: int = mini(int(i / seg), freqs.size() - 1)
		var f: float = freqs[idx]
		var local_prog: float = float(i % seg) / float(seg)
		var env: float = (1.0 - local_prog) * 0.4
		var s: float = sin(TAU * f * t) * env
		_write_s16(data, i, s)
	return _wav_from(data)


func _write_s16(data: PackedByteArray, i: int, sample: float) -> void:
	var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
	data[i * 2] = v & 0xFF
	data[i * 2 + 1] = (v >> 8) & 0xFF


func _wav_from(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w
