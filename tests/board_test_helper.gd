class_name BoardTestHelper extends RefCounted
## Helper untuk membangun Board dari grid warna literal (test mudah dibaca).
## Dipakai test match_detector, gravity, cascade, fixtures.


## Buat board dari array baris string. Tiap char = warna ('1'-'6'), '.' = empty.
## Contoh: ["111", "234", "...."] (baris atas dulu).
## CATATAN: ini bypass _fill_no_initial_match — sengaja, untuk setup state spesifik.
static func from_grid(rows: Array) -> Board:
	var b := Board.new()
	b.height = rows.size()
	b.width = String(rows[0]).length()
	var n := b.width * b.height
	b.cells = PackedInt32Array()
	b.cells.resize(n)
	b.playable_mask = PackedInt32Array()
	b.playable_mask.resize(n)
	b.obstacle_layer = PackedInt32Array()
	b.obstacle_layer.resize(n)
	b.color_subset = PackedInt32Array([1, 2, 3, 4, 5, 6])
	for y in range(b.height):
		var row := String(rows[y])
		for x in range(b.width):
			var ch := row[x]
			var i := b.idx(x, y)
			if ch == ".":
				b.cells[i] = TileCodes.EMPTY
				b.playable_mask[i] = 1
			elif ch == "#":
				# Non-playable
				b.cells[i] = TileCodes.EMPTY
				b.playable_mask[i] = 0
			else:
				b.cells[i] = TileCodes.encode(int(ch))
				b.playable_mask[i] = 1
	return b


## Render board jadi array string (untuk assert/debug). Warna saja.
static func to_grid(b: Board) -> Array:
	var rows: Array = []
	for y in range(b.height):
		var s := ""
		for x in range(b.width):
			if not b.is_playable(x, y):
				s += "#"
			else:
				var c := b.get_color(x, y)
				s += "." if c == TileCodes.EMPTY else str(c)
		rows.append(s)
	return rows
