class_name SpecialItems extends RefCounted
## Aturan special items (Fase 2). Acuan: dok 14 §2 (pembuatan), §3 (aktivasi & combo).
## Fungsi murni & static — dipakai Board via hook (_special_create_fn/_special_trigger_fn)
## dan solver memakai logika yang SAMA (determinisme).
##
## T2.1  : create_specials_from_matches (line-4→roket, L/T→bom, line-5→colorbomb)
## T2.1b : kotak 2×2 → propeller (dok 14 §2.4, ruleset v2)
## T2.2  : affected_cells (area-of-effect tiap special)
## T2.3  : combo table (special + special) + resolve_combo

# --- §2.1 + §2.4: match kind → special type ---------------------------------

## Tentukan special yang DIBUAT dari daftar matches (dok 14 §2.1, §2.4).
## Mengembalikan Array of { "pos": Vector2i, "special_type": int }.
## anchor_candidates: posisi tile yang digerakkan pemain (Array[Vector2i]) — bisa kosong.
static func create_specials_from_matches(matches: Array, anchor_candidates: Array) -> Array:
	var created: Array = []
	for m in matches:
		var stype := _special_for_kind(m["kind"], m.get("orientation", "none"))
		if stype == TileCodes.SPECIAL_NONE:
			continue
		var pos := _anchor_for_match(m, anchor_candidates)
		created.append({"pos": pos, "special_type": stype})
	return created


## Pemetaan kind → tipe special (dok 14 §2.1).
static func _special_for_kind(kind: int, orientation: String) -> int:
	match kind:
		MatchDetector.MatchKind.LINE_4:
			# Roket tegak lurus arah match (match horizontal → roket vertikal? )
			# dok 14 §2.1: "4 segaris (horizontal) → Roket horizontal".
			return TileCodes.SPECIAL_ROCKET_H if orientation == "h" else TileCodes.SPECIAL_ROCKET_V
		MatchDetector.MatchKind.LINE_5:
			return TileCodes.SPECIAL_COLORBOMB
		MatchDetector.MatchKind.SHAPE_LT:
			return TileCodes.SPECIAL_BOMB
		MatchDetector.MatchKind.SHAPE_SQUARE:
			return TileCodes.SPECIAL_PROPELLER
		_:
			return TileCodes.SPECIAL_NONE


## Anchor special (dok 14 §2.3): pakai posisi tile yang digerakkan pemain kalau ia
## bagian dari match; selain itu fallback deterministik.
static func _anchor_for_match(m: Dictionary, anchor_candidates: Array) -> Vector2i:
	var cells: Array = m["cells"]
	for cand in anchor_candidates:
		for c in cells:
			if c == cand:
				return cand
	# Fallback deterministik: kiri-atas (y terkecil, lalu x terkecil).
	var best: Vector2i = cells[0]
	for c in cells:
		if c.y < best.y or (c.y == best.y and c.x < best.x):
			best = c
	return best


# --- §3.1: area-of-effect tiap special --------------------------------------

## Cell yang terdampak saat sebuah special di posisi `pos` (warna `color`) diaktifkan.
## color_target: untuk colorbomb = warna yang disasar (dari tile yang di-swap).
## Mengembalikan Array[Vector2i] (termasuk pos itu sendiri).
static func affected_cells(board: Board, pos: Vector2i, special_type: int, color_target: int = -1) -> Array:
	var out: Array[Vector2i] = []
	match special_type:
		TileCodes.SPECIAL_ROCKET_H:
			for x in range(board.width):
				if board.is_playable(x, pos.y):
					out.append(Vector2i(x, pos.y))
		TileCodes.SPECIAL_ROCKET_V:
			for y in range(board.height):
				if board.is_playable(pos.x, y):
					out.append(Vector2i(pos.x, y))
		TileCodes.SPECIAL_BOMB:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var p := Vector2i(pos.x + dx, pos.y + dy)
					if board.is_playable(p.x, p.y):
						out.append(p)
		TileCodes.SPECIAL_COLORBOMB:
			# Semua tile berwarna = color_target. Kalau -1, fallback warna terbanyak.
			var target := color_target
			if target <= 0:
				target = _dominant_color(board)
			for y in range(board.height):
				for x in range(board.width):
					if board.is_playable(x, y) and board.get_color(x, y) == target:
						out.append(Vector2i(x, y))
			out.append(pos)
		TileCodes.SPECIAL_PROPELLER:
			# Propeller: target 1 cell (objektif terdekat / fallback deterministik) + 4 tetangga.
			var tgt := _propeller_target(board, pos)
			out.append(tgt)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = tgt + d
				if board.is_playable(p.x, p.y):
					out.append(p)
			out.append(pos)
		_:
			out.append(pos)
	return out


## Target propeller (dok 14 §3.1): deterministik. V1 sederhana: cell playable
## non-empty paling "jauh" secara index dari pos (biar terasa terbang), tie-break index.
## (Objektif-aware = tuning lanjutan; tetap deterministik.)
static func _propeller_target(board: Board, pos: Vector2i) -> Vector2i:
	# Pilih cell berwarna pertama (index flat) yang BUKAN pos. Deterministik & sederhana.
	for y in range(board.height):
		for x in range(board.width):
			var p := Vector2i(x, y)
			if p == pos:
				continue
			if board.is_playable(x, y) and board.get_color(x, y) != TileCodes.EMPTY:
				return p
	return pos


