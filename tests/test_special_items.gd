extends GutTest
## T2.1-T2.3 + T2.1b — Special items: pembuatan dari match, area efek, combo, kotak 2×2.
## Acuan: dok 14 §2 (pembuatan), §2.4 (kotak 2×2 → propeller), §3 (aktivasi & combo).
## Logika special = fungsi murni/static → kebanyakan diuji langsung (deterministik).

const MK := MatchDetector.MatchKind


func _v(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)


# ---------------------------------------------------------------------------
# T2.1 — create_specials_from_matches: kind → special type + anchor
# ---------------------------------------------------------------------------

func test_line4_horizontal_makes_rocket_h() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(2, 0), _v(3, 0)],
		"kind": MK.LINE_4, "orientation": "h", "color": 1,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created.size(), 1, "line-4 → 1 special")
	assert_eq(created[0]["special_type"], TileCodes.SPECIAL_ROCKET_H, "horizontal → roket H")


func test_line4_vertical_makes_rocket_v() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(0, 1), _v(0, 2), _v(0, 3)],
		"kind": MK.LINE_4, "orientation": "v", "color": 2,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created[0]["special_type"], TileCodes.SPECIAL_ROCKET_V, "vertical → roket V")


func test_line5_makes_colorbomb() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(2, 0), _v(3, 0), _v(4, 0)],
		"kind": MK.LINE_5, "orientation": "h", "color": 3,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created[0]["special_type"], TileCodes.SPECIAL_COLORBOMB, "line-5 → color bomb")


func test_lt_shape_makes_bomb() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(2, 0), _v(0, 1), _v(0, 2)],
		"kind": MK.SHAPE_LT, "orientation": "none", "color": 4,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created[0]["special_type"], TileCodes.SPECIAL_BOMB, "L/T → bom")


func test_square_makes_propeller() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(0, 1), _v(1, 1)],
		"kind": MK.SHAPE_SQUARE, "orientation": "none", "color": 5,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created[0]["special_type"], TileCodes.SPECIAL_PROPELLER, "kotak 2×2 → propeller")


func test_line3_makes_no_special() -> void:
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(2, 0)],
		"kind": MK.LINE_3, "orientation": "h", "color": 1,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created.size(), 0, "line-3 → tidak ada special")


