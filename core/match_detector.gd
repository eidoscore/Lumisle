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
}


## Cari semua match. Mengembalikan Array of Dictionary:
##   { "cells": Array[Vector2i], "kind": MatchKind, "orientation": "h"/"v"/"none", "color": int }
## Match yang berpotongan (H+V share cell) digabung jadi satu grup SHAPE_LT (dok 14 §2.1).
static func find_all(board: Board) -> Array:
	var runs := _find_runs(board)        # semua run horizontal & vertikal >=3
	if runs.is_empty():
		return []
	var groups := _merge_intersecting(runs)   # gabung run yang berbagi cell
	var result: Array = []
	for g in groups:
		result.append(_classify(g))
	return result


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
static func has_any_match(board: Board) -> bool:
	return not _find_runs(board).is_empty()
