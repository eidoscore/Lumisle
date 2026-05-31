class_name MatchDetector extends RefCounted
## Deteksi SEMUA match simultan dari snapshot (dok 14 §0, §2). Fungsi murni & static.
## Output: daftar grup match dgn klasifikasi tipe (untuk pembuatan special, dok 14 §2.1).
## Tidak memodifikasi board.

# Klasifikasi bentuk match (dok 14 §2.1-§2.2).
enum MatchKind {
	LINE_3,      # 3 segaris → tidak ada special
	LINE_4,      # 4 segaris → roket (orientasi sesuai arah)
	LINE_5,      # 5 segaris lurus → color bomb
	SHAPE_LT,    # L/T (dua garis berpotongan) → bom
	SHAPE_SQUARE, # kotak 2×2 sewarna (murni, bukan bagian garis) → propeller (dok 14 §2.4)
}


## Cari semua match. Mengembalikan Array of Dictionary:
##   { "cells": Array[Vector2i], "kind": MatchKind, "orientation": "h"/"v"/"none", "color": int }
## Match yang berpotongan (H+V share cell) digabung jadi satu grup SHAPE_LT (dok 14 §2.1).
## Kotak 2×2 sewarna yang TIDAK beririsan garis ≥3 → grup SHAPE_SQUARE (dok 14 §2.4).
static func find_all(board: Board) -> Array:
	var runs := _find_runs(board)        # semua run horizontal & vertikal >=3
	var groups := _merge_intersecting(runs) if not runs.is_empty() else []
	var result: Array = []
	# Kumpulan cell yang sudah masuk grup garis (untuk prioritas garis > square §2.2).
	var line_cells := {}
	for g in groups:
		var classified := _classify(g)
		result.append(classified)
		for c in classified["cells"]:
			line_cells[c] = true
	# Deteksi kotak 2×2 yang tak beririsan garis (dok 14 §2.4).
	for sq in _find_squares(board, line_cells):
		result.append(sq)
	return result


## Cari kotak 2×2 sewarna yang TIDAK beririsan cell garis (line_cells).
## Anti-overlap: kotak yang sudah "diklaim" cell-nya oleh kotak lebih kiri-atas di-skip.
static func _find_squares(board: Board, line_cells: Dictionary) -> Array:
	var squares: Array = []
	var claimed := {}   # cell yang sudah jadi bagian kotak 2×2 sebelumnya
	for y in range(board.height - 1):
		for x in range(board.width - 1):
			var c00 := Vector2i(x, y)
			var c10 := Vector2i(x + 1, y)
			var c01 := Vector2i(x, y + 1)
			var c11 := Vector2i(x + 1, y + 1)
			# Skip kalau ada cell yang sudah masuk garis atau sudah diklaim kotak lain.
			if line_cells.has(c00) or line_cells.has(c10) or line_cells.has(c01) or line_cells.has(c11):
				continue
			if claimed.has(c00) or claimed.has(c10) or claimed.has(c01) or claimed.has(c11):
				continue
			if not (board.is_playable(x, y) and board.is_playable(x + 1, y) \
					and board.is_playable(x, y + 1) and board.is_playable(x + 1, y + 1)):
				continue
			var col := board.get_color(x, y)
			if col == TileCodes.EMPTY:
				continue
			if board.get_color(x + 1, y) != col or board.get_color(x, y + 1) != col \
					or board.get_color(x + 1, y + 1) != col:
				continue
			# Kotak 2×2 valid (kiri-atas menang, §2.4).
			var cells_arr: Array[Vector2i] = [c00, c10, c01, c11]
			squares.append({"cells": cells_arr, "kind": MatchKind.SHAPE_SQUARE, "orientation": "none", "color": col})
			claimed[c00] = true
			claimed[c10] = true
			claimed[c01] = true
			claimed[c11] = true
	return squares


