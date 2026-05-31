extends GutTest
## T1.10 — Determinisme & replay runner (dok 14 §7).
## Seed sama + move sama → urutan board_hash identik.


## Replay runner: jalankan daftar move pada board berseed, kumpulkan board_hash tiap langkah.
func _replay(seed: int, moves: Array) -> Array:
	var b := Board.new()
	b.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(seed))
	var hashes: Array = [b.board_hash()]
	var move_rng := GameRNG.new(seed + 1000)
	for mv in moves:
		b.resolve_swap(mv[0], mv[1], mv[2], mv[3], move_rng)
		hashes.append(b.board_hash())
	return hashes


func test_setup_same_seed_identical() -> void:
	var a := Board.new()
	var b := Board.new()
	a.setup(8, 9, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(2024))
	b.setup(8, 9, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(2024))
	assert_eq(a.board_hash(), b.board_hash(), "setup seed sama identik")


func test_setup_different_seed_differs() -> void:
	var a := Board.new()
	var b := Board.new()
	a.setup(8, 9, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(1))
	b.setup(8, 9, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(2))
	assert_ne(a.board_hash(), b.board_hash(), "seed beda → board (umumnya) beda")


func test_replay_identical_twice() -> void:
	# Ambil move valid dari board berseed, lalu replay 2x → urutan hash identik.
	var probe := Board.new()
	probe.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(555))
	var moves: Array = []
	var mrng := GameRNG.new(1555)
	# Bangun urutan 8 move valid dari board kerja terpisah.
	var work := Board.new()
	work.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(555))
	for i in range(8):
		var pm := work.find_possible_moves()
		if pm.is_empty():
			break
		var mv = pm[0]
		moves.append([int(mv["a"].x), int(mv["a"].y), int(mv["b"].x), int(mv["b"].y)])
		work.resolve_swap(int(mv["a"].x), int(mv["a"].y), int(mv["b"].x), int(mv["b"].y), mrng)

	var run1 := _replay(555, moves)
	var run2 := _replay(555, moves)
	assert_eq(run1, run2, "replay 2x dgn seed+move sama → urutan hash identik")
	assert_gt(run1.size(), 1, "ada langkah yang ter-replay")