static func _dominant_color(board: Board) -> int:
	var counts := {}
	for y in range(board.height):
		for x in range(board.width):
			if not board.is_playable(x, y):
				continue
			var c := board.get_color(x, y)
			if c == TileCodes.EMPTY:
				continue
			counts[c] = counts.get(c, 0) + 1
	var best := 0
	var best_count := -1
	for c in counts:
		if counts[c] > best_count or (counts[c] == best_count and c < best):
			best = c
			best_count = counts[c]
	return best


# --- §3.2: combo special + special ------------------------------------------

enum ComboEffect { CROSS, THICK_CROSS, BIG_AREA, CONVERT_TO_ROCKET, CONVERT_TO_BOMB, CLEAR_ALL }

## Tabel combo (dok 14 §3.2). Key = (min<<4)|max dari dua special_type (komutatif).
## Dibangun sekali. Berisi {effect:int, radius:int}.
static func combo_table() -> Dictionary:
	var t := {}
	var R_H := TileCodes.SPECIAL_ROCKET_H
	var R_V := TileCodes.SPECIAL_ROCKET_V
	var B := TileCodes.SPECIAL_BOMB
	var CB := TileCodes.SPECIAL_COLORBOMB
	# Roket + Roket (semua kombinasi H/V) → palang.
	for a in [R_H, R_V]:
		for b in [R_H, R_V]:
			t[_combo_key(a, b)] = {"effect": ComboEffect.CROSS, "radius": 0}
	# Roket + Bom → palang tebal.
	for r in [R_H, R_V]:
		t[_combo_key(r, B)] = {"effect": ComboEffect.THICK_CROSS, "radius": 1}
	# Bom + Bom → area besar 5×5.
	t[_combo_key(B, B)] = {"effect": ComboEffect.BIG_AREA, "radius": 2}
	# Color Bomb + Roket → konversi warna jadi roket.
	for r in [R_H, R_V]:
		t[_combo_key(CB, r)] = {"effect": ComboEffect.CONVERT_TO_ROCKET, "radius": 0}
	# Color Bomb + Bom → konversi warna jadi bom.
	t[_combo_key(CB, B)] = {"effect": ComboEffect.CONVERT_TO_BOMB, "radius": 0}
	# Color Bomb + Color Bomb → bersihkan papan.
	t[_combo_key(CB, CB)] = {"effect": ComboEffect.CLEAR_ALL, "radius": 0}
	return t


static func _combo_key(a: int, b: int) -> int:
	var lo: int = min(a, b)
	var hi: int = max(a, b)
	return (lo << 4) | hi


## Apakah dua special (di-swap) membentuk combo yang dikenal?
static func is_combo(special_a: int, special_b: int) -> bool:
	if special_a == TileCodes.SPECIAL_NONE or special_b == TileCodes.SPECIAL_NONE:
		return false
	return combo_table().has(_combo_key(special_a, special_b))


## Cell terdampak combo dua special di posisi pivot (dok 14 §3.2).
## pivot = posisi tile kedua (tempat combo terjadi). Untuk konversi colorbomb,
## color_other = warna tile non-colorbomb (atau dominant).
static func combo_affected_cells(board: Board, pivot: Vector2i, special_a: int, special_b: int) -> Array:
	var out: Array[Vector2i] = []
	var key := _combo_key(special_a, special_b)
	var def: Dictionary = combo_table().get(key, {})
	if def.is_empty():
		return out
	match def["effect"]:
		ComboEffect.CROSS:
			out += affected_cells(board, pivot, TileCodes.SPECIAL_ROCKET_H)
			out += affected_cells(board, pivot, TileCodes.SPECIAL_ROCKET_V)
		ComboEffect.THICK_CROSS:
			for off in range(-1, 2):
				out += affected_cells(board, Vector2i(pivot.x, clampi(pivot.y + off, 0, board.height - 1)), TileCodes.SPECIAL_ROCKET_H)
				out += affected_cells(board, Vector2i(clampi(pivot.x + off, 0, board.width - 1), pivot.y), TileCodes.SPECIAL_ROCKET_V)
		ComboEffect.BIG_AREA:
			var r: int = def["radius"]
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var p := Vector2i(pivot.x + dx, pivot.y + dy)
					if board.is_playable(p.x, p.y):
						out.append(p)
		ComboEffect.CONVERT_TO_ROCKET, ComboEffect.CONVERT_TO_BOMB, ComboEffect.CLEAR_ALL:
			# Untuk efek besar (konversi/clear-all): kembalikan semua cell playable.
			# (Detail konversi per-tile jadi roket/bom = tuning T2.x; v1 = clear semua warna target / papan.)
			if def["effect"] == ComboEffect.CLEAR_ALL:
				for y in range(board.height):
					for x in range(board.width):
						if board.is_playable(x, y):
							out.append(Vector2i(x, y))
			else:
				# CONVERT_*: target warna = warna paling banyak (deterministik), lalu seluruh cell warna itu.
				var target := _dominant_color(board)
				for y in range(board.height):
					for x in range(board.width):
						if board.is_playable(x, y) and board.get_color(x, y) == target:
							out.append(Vector2i(x, y))
				out.append(pivot)
	return out