## Cari semua "run" (deret >=3 sewarna) horizontal dan vertikal.
## Tiap run: { "cells": Array[Vector2i], "orientation": "h"/"v", "color": int }
static func _find_runs(board: Board) -> Array:
	var runs: Array = []
	# Horizontal
	for y in range(board.height):
		var x := 0
		while x < board.width:
			if not board.is_playable(x, y):
				x += 1
				continue
			var color := board.get_color(x, y)
			if color == TileCodes.EMPTY:
				x += 1
				continue
			var run_len := 1
			while x + run_len < board.width and board.is_playable(x + run_len, y) \
					and board.get_color(x + run_len, y) == color:
				run_len += 1
			if run_len >= 3:
				var rcells: Array[Vector2i] = []
				for k in range(run_len):
					rcells.append(Vector2i(x + k, y))
				runs.append({"cells": rcells, "orientation": "h", "color": color})
			x += run_len
	# Vertikal
	for x in range(board.width):
		var y := 0
		while y < board.height:
			if not board.is_playable(x, y):
				y += 1
				continue
			var color := board.get_color(x, y)
			if color == TileCodes.EMPTY:
				y += 1
				continue
			var run_len := 1
			while y + run_len < board.height and board.is_playable(x, y + run_len) \
					and board.get_color(x, y + run_len) == color:
				run_len += 1
			if run_len >= 3:
				var rcells: Array[Vector2i] = []
				for k in range(run_len):
					rcells.append(Vector2i(x, y + k))
				runs.append({"cells": rcells, "orientation": "v", "color": color})
			y += run_len
	return runs


## Gabung run yang berbagi minimal 1 cell (H+V berpotongan → satu grup L/T).
## Union-find sederhana berbasis cell.
static func _merge_intersecting(runs: Array) -> Array:
	var n := runs.size()
	var parent: Array[int] = []
	for i in range(n):
		parent.append(i)

	var find := func(a: int) -> int:
		while parent[a] != a:
			parent[a] = parent[parent[a]]
			a = parent[a]
		return a

	# Bandingkan tiap pasang run; kalau berbagi cell, union.
	for i in range(n):
		for j in range(i + 1, n):
			if runs[i]["color"] != runs[j]["color"]:
				continue
			if _runs_share_cell(runs[i]["cells"], runs[j]["cells"]):
				var ri: int = find.call(i)
				var rj: int = find.call(j)
				if ri != rj:
					parent[rj] = ri

	# Kumpulkan grup.
	var groups_map := {}
	for i in range(n):
		var root: int = find.call(i)
		if not groups_map.has(root):
			groups_map[root] = []
		groups_map[root].append(runs[i])

	var groups: Array = []
	for root in groups_map:
		groups.append(groups_map[root])
	return groups


static func _runs_share_cell(a: Array, b: Array) -> bool:
	var set_a := {}
	for c in a:
		set_a[c] = true
	for c in b:
		if set_a.has(c):
			return true
	return false


## Klasifikasi satu grup (kumpulan run yang sudah di-merge) → tipe match + cells gabungan.
static func _classify(group: Array) -> Dictionary:
	# Gabung semua cell unik dari run dalam grup.
	var cell_set := {}
	var color: int = group[0]["color"]
	var has_h := false
	var has_v := false
	var max_h_len := 0
	var max_v_len := 0
	for run in group:
		if run["orientation"] == "h":
			has_h = true
			max_h_len = max(max_h_len, run["cells"].size())
		else:
			has_v = true
			max_v_len = max(max_v_len, run["cells"].size())
		for c in run["cells"]:
			cell_set[c] = true

	var cells_arr: Array[Vector2i] = []
	for c in cell_set:
		cells_arr.append(c)

	var orientation := "none"
	var kind: int
	if has_h and has_v:
		# Dua garis berpotongan → L/T → bom (dok 14 §2.1).
		kind = MatchKind.SHAPE_LT
	else:
		orientation = "h" if has_h else "v"
		var line_len: int = max_h_len if has_h else max_v_len
		if line_len >= 5:
			kind = MatchKind.LINE_5     # color bomb
		elif line_len == 4:
			kind = MatchKind.LINE_4     # roket
		else:
			kind = MatchKind.LINE_3     # no special
	return {"cells": cells_arr, "kind": kind, "orientation": orientation, "color": color}


## Helper: apakah ada match sama sekali (untuk init no-match & validasi).
## Termasuk kotak 2×2 (dok 14 §2.4) — penting agar swap pembentuk 2×2 murni
## dianggap valid (swap_will_match) & init board bebas dari 2×2 juga.
static func has_any_match(board: Board) -> bool:
	if not _find_runs(board).is_empty():
		return true
	return not _find_squares(board, {}).is_empty()
