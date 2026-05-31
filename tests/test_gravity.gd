extends GutTest
## T1.6 — Gravity + Refill (dok 14 §4).


func test_gravity_simple_fall() -> void:
	# Tile di atas, kosong di bawah → jatuh ke bawah.
	# kolom 0: '1' di atas, '.' di bawah
	var b := BoardTestHelper.from_grid(["1", ".", "."])
	var events := Gravity.apply_gravity(b)
	assert_eq(b.get_color(0, 2), 1, "tile jatuh ke baris bawah")
	assert_eq(b.get_color(0, 0), TileCodes.EMPTY, "atas jadi kosong")
	assert_gt(events.size(), 0, "ada event TileFell")
	assert_eq(events[0].type, MoveAction.Type.TILE_FELL, "event TileFell")


func test_gravity_stack() -> void:
	# 1 . 2 . 3 → harus jadi . . 1 2 3 (semua turun ke bawah, urutan dipertahankan)
	var b := BoardTestHelper.from_grid(["1", ".", "2", ".", "3"])
	Gravity.apply_gravity(b)
	assert_eq(b.get_color(0, 0), TileCodes.EMPTY, "(0,0) kosong")
	assert_eq(b.get_color(0, 1), TileCodes.EMPTY, "(0,1) kosong")
	assert_eq(b.get_color(0, 2), 1, "(0,2) = 1")
	assert_eq(b.get_color(0, 3), 2, "(0,3) = 2")
	assert_eq(b.get_color(0, 4), 3, "(0,4) = 3")


func test_gravity_blocker_holds() -> void:
	# Crate (#blocker) di tengah harus menahan tile di atasnya.
	# Pakai obstacle crate via setup, bukan helper.
	var b := Board.new()
	var obstacles := [{"type": TileCodes.ObstacleType.CRATE, "layer": 1, "hp": 1, "positions": [Vector2i(0, 2)]}]
	b.setup(1, 4, PackedInt32Array([1]), GameRNG.new(1), PackedInt32Array(), obstacles)
	# Set manual: tile di (0,0), kosong (0,1), crate (0,2), kosong (0,3)
	b.set_cell(0, 0, TileCodes.encode(1))
	b.set_cell(0, 1, TileCodes.EMPTY)
	b.set_cell(0, 3, TileCodes.EMPTY)
	Gravity.apply_gravity(b)
	# Tile harus berhenti tepat di atas crate (0,1), tidak menembus ke (0,3).
	assert_eq(b.get_color(0, 1), 1, "tile berhenti di atas crate")
	assert_eq(b.get_color(0, 3), TileCodes.EMPTY, "di bawah crate tetap kosong")


func test_refill_fills_empty() -> void:
	var b := BoardTestHelper.from_grid(["..", ".."])
	b.color_subset = PackedInt32Array([1, 2, 3])
	var events := Gravity.apply_refill(b, GameRNG.new(5))
	assert_eq(events.size(), 4, "4 sel kosong terisi")
	for y in range(2):
		for x in range(2):
			assert_ne(b.get_color(x, y), TileCodes.EMPTY, "(%d,%d) terisi" % [x, y])


func test_refill_deterministic() -> void:
	var b1 := BoardTestHelper.from_grid(["...", "...", "..."])
	var b2 := BoardTestHelper.from_grid(["...", "...", "..."])
	b1.color_subset = PackedInt32Array([1, 2, 3, 4])
	b2.color_subset = PackedInt32Array([1, 2, 3, 4])
	Gravity.apply_refill(b1, GameRNG.new(77))
	Gravity.apply_refill(b2, GameRNG.new(77))
	assert_eq(b1.board_hash(), b2.board_hash(), "refill seed sama → identik")


func test_gravity_then_refill_full() -> void:
	# Setelah gravity + refill, tidak boleh ada sel kosong (di sel playable non-blocker).
	var b := BoardTestHelper.from_grid(["1.2", "...", "3.4"])
	b.color_subset = PackedInt32Array([1, 2, 3, 4, 5])
	Gravity.apply_gravity(b)
	Gravity.apply_refill(b, GameRNG.new(9))
	for y in range(b.height):
		for x in range(b.width):
			assert_ne(b.get_color(x, y), TileCodes.EMPTY, "(%d,%d) terisi penuh" % [x, y])