func test_anchor_uses_swap_position() -> void:
	# dok 14 §2.3: anchor = posisi tile yang digerakkan pemain kalau ia bagian match.
	var matches := [{
		"cells": [_v(0, 0), _v(1, 0), _v(2, 0), _v(3, 0)],
		"kind": MK.LINE_4, "orientation": "h", "color": 1,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [_v(2, 0)])
	assert_eq(created[0]["pos"], _v(2, 0), "anchor = posisi swap (2,0)")


func test_anchor_fallback_topleft() -> void:
	# Tanpa anchor candidate → fallback kiri-atas (y terkecil lalu x terkecil).
	var matches := [{
		"cells": [_v(3, 0), _v(1, 0), _v(2, 0), _v(0, 0)],
		"kind": MK.LINE_4, "orientation": "h", "color": 1,
	}]
	var created := SpecialItems.create_specials_from_matches(matches, [])
	assert_eq(created[0]["pos"], _v(0, 0), "fallback anchor = (0,0)")


# ---------------------------------------------------------------------------
# T2.1b — deteksi kotak 2×2 di MatchDetector (dok 14 §2.4)
# ---------------------------------------------------------------------------

func test_pure_square_detected() -> void:
	var b := BoardTestHelper.from_grid(["11", "11"])
	var matches := MatchDetector.find_all(b)
	assert_eq(matches.size(), 1, "1 grup match")
	assert_eq(matches[0]["kind"], MK.SHAPE_SQUARE, "kotak 2×2 murni → SHAPE_SQUARE")


func test_line_beats_square() -> void:
	# Baris 3 sewarna + kotak 2×2 yang beririsan → garis menang, square diabaikan (§2.2).
	var b := BoardTestHelper.from_grid(["111", "11."])
	var matches := MatchDetector.find_all(b)
	var kinds := []
	for m in matches:
		kinds.append(m["kind"])
	assert_true(kinds.has(MK.LINE_3), "ada garis-3")
	assert_false(kinds.has(MK.SHAPE_SQUARE), "kotak 2×2 yg beririsan garis TIDAK dihitung")


func test_square_does_not_overlap_double() -> void:
	# Blok 2×3 sewarna (tanpa garis ≥3? sebenarnya ada garis) → tidak boleh 2 propeller.
	# Pakai 2×2 + 1 ekstra yang TIDAK bikin garis: kolom 2 tinggi 2, plus 1 di kanan bawah.
	var b := BoardTestHelper.from_grid(["11.", "111", ".11"])
	var matches := MatchDetector.find_all(b)
	var squares := 0
	for m in matches:
		if m["kind"] == MK.SHAPE_SQUARE:
			squares += 1
	# Baris tengah "111" = garis-3 → cell-nya klaim; sisa kotak tak utuh → 0 square.
	assert_true(squares <= 1, "tidak boleh dobel propeller dari area sama")


func test_has_any_match_includes_square() -> void:
	# Penting: swap_will_match (lewat has_any_match) harus true utk 2×2 murni.
	var b := BoardTestHelper.from_grid(["11", "11"])
	assert_true(MatchDetector.has_any_match(b), "has_any_match true utk kotak 2×2")


func test_swap_forming_pure_square_is_valid() -> void:
	# Board: swap (1,1)<->(1,2) membentuk kotak 2×2 murni di (0,0).
	var b := BoardTestHelper.from_grid(["11", "12", "31"])
	assert_false(MatchDetector.has_any_match(b), "pra-swap: tidak ada match")
	assert_true(b.swap_will_match(1, 1, 1, 2), "swap pembentuk 2×2 murni = valid")


# ---------------------------------------------------------------------------
# T2.2 — area efek special (affected_cells)
# ---------------------------------------------------------------------------

func _grid5() -> Board:
	return BoardTestHelper.from_grid([
		"12345", "23451", "34512", "45123", "51234",
	])


func test_rocket_h_clears_row() -> void:
	var b := _grid5()
	var aff := SpecialItems.affected_cells(b, _v(2, 2), TileCodes.SPECIAL_ROCKET_H)
	assert_eq(aff.size(), 5, "roket H → seluruh baris (5)")
	for c in aff:
		assert_eq(c.y, 2, "semua di baris y=2")


func test_rocket_v_clears_column() -> void:
	var b := _grid5()
	var aff := SpecialItems.affected_cells(b, _v(2, 2), TileCodes.SPECIAL_ROCKET_V)
	assert_eq(aff.size(), 5, "roket V → seluruh kolom (5)")
	for c in aff:
		assert_eq(c.x, 2, "semua di kolom x=2")


func test_bomb_clears_3x3() -> void:
	var b := _grid5()
	var aff := SpecialItems.affected_cells(b, _v(2, 2), TileCodes.SPECIAL_BOMB)
	assert_eq(aff.size(), 9, "bom interior → 3×3 = 9")


func test_bomb_corner_clamped() -> void:
	var b := _grid5()
	var aff := SpecialItems.affected_cells(b, _v(0, 0), TileCodes.SPECIAL_BOMB)
	assert_eq(aff.size(), 4, "bom di pojok → 2×2 = 4")


func test_colorbomb_clears_target_color() -> void:
	var b := _grid5()
	# Warna 1 muncul 5x di latin-square shift.
	var aff := SpecialItems.affected_cells(b, _v(0, 0), TileCodes.SPECIAL_COLORBOMB, 1)
	# Dedupe (pos bisa ikut ter-append) lalu hitung cell warna 1.
	var uniq := {}
	for c in aff:
		uniq[c] = true
	var count_color1 := 0
	for c in uniq:
		if b.get_color(c.x, c.y) == 1:
			count_color1 += 1
	assert_eq(count_color1, 5, "color bomb target=1 → semua 5 tile warna 1")


# ---------------------------------------------------------------------------
# T2.3 — combo special + special
# ---------------------------------------------------------------------------

func test_is_combo_true_for_two_specials() -> void:
	assert_true(SpecialItems.is_combo(TileCodes.SPECIAL_ROCKET_H, TileCodes.SPECIAL_ROCKET_V),
		"roket+roket = combo")
	assert_true(SpecialItems.is_combo(TileCodes.SPECIAL_COLORBOMB, TileCodes.SPECIAL_COLORBOMB),
		"colorbomb+colorbomb = combo")


func test_is_combo_false_with_normal() -> void:
	assert_false(SpecialItems.is_combo(TileCodes.SPECIAL_ROCKET_H, TileCodes.SPECIAL_NONE),
		"special + normal = bukan combo")


func test_combo_is_commutative() -> void:
	var b := _grid5()
	var ab := SpecialItems.combo_affected_cells(b, _v(2, 2), TileCodes.SPECIAL_ROCKET_H, TileCodes.SPECIAL_BOMB)
	var ba := SpecialItems.combo_affected_cells(b, _v(2, 2), TileCodes.SPECIAL_BOMB, TileCodes.SPECIAL_ROCKET_H)
	assert_eq(ab.size(), ba.size(), "combo komutatif (urutan tak pengaruh)")


func test_combo_rocket_rocket_is_cross() -> void:
	var b := _grid5()
	var aff := SpecialItems.combo_affected_cells(b, _v(2, 2), TileCodes.SPECIAL_ROCKET_H, TileCodes.SPECIAL_ROCKET_V)
	# Palang = baris + kolom; cell unik = 5 + 5 - 1 (pusat dobel) tapi affected boleh dobel.
	var uniq := {}
	for c in aff:
		uniq[c] = true
	assert_eq(uniq.size(), 9, "palang 5+5-1 = 9 cell unik")


func test_combo_colorbomb_colorbomb_clears_all() -> void:
	var b := _grid5()
	var aff := SpecialItems.combo_affected_cells(b, _v(2, 2), TileCodes.SPECIAL_COLORBOMB, TileCodes.SPECIAL_COLORBOMB)
	var uniq := {}
	for c in aff:
		uniq[c] = true
	assert_eq(uniq.size(), 25, "CB+CB → bersihkan seluruh papan (25)")


# ---------------------------------------------------------------------------
# Integrasi — resolve_swap menghasilkan special (T2.1 end-to-end)
# ---------------------------------------------------------------------------

func test_resolve_swap_line4_creates_rocket() -> void:
	# Swap (2,0)<->(2,1): baris atas jadi 1 1 1 1 3 → line-4 → roket H.
	var b := BoardTestHelper.from_grid([
		"11213",
		"45142",
		"23451",
		"34512",
	])
	assert_false(MatchDetector.has_any_match(b), "pra-swap bersih")
	var report := b.resolve_swap(2, 0, 2, 1, GameRNG.new(777))
	assert_true(report.is_accepted, "swap line-4 diterima")
	var has_rocket := false
	for step in report.steps:
		if step.type == MoveAction.Type.SPECIAL_CREATED \
				and step.data.get("special_type", -1) == TileCodes.SPECIAL_ROCKET_H:
			has_rocket = true
	assert_true(has_rocket, "ada SPECIAL_CREATED roket H di report")
