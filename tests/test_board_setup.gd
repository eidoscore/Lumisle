extends GutTest
## T1.3 + T1.5 — Board state, akses, setup tanpa match awal.


func test_setup_dimensions() -> void:
	var b := Board.new()
	b.setup(7, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(1))
	assert_eq(b.width, 7, "width")
	assert_eq(b.height, 8, "height")
	assert_eq(b.cells.size(), 56, "cells = w*h")
	assert_eq(b.obstacle_layer.size(), 56, "obstacle_layer paralel")


func test_idx_and_access() -> void:
	var b := Board.new()
	b.setup(5, 5, PackedInt32Array([1, 2, 3]), GameRNG.new(1))
	assert_eq(b.idx(2, 3), 17, "idx = y*width+x = 3*5+2")
	b.set_cell(2, 3, TileCodes.encode(4))
	assert_eq(b.get_color(2, 3), 4, "set/get color")
	assert_false(b.in_bounds(-1, 0), "out of bounds kiri")
	assert_false(b.in_bounds(5, 0), "out of bounds kanan")


func test_no_initial_match_100_seeds() -> void:
	# DoD T1.5: 100 board berseed berbeda → tidak ada match awal.
	for seed in range(100):
		var b := Board.new()
		b.setup(8, 9, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(seed))
		assert_false(MatchDetector.has_any_match(b),
			"seed %d: board awal tidak boleh punya match" % seed)


func test_no_initial_match_small_subset() -> void:
	# Subset 4 warna juga harus bersih (lebih sulit, lebih mungkin match).
	for seed in range(50):
		var b := Board.new()
		b.setup(7, 7, PackedInt32Array([1, 2, 3, 4]), GameRNG.new(seed))
		assert_false(MatchDetector.has_any_match(b),
			"subset-4 seed %d: tidak ada match awal" % seed)


func test_obstacle_applied() -> void:
	var b := Board.new()
	var obstacles := [
		{"type": TileCodes.ObstacleType.ICE, "layer": 1, "hp": 2, "positions": [Vector2i(2, 3)]},
		{"type": TileCodes.ObstacleType.CRATE, "layer": 1, "hp": 1, "positions": [Vector2i(0, 0)]},
	]
	b.setup(6, 6, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(1), PackedInt32Array(), obstacles)
	assert_eq(TileCodes.obstacle_type(b.get_obstacle(2, 3)), TileCodes.ObstacleType.ICE, "ice di (2,3)")
	assert_eq(TileCodes.obstacle_hp(b.get_obstacle(2, 3)), 2, "hp ice = 2")
	assert_true(b.cell_blocks_movement(0, 0), "crate menahan gravity")
	assert_false(b.cell_blocks_movement(2, 3), "ice tidak menahan")


func test_setup_deterministic() -> void:
	var b1 := Board.new()
	var b2 := Board.new()
	b1.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(42))
	b2.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(42))
	assert_eq(b1.board_hash(), b2.board_hash(), "setup seed sama → board identik (hash)")
