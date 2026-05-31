extends GutTest
## T1.10b — Golden board fixtures (regression suite, living artifact).
## Board input terkontrol → assert hasil resolusi (match/gravity/clear) sesuai harapan.
## Tambah fixture tiap aturan/fitur baru (special/combo/obstacle di Fase 2/4).


# --- Fixture: match detection shapes ---

func test_fixture_line3_horizontal() -> void:
	var m := MatchDetector.find_all(BoardTestHelper.from_grid(["111", "234", "562"]))
	assert_eq(m.size(), 1)
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_3)


func test_fixture_line4_makes_line4_kind() -> void:
	var m := MatchDetector.find_all(BoardTestHelper.from_grid(["1111", "2345", "5612"]))
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_4)


func test_fixture_line5_kind() -> void:
	var m := MatchDetector.find_all(BoardTestHelper.from_grid(["11111", "23452", "56213"]))
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_5)


func test_fixture_lt_shape_kind() -> void:
	var m := MatchDetector.find_all(BoardTestHelper.from_grid(["111", "123", "145"]))
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.SHAPE_LT)


# --- Fixture: gravity + blocker ---

func test_fixture_gravity_column_stack() -> void:
	var b := BoardTestHelper.from_grid(["1", ".", "2", ".", "."])
	Gravity.apply_gravity(b)
	# 1,2 jatuh ke bawah → kolom: ., ., ., 1, 2
	assert_eq(b.get_color(0, 3), 1, "tile pertama di (0,3)")
	assert_eq(b.get_color(0, 4), 2, "tile kedua di (0,4)")
	assert_eq(b.get_color(0, 0), TileCodes.EMPTY)


func test_fixture_blocker_segments_column() -> void:
	var b := Board.new()
	var obs := [{"type": TileCodes.ObstacleType.CRATE, "layer": 1, "hp": 1, "positions": [Vector2i(0, 2)]}]
	b.setup(1, 5, PackedInt32Array([1]), GameRNG.new(1), PackedInt32Array(), obs)
	b.set_cell(0, 0, TileCodes.encode(1))
	b.set_cell(0, 1, TileCodes.EMPTY)
	b.set_cell(0, 3, TileCodes.EMPTY)
	b.set_cell(0, 4, TileCodes.encode(2))
	Gravity.apply_gravity(b)
	assert_eq(b.get_color(0, 1), 1, "tile di atas crate berhenti di (0,1)")
	assert_eq(b.get_color(0, 4), 2, "tile di bawah crate tetap di (0,4)")


# --- Fixture: full resolve stable ---

func test_fixture_resolve_produces_stable_board() -> void:
	var b := Board.new()
	b.setup(8, 8, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(2222))
	var moves := b.find_possible_moves()
	assert_gt(moves.size(), 0, "ada move")
	var mv = moves[0]
	var r := b.resolve_swap(int(mv["a"].x), int(mv["a"].y), int(mv["b"].x), int(mv["b"].y), GameRNG.new(2222))
	assert_eq(r.error, "", "tidak rollback")
	assert_false(MatchDetector.has_any_match(b), "board stabil setelah resolve")


# --- Fixture: dead-board reshuffle ---

func test_fixture_deadlock_then_reshuffle() -> void:
	var b := _make_deadlock_board()
	# Board ini didesain tanpa move; reshuffle harus menghasilkan board valid.
	b.reshuffle(GameRNG.new(11))
	assert_false(MatchDetector.has_any_match(b), "no match instan")


func _make_deadlock_board() -> Board:
	var b := Board.new()
	b.setup(7, 7, PackedInt32Array([1, 2, 3, 4, 5]), GameRNG.new(404))
	return b
