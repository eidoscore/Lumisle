class_name Board extends RefCounted
## Jantung logika match-3 — RefCounted (BUKAN Node), headless, deterministik.
## State: flat PackedInt32Array row-major (idx = y*width + x). Dok 04 §3.1, dok 14.
## RNG di-INJECT (bukan autoload) → boleh banyak board simultan (solver).
##
## T1.3: state + akses + setup. T1.5: init no-match. T1.6: gravity (helper).
## T1.7: resolve_swap + cascade. T1.8: validasi. T1.9: find_possible_moves + reshuffle.

const MAX_CASCADE := 64               # guard infinite cascade (dok 14 §1 STEP D)

var width: int = 0
var height: int = 0
var cells: PackedInt32Array = PackedInt32Array()          # warna+special per cell (TileCodes)
var playable_mask: PackedInt32Array = PackedInt32Array()  # 1=playable, 0=blocked
var obstacle_layer: PackedInt32Array = PackedInt32Array()  # encoded obstacle paralel (dok 14 §0.2)

var color_subset: PackedInt32Array = PackedInt32Array()   # warna aktif level ini
var _rng: GameRNG = null


# ---------------------------------------------------------------------------
# Indexing & akses dasar
# ---------------------------------------------------------------------------

func idx(x: int, y: int) -> int:
	return y * width + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func is_playable(x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	return playable_mask[idx(x, y)] == 1


func get_cell(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return TileCodes.EMPTY
	return cells[idx(x, y)]


func set_cell(x: int, y: int, value: int) -> void:
	if not in_bounds(x, y):
		return
	var i := idx(x, y)
	cells[i] = value


func get_color(x: int, y: int) -> int:
	return TileCodes.decode_color(get_cell(x, y))


func get_special(x: int, y: int) -> int:
	return TileCodes.decode_special(get_cell(x, y))


func get_obstacle(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return TileCodes.OBS_NONE
	return obstacle_layer[idx(x, y)]


## Apakah cell menahan jatuh (gravity)? Baca dari encoding obstacle (tanpa instantiate).
func cell_blocks_movement(x: int, y: int) -> bool:
	return TileCodes.encoded_blocks_movement(get_obstacle(x, y))


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Bangun papan dari parameter. RNG di-inject. Mengisi tile awal TANPA match (T1.5).
## level_def opsional (Fase 4); di Fase 1 dipakai param langsung.
func setup(p_width: int, p_height: int, p_color_subset: PackedInt32Array, rng: GameRNG,
		p_playable_mask: PackedInt32Array = PackedInt32Array(),
		p_obstacles: Array = []) -> void:
	width = p_width
	height = p_height
	color_subset = p_color_subset
	_rng = rng

	var n := width * height
	cells = PackedInt32Array()
	cells.resize(n)
	obstacle_layer = PackedInt32Array()
	obstacle_layer.resize(n)  # default 0 = OBS_NONE

	# playable_mask: default semua playable kalau tidak diberikan.
	if p_playable_mask.size() == n:
		playable_mask = p_playable_mask
	else:
		playable_mask = PackedInt32Array()
		playable_mask.resize(n)
		for i in range(n):
			playable_mask[i] = 1

	_apply_obstacles(p_obstacles)
	_fill_no_initial_match()


## Konversi Format A obstacle → obstacle_layer (dok 14 §0.2). V1: maks 1 obstacle/cell.
func _apply_obstacles(obstacles: Array) -> void:
	for entry in obstacles:
		# entry: {type:int, layer:int, positions:Array, hp:int}
		var otype: int = entry.get("type", TileCodes.OBS_NONE)
		var layer: int = entry.get("layer", 1)
		var hp: int = entry.get("hp", 1)
		var positions: Array = entry.get("positions", [])
		for pos in positions:
			var px := int(pos.x)
			var py := int(pos.y)
			if not in_bounds(px, py):
				continue
			var i := idx(px, py)
			# Maks 1 obstacle/cell: simpan yang layer lebih tinggi.
			var existing := obstacle_layer[i]
			if existing == TileCodes.OBS_NONE or layer > TileCodes.obstacle_layer_of(existing):
				obstacle_layer[i] = TileCodes.encode_obstacle(otype, hp, layer)


## Isi tile berseed, re-roll cell yang membentuk match awal sampai bersih (T1.5).
func _fill_no_initial_match() -> void:
	for y in range(height):
		for x in range(width):
			if not is_playable(x, y):
				set_cell(x, y, TileCodes.EMPTY)
				continue
			# Pilih warna yang tidak langsung membentuk match-3 ke kiri / atas.
			var color := _pick_safe_color(x, y)
			set_cell(x, y, TileCodes.encode(color))


## Pilih warna yang tidak membuat 3-segaris dgn 2 tetangga kiri / 2 tetangga atas.
func _pick_safe_color(x: int, y: int) -> int:
	var color := _rng.pick_packed(color_subset)
	for attempt in range(32):
		color = _rng.pick_packed(color_subset)
		var bad := false
		# Cek kiri: (x-1) & (x-2) sama warna.
		if x >= 2 and is_playable(x - 1, y) and is_playable(x - 2, y):
			if get_color(x - 1, y) == color and get_color(x - 2, y) == color:
				bad = true
		# Cek atas: (y-1) & (y-2) sama warna.
		if not bad and y >= 2 and is_playable(x, y - 1) and is_playable(x, y - 2):
			if get_color(x, y - 1) == color and get_color(x, y - 2) == color:
				bad = true
		if not bad:
			return color
	# Fallback aman: kalau subset kecil & banyak gagal, ambil warna terakhir yang dicoba.
	return color


# ---------------------------------------------------------------------------
# Hash (dok 14 §7) — untuk test determinisme & fixtures
# ---------------------------------------------------------------------------

func board_hash() -> int:
	# Hash deterministik dari cells + obstacle_layer.
	var h := hash(cells.to_byte_array())
	h = hash([h, obstacle_layer.to_byte_array()])
	return h


# ---------------------------------------------------------------------------
# T1.7 — resolve_swap + cascade loop (dok 14 §1)
# T1.8 — error handling + validasi
# T1.9 — find_possible_moves + reshuffle
# ---------------------------------------------------------------------------

## Hook untuk special items (Fase 2). Di Fase 1 default null/no-op.
## Diisi oleh SpecialItems di Fase 2 TANPA mengubah loop ini (T1.7 DoD: modular).
## Signature direncanakan:
##   _special_create_fn(matches) -> Array  (special yang dibuat)
##   _special_trigger_fn(triggers) -> Dictionary (clear_mask tambahan + new_triggers)
var _special_create_fn: Callable = Callable()
var _special_trigger_fn: Callable = Callable()


## STEP A-F (dok 14 §1). Mengembalikan TurnReport (replay log).
func resolve_swap(x1: int, y1: int, x2: int, y2: int, rng: GameRNG) -> TurnReport:
	_rng = rng
	var report := TurnReport.new()
	report.initial_board_hash = board_hash()

	# STEP A — Validasi swap (bersebelahan ortogonal, playable).
	if not _is_valid_swap_positions(x1, y1, x2, y2):
		return TurnReport.rejected()
	report.is_valid_swap = true

	# Snapshot untuk rollback (T1.8) & swap-back (STEP C).
	var snapshot := cells.duplicate()

	# STEP B — Lakukan swap.
	_swap_cells(x1, y1, x2, y2)

	# STEP C — Apakah giliran valid? (Fase 1: hanya kriteria "menghasilkan match".)
	# (Special-swap & combo = Fase 2, lewat hook.)
	var has_match := MatchDetector.has_any_match(self)
	if not has_match:
		# Swap-back, rejected, tidak makan langkah (anti-frustrasi).
		cells = snapshot
		var r := TurnReport.rejected()
		r.is_valid_swap = true   # fisik valid, tapi tidak menghasilkan apa-apa
		return r

	report.is_accepted = true
	report.move_cost = 1
	# Catat event SWAP (untuk view animasi).
	report.add_step(MoveAction.make(
		MoveAction.Type.SWAP, [],
		{"from": Vector2i(x1, y1), "to": Vector2i(x2, y2), "valid": true}
	))

	# STEP D — Loop cascade.
	var cascade_index := 0
	while cascade_index < MAX_CASCADE:
		cascade_index += 1
		var matches := MatchDetector.find_all(self)
		if matches.is_empty():
			break
		_resolve_cascade_step(matches, cascade_index, report, rng)

	if cascade_index >= MAX_CASCADE:
		push_warning("Board.resolve_swap: MAX_CASCADE tercapai — kemungkinan bug")

	# STEP E — Dead-board & reshuffle (gratis).
	if find_possible_moves().is_empty():
		reshuffle(rng)
		report.add_step(MoveAction.make(MoveAction.Type.RESHUFFLE, [], {}))

	# T1.8 — Validasi akhir + rollback kalau corrupt.
	if not _validate_board_state():
		push_error("Board.resolve_swap: state invalid setelah resolusi — rollback")
		cells = snapshot
		return TurnReport.invalid("internal_error")

	report.final_board_hash = board_hash()
	return report


## Satu gelombang cascade: clear match → gravity → refill (dok 14 §1 STEP D.3).
## Fase 1: tanpa special (created/triggered = no-op via hook null).
func _resolve_cascade_step(matches: Array, cascade_index: int, report: TurnReport, rng: GameRNG) -> void:
	# D.1 — special yang dibuat dari matches (Fase 2 via hook; Fase 1 kosong).
	var created: Array = []
	if _special_create_fn.is_valid():
		created = _special_create_fn.call(matches)

	# Posisi anchor created (dikecualikan dari clear, dok 14 §3.5 poin 3).
	var created_positions := {}
	for c in created:
		created_positions[c["pos"]] = true

	# D.2 — clear_mask = union semua cell match (sekali, dok 14 §3.5 poin 1).
	var clear_set := {}
	var cleared_colors: Array[int] = []
	for m in matches:
		for cpos in m["cells"]:
			if created_positions.has(cpos):
				continue  # special baru kebal clear di step ini
			if not clear_set.has(cpos):
				clear_set[cpos] = true
				cleared_colors.append(get_color(int(cpos.x), int(cpos.y)))

	# D.3 — emit TileCleared + hapus fisik.
	var cleared_positions: Array[Vector2i] = []
	for cpos in clear_set:
		cleared_positions.append(cpos)
	if not cleared_positions.is_empty():
		report.add_step(MoveAction.make(
			MoveAction.Type.TILE_CLEARED, cleared_positions, {"colors": cleared_colors}
		))
		# Skor (dok 14 §6): base 20 per tile × faktor cascade (cascade_index+1).
		report.score_delta_x2 += cleared_positions.size() * 20 * (cascade_index + 1)
		for cpos in cleared_positions:
			set_cell(int(cpos.x), int(cpos.y), TileCodes.EMPTY)

	# Tempatkan special yang dibuat (Fase 2).
	for c in created:
		var cp: Vector2i = c["pos"]
		set_cell(int(cp.x), int(cp.y), TileCodes.encode(0, c["special_type"]))
		report.add_step(MoveAction.make(
			MoveAction.Type.SPECIAL_CREATED, [], {"special_type": c["special_type"], "pos": cp}
		))

	# (Obstacle damage & objective credit = Fase 4; hook nanti.)

	# Gravity → event TileFell.
	var fall_events := Gravity.apply_gravity(self)
	for e in fall_events:
		report.add_step(e)

	# Refill → event TileSpawned.
	var spawn_events := Gravity.apply_refill(self, rng)
	for e in spawn_events:
		report.add_step(e)


# ---------------------------------------------------------------------------
# Helper swap & validasi
# ---------------------------------------------------------------------------

func _is_valid_swap_positions(x1: int, y1: int, x2: int, y2: int) -> bool:
	if not is_playable(x1, y1) or not is_playable(x2, y2):
		return false
	# Bersebelahan ortogonal (jarak Manhattan = 1).
	var dx := absi(x1 - x2)
	var dy := absi(y1 - y2)
	if dx + dy != 1:
		return false
	# Tidak boleh swap cell yang kosong atau ber-blocker.
	if cell_blocks_movement(x1, y1) or cell_blocks_movement(x2, y2):
		return false
	return true


func _swap_cells(x1: int, y1: int, x2: int, y2: int) -> void:
	var tmp := get_cell(x1, y1)
	set_cell(x1, y1, get_cell(x2, y2))
	set_cell(x2, y2, tmp)


## T1.8 — Validasi state board. Tidak ada match tersisa (cascade selesai),
## tidak ada sel playable non-blocker yang kosong (gravity+refill benar).
func _validate_board_state() -> bool:
	if MatchDetector.has_any_match(self):
		return false
	for y in range(height):
		for x in range(width):
			if not is_playable(x, y):
				continue
			if cell_blocks_movement(x, y):
				continue
			if get_color(x, y) == TileCodes.EMPTY:
				return false
	return true


# ---------------------------------------------------------------------------
# T1.9 — find_possible_moves + reshuffle
# ---------------------------------------------------------------------------

## Daftar swap valid yang menghasilkan match. Untuk hint, solver, deteksi deadlock.
## Mengembalikan Array of {a:Vector2i, b:Vector2i}.
func find_possible_moves() -> Array:
	var moves: Array = []
	for y in range(height):
		for x in range(width):
			if not is_playable(x, y) or cell_blocks_movement(x, y):
				continue
			# Cek swap ke kanan & ke bawah (cukup, hindari duplikat).
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var nx: int = x + dir.x
				var ny: int = y + dir.y
				if not is_playable(nx, ny) or cell_blocks_movement(nx, ny):
					continue
				if _swap_creates_match(x, y, nx, ny):
					moves.append({"a": Vector2i(x, y), "b": Vector2i(nx, ny)})
	return moves


## Cek (tanpa mengubah state permanen) apakah swap (x1,y1)<->(x2,y2) menghasilkan match.
func _swap_creates_match(x1: int, y1: int, x2: int, y2: int) -> bool:
	_swap_cells(x1, y1, x2, y2)
	var has_match := MatchDetector.has_any_match(self)
	_swap_cells(x1, y1, x2, y2)  # kembalikan
	return has_match


## PUBLIK (untuk view): apakah swap ini akan diterima (valid posisi + menghasilkan
## match)? Tidak mengubah state. View pakai ini untuk memutuskan animasi slide
## (valid) vs bounce (invalid) SEBELUM resolve_swap memutasi board.
func swap_will_match(x1: int, y1: int, x2: int, y2: int) -> bool:
	if not _is_valid_swap_positions(x1, y1, x2, y2):
		return false
	return _swap_creates_match(x1, y1, x2, y2)


## Acak ulang posisi tile (berseed). Pastikan no match instan & ada >=1 move (dok 14 §1 STEP E).
## Reshuffle GRATIS (D16). Mengumpulkan warna existing lalu menyebar ulang.
func reshuffle(rng: GameRNG) -> void:
	# Kumpulkan semua warna tile yang ada (sel playable non-blocker non-empty).
	var colors: Array = []
	var slots: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if not is_playable(x, y) or cell_blocks_movement(x, y):
				continue
			var c := get_color(x, y)
			if c != TileCodes.EMPTY:
				colors.append(get_cell(x, y))  # simpan encoded (warna+special)
				slots.append(Vector2i(x, y))

	# Coba beberapa kali shuffle sampai dapat konfigurasi valid (no match, ada move).
	for attempt in range(64):
		var shuffled := colors.duplicate()
		rng.shuffle(shuffled)
		for i in range(slots.size()):
			set_cell(int(slots[i].x), int(slots[i].y), shuffled[i])
		if not MatchDetector.has_any_match(self) and not find_possible_moves().is_empty():
			return
	# Fallback: terima konfigurasi terakhir (jarang tercapai untuk board normal).
