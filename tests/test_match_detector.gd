extends GutTest
## T1.4 — MatchDetector: deteksi match 3/4/5/L/T simultan (dok 14 §2).


func _find(rows: Array) -> Array:
	return MatchDetector.find_all(BoardTestHelper.from_grid(rows))


func test_horizontal_3() -> void:
	var m := _find(["111", "234", "562"])
	assert_eq(m.size(), 1, "1 match")
	assert_eq(m[0]["cells"].size(), 3, "3 cell")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_3, "LINE_3")


func test_vertical_3() -> void:
	# Kolom 0 = 1,1,1 (vertikal). Sisanya tidak match.
	var m := _find(["123", "145", "162"])
	assert_eq(m.size(), 1, "1 match vertikal")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_3, "LINE_3")
	assert_eq(m[0]["orientation"], "v", "vertikal")


func test_line_4_horizontal() -> void:
	var m := _find(["1111", "2345", "5621"])
	assert_eq(m.size(), 1, "1 match")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_4, "LINE_4")
	assert_eq(m[0]["orientation"], "h", "horizontal")


func test_line_5_horizontal() -> void:
	var m := _find(["11111", "23452", "56213"])
	assert_eq(m.size(), 1, "1 match")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.LINE_5, "LINE_5")


func test_no_match() -> void:
	var m := _find(["123", "231", "312"])
	assert_eq(m.size(), 0, "tidak ada match")


func test_l_shape_intersect() -> void:
	# L: baris atas 111 + kolom kiri turun 1,1 → bentuk L (5 cell, share pojok).
	# grid:
	# 1 1 1
	# 1 2 3
	# 1 4 5
	var m := _find(["111", "123", "145"])
	assert_eq(m.size(), 1, "H+V berpotongan digabung jadi 1 grup")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.SHAPE_LT, "SHAPE_LT (L)")
	assert_eq(m[0]["cells"].size(), 5, "5 cell unik (3 + 3 - 1 share)")


func test_t_shape_intersect() -> void:
	# T: kolom tengah 3 + baris tengah 3 berpotongan.
	# 2 1 3
	# 1 1 1
	# 4 1 5
	var m := _find(["213", "111", "415"])
	assert_eq(m.size(), 1, "T digabung 1 grup")
	assert_eq(m[0]["kind"], MatchDetector.MatchKind.SHAPE_LT, "SHAPE_LT (T)")
	assert_eq(m[0]["cells"].size(), 5, "5 cell unik")


func test_two_separate_matches() -> void:
	# Dua match terpisah warna beda.
	# 1 1 1 . 2 2 2
	var m := _find(["111.222"])
	assert_eq(m.size(), 2, "2 match terpisah")


func test_non_playable_breaks_run() -> void:
	# '#' (non-playable) memutus run.
	var m := _find(["11#11"])
	assert_eq(m.size(), 0, "run terputus oleh non-playable → tidak ada match-3")


func test_has_any_match() -> void:
	assert_true(MatchDetector.has_any_match(BoardTestHelper.from_grid(["111", "234", "562"])), "ada match")
	assert_false(MatchDetector.has_any_match(BoardTestHelper.from_grid(["123", "231", "312"])), "tidak ada match")
