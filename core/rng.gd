class_name GameRNG extends RefCounted
## RNG berseed deterministik. SEMUA randomness gameplay lewat sini (dok 14 §0).
## JANGAN pakai randi()/randf() global. Acuan: docs/04-tdd-arsitektur.md §3.6.
## rng_algorithm_version: naik kalau algoritma berubah (reproducibility, dok 14 §8).

const RNG_ALGORITHM_VERSION := 1

var _rng: RandomNumberGenerator
var _seed: int


func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	_seed = seed_value
	_rng.seed = seed_value


## Seed yang dipakai (untuk reproduksi / simpan ke level).
func get_seed() -> int:
	return _seed


## Set ulang seed (reset state stream).
func set_seed(seed_value: int) -> void:
	_seed = seed_value
	_rng.seed = seed_value


## Integer acak 0..max_exclusive-1. Deterministik per seed + urutan panggil.
func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		return 0
	return _rng.randi() % max_exclusive


## Integer acak inklusif [min_val, max_val].
func next_range(min_val: int, max_val: int) -> int:
	if max_val <= min_val:
		return min_val
	return min_val + next_int(max_val - min_val + 1)


## Pilih satu elemen acak dari array warna (atau array int apa pun).
func pick(arr: Array) -> int:
	if arr.is_empty():
		return -1
	return arr[next_int(arr.size())]


## Pilih dari PackedInt32Array (mis. color_subset level).
func pick_packed(arr: PackedInt32Array) -> int:
	if arr.is_empty():
		return -1
	return arr[next_int(arr.size())]


## Fisher-Yates shuffle in-place, deterministik.
## Implementasi WAJIB identik kalau kelak diport ke GDExtension (dok 05 §6.1).
func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := next_int(i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
