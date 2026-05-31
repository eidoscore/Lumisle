class_name Gravity extends RefCounted
## Gravity + refill sebagai HELPER STATIC (dok 04 §3.2b, dok 14 §4).
## Helper memodifikasi cells board & menghasilkan Array[MoveAction]; board yang memanggil.
## Urutan kolom WAJIB kiri→kanan; RNG refill urut sama (determinisme, dok 14 §4).
## Blocker (obstacle blocks_movement) menahan jatuh; baca dari obstacle_layer (no instantiate).


## Terapkan gravity ke board (mutasi cells). Kembalikan event TileFell.
## Per kolom kiri→kanan, dari bawah ke atas; blocker memisah "segmen" kolom.
static func apply_gravity(board: Board) -> Array:
	var events: Array = []
	for x in range(board.width):
		_apply_gravity_column(board, x, events)
	return events


static func _apply_gravity_column(board: Board, x: int, events: Array) -> void:
	# write_row = baris terendah yang siap diisi (mulai dari paling bawah).
	var write_row := board.height - 1
	for y in range(board.height - 1, -1, -1):
		if not board.is_playable(x, y):
			continue
		# Blocker: tile tidak bisa lewat. Reset write_row ke atas blocker.
		if board.cell_blocks_movement(x, y):
			write_row = y - 1
			continue
		var cell := board.get_cell(x, y)
		if TileCodes.decode_color(cell) != TileCodes.EMPTY:
			# Ada tile di (x,y). Pindah ke write_row kalau berbeda.
			if write_row != y:
				board.set_cell(x, write_row, cell)
				board.set_cell(x, y, TileCodes.EMPTY)
				events.append(MoveAction.make(
					MoveAction.Type.TILE_FELL, [],
					{"from": Vector2i(x, y), "to": Vector2i(x, write_row)}
				))
			write_row -= 1
		# kalau EMPTY, write_row tetap (akan diisi oleh tile di atasnya / refill)


## Isi sel kosong dari atas dengan warna acak (color_subset). Kembalikan TileSpawned.
## Urutan kolom kiri→kanan, lalu atas→bawah dalam kolom (dok 14 §4.2) — RNG urut.
static func apply_refill(board: Board, rng: GameRNG) -> Array:
	var events: Array = []
	for x in range(board.width):
		for y in range(board.height):
			if not board.is_playable(x, y):
				continue
			# Blocker tidak diisi tile baru (itu obstacle, bukan slot tile).
			if board.cell_blocks_movement(x, y):
				continue
			if TileCodes.decode_color(board.get_cell(x, y)) == TileCodes.EMPTY:
				var color := rng.pick_packed(board.color_subset)
				board.set_cell(x, y, TileCodes.encode(color))
				events.append(MoveAction.make(
					MoveAction.Type.TILE_SPAWNED, [],
					{"pos": Vector2i(x, y), "color": color, "from_row": y}
				))
	return events
