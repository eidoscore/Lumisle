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
	# Hook special items (Fase 2) sudah default-aktif di deklarasi _special_create_fn.


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


## Pilih warna yang tidak membuat 3-segaris dgn 2 tetangga kiri / 2 tetangga atas,
## DAN tidak membentuk kotak 2×2 sewarna dengan tetangga kiri/atas/kiri-atas (dok 14 §2.4).
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
		# Cek kotak 2×2: cell (x-1,y),(x,y-1),(x-1,y-1) semuanya == color.
		if not bad and x >= 1 and y >= 1 \
				and is_playable(x - 1, y) and is_playable(x, y - 1) and is_playable(x - 1, y - 1):
			if get_color(x - 1, y) == color and get_color(x, y - 1) == color \
					and get_color(x - 1, y - 1) == color:
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


## Salinan dalam (deep) board untuk evaluasi move tanpa memutasi aslinya (T5.3 solver
## lookahead). RNG TIDAK ikut (caller inject saat resolve). State penuh disalin.
func clone() -> Board:
	var b := Board.new()
	b.width = width
	b.height = height
	b.cells = cells.duplicate()
	b.playable_mask = playable_mask.duplicate()
	b.obstacle_layer = obstacle_layer.duplicate()
	b.color_subset = color_subset.duplicate()
	return b


# ---------------------------------------------------------------------------
# T1.7 — resolve_swap + cascade loop (dok 14 §1)
# T1.8 — error handling + validasi
# T1.9 — find_possible_moves + reshuffle
# ---------------------------------------------------------------------------

## Hook untuk special items (Fase 2). Default = SpecialItems (selalu aktif sejak
## deklarasi, agar board yang dibangun tanpa setup() — mis. test via from_grid —
## tetap membuat special). Bisa di-override (mis. solver/test khusus).
var _special_create_fn: Callable = Callable(SpecialItems, "create_specials_from_matches")
var _special_trigger_fn: Callable = Callable()

## Antrian special yang harus diaktifkan (FIFO, dok 14 §3.4). Diisi saat swap-special
## atau saat special kena clear/efek special lain (chain reaction T2.4).
var _trigger_queue: Array = []
## Cell ekstra yang harus di-clear pada step cascade berikutnya (mis. hasil combo).
var _pending_clear: Array = []
## Anchor kandidat untuk special yang dibuat = 2 cell yang baru di-swap (dok 14 §2.3).
var _swap_anchors: Array = []
## Warna target untuk color bomb yang di-trigger (dari tile pasangan swap).
var _colorbomb_target := -1


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

	# Special yang ada di kedua cell SEBELUM swap (untuk deteksi special-swap & combo).
	var sp1 := get_special(x1, y1)
	var sp2 := get_special(x2, y2)
	var col1 := get_color(x1, y1)
	var col2 := get_color(x2, y2)

	# STEP B — Lakukan swap.
	_swap_cells(x1, y1, x2, y2)

	# Reset state per-giliran (anchor untuk special baru, queue, target colorbomb).
	_swap_anchors = [Vector2i(x1, y1), Vector2i(x2, y2)]
	_trigger_queue = []
	_pending_clear = []
	_colorbomb_target = -1

	# STEP C — Apakah giliran valid? (dok 14 §C: match ATAU special-swap ATAU combo.)
	var has_match := MatchDetector.has_any_match(self)
	var is_combo := SpecialItems.is_combo(sp1, sp2)
	# Special-swap tunggal: salah satu cell special & yang lain tile biasa.
	var single_special := false
	var single_special_pos := Vector2i(-1, -1)
	var single_special_type := TileCodes.SPECIAL_NONE
	if not is_combo:
		if sp1 != TileCodes.SPECIAL_NONE and sp2 == TileCodes.SPECIAL_NONE:
			single_special = true
			single_special_pos = Vector2i(x2, y2)   # setelah swap, special pindah ke (x2,y2)
			single_special_type = sp1
			_colorbomb_target = col2   # warna pasangan (untuk colorbomb)
		elif sp2 != TileCodes.SPECIAL_NONE and sp1 == TileCodes.SPECIAL_NONE:
			single_special = true
			single_special_pos = Vector2i(x1, y1)
			single_special_type = sp2
			_colorbomb_target = col1

	if not has_match and not is_combo and not single_special:
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

	# Seed trigger queue dari swap-special / combo (dok 14 §C catatan: bypass match).
	if is_combo:
		# Combo special+special di posisi (x2,y2) (pivot = tile kedua).
		report.add_step(MoveAction.make(
			MoveAction.Type.COMBO_TRIGGERED, [],
			{"special_a": sp1, "special_b": sp2, "pos": Vector2i(x2, y2)}
		))
		_apply_combo(Vector2i(x2, y2), sp1, sp2, report)
	elif single_special:
		_trigger_queue.append({"pos": single_special_pos, "type": single_special_type})

	# STEP D — Loop cascade (match + trigger queue).
	var cascade_index := 0
	while cascade_index < MAX_CASCADE:
		cascade_index += 1
		var matches := MatchDetector.find_all(self)
		var has_work := not _trigger_queue.is_empty() or not _pending_clear.is_empty()
		if matches.is_empty() and not has_work:
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


## Gravity + refill + cascade setelah modifikasi eksternal (mis. booster hammer, T6.6).
## Dimulai dari board yang sudah ada cell kosong; tidak ada swap — langsung gravity dulu.
func run_gravity_refill_cascade(rng: GameRNG) -> TurnReport:
	_rng = rng
	_trigger_queue = []
	_pending_clear = []
	_swap_anchors  = []
	_colorbomb_target = -1
	var report := TurnReport.new()
	# 1. Gravity + bring-down
	var fall_events := Gravity.apply_gravity(self)
	for e in fall_events:
		report.add_step(e)
	_process_bring_down(report)
	# 2. Refill
	var spawn_events := Gravity.apply_refill(self, rng)
	for e in spawn_events:
		report.add_step(e)
	# 3. Cascade kalau ada match baru setelah refill
	var cascade_index := 0
	while cascade_index < MAX_CASCADE:
		cascade_index += 1
		var matches := MatchDetector.find_all(self)
		if matches.is_empty() and _trigger_queue.is_empty() and _pending_clear.is_empty():
			break
		_resolve_cascade_step(matches, cascade_index, report, rng)
	# 4. Dead-board reshuffle
	if find_possible_moves().is_empty():
		reshuffle(rng)
		report.add_step(MoveAction.make(MoveAction.Type.RESHUFFLE, [], {}))
	return report


## Satu gelombang cascade (dok 14 §1 STEP D, §3.5 resolusi simultan):
## 1) buat special dari matches (anchor = swap cell kalau bisa)
## 2) drain trigger_queue → kumpulkan area efek special + chain (special kena efek → queue)
## 3) clear_mask = union (match cells ∪ area efek special), KECUALI anchor special baru
## 4) emit TileCleared, tempatkan special baru, gravity, refill
func _resolve_cascade_step(matches: Array, cascade_index: int, report: TurnReport, rng: GameRNG) -> void:
	# D.1 — special yang dibuat dari matches (Fase 2 via hook).
	var created: Array = []
	if _special_create_fn.is_valid():
		created = _special_create_fn.call(matches, _swap_anchors)
	# Anchor swap hanya berlaku utk giliran pertama (cascade berikut = fallback).
	_swap_anchors = []

	var created_positions := {}
	for c in created:
		created_positions[c["pos"]] = true

	# D.2a — clear dari MATCH (union sel match, kecuali anchor special baru).
	var clear_set := {}
	for m in matches:
		for cpos in m["cells"]:
			if created_positions.has(cpos):
				continue  # special baru kebal clear di step ini (§3.5 poin 3)
			clear_set[cpos] = true

	# Pending clear dari combo (dok 14 §3.2): cell yang ditandai combo untuk dihapus.
	for cpos in _pending_clear:
		# Special yang kena combo → ikut chain (queue) sebelum di-clear.
		var psp := get_special(int(cpos.x), int(cpos.y))
		if psp != TileCodes.SPECIAL_NONE:
			_trigger_queue.append({"pos": cpos, "type": psp})
		else:
			clear_set[cpos] = true
	_pending_clear = []

	# D.2b — drain trigger_queue: aktifkan special, kumpulkan area efek + chain (§3.4).
	var triggered_events: Array = []   # untuk emit SPECIAL_TRIGGERED
	var processed := {}                # dedupe per step (§3.4)
	while not _trigger_queue.is_empty():
		var trig: Dictionary = _trigger_queue.pop_front()
		var tpos: Vector2i = trig["pos"]
		if processed.has(tpos):
			continue
		processed[tpos] = true
		var ttype: int = trig["type"]
		# Special yang di-trigger langsung di-set EMPTY (§3.5 poin 4) sebelum hitung area.
		set_cell(tpos.x, tpos.y, TileCodes.EMPTY)
		var affected: Array = SpecialItems.affected_cells(self, tpos, ttype, _colorbomb_target)
		triggered_events.append({"type": ttype, "pos": tpos, "affected": affected})
		for ap in affected:
			# Chain: kalau cell terdampak adalah special lain (belum diproses) → queue.
			var asp := get_special(ap.x, ap.y)
			if asp != TileCodes.SPECIAL_NONE and not processed.has(ap) and ap != tpos:
				_trigger_queue.append({"pos": ap, "type": asp})
			if not created_positions.has(ap):
				clear_set[ap] = true

	# Emit SPECIAL_TRIGGERED (sesudah area dihitung, sebelum clear fisik).
	for ev in triggered_events:
		var aff_arr: Array[Vector2i] = []
		for a in ev["affected"]:
			aff_arr.append(a)
		report.add_step(MoveAction.make(
			MoveAction.Type.SPECIAL_TRIGGERED, aff_arr,
			{"special_type": ev["type"], "pos": ev["pos"], "affected": aff_arr}
		))

	# D.3 — emit TileCleared + hapus fisik (union sekali, §3.5 poin 1).
	var cleared_positions: Array[Vector2i] = []
	var cleared_colors: Array[int] = []
	for cpos in clear_set:
		var cc := get_color(int(cpos.x), int(cpos.y))
		if cc == TileCodes.EMPTY:
			continue   # sudah kosong (mis. special yang sudah di-EMPTY-kan) — jangan double
		cleared_positions.append(cpos)
		cleared_colors.append(cc)
	if not cleared_positions.is_empty():
		report.add_step(MoveAction.make(
			MoveAction.Type.TILE_CLEARED, cleared_positions, {"colors": cleared_colors}
		))
		report.score_delta_x2 += cleared_positions.size() * 20 * (cascade_index + 1)
		for cpos in cleared_positions:
			set_cell(int(cpos.x), int(cpos.y), TileCodes.EMPTY)

	# T4.3a — Damage obstacle yang BERSEBELAHAN dgn cell yang baru di-clear (dok 14 §5).
	# Ice pecah dari match di sebelah; box/crate juga. Collectible (bring-down) TIDAK
	# di-damage dari match — ia turun & "delivered" (ditangani di gravity bring-down).
	_damage_adjacent_obstacles(cleared_positions, report)

	# Tempatkan special yang dibuat (warna ikut warna match agar colorbomb tahu target).
	for c in created:
		var cp: Vector2i = c["pos"]
		set_cell(int(cp.x), int(cp.y), TileCodes.encode(0, c["special_type"]))
		report.add_step(MoveAction.make(
			MoveAction.Type.SPECIAL_CREATED, [], {"special_type": c["special_type"], "pos": cp}
		))

	# Gravity → event TileFell.
	var fall_events := Gravity.apply_gravity(self)
	for e in fall_events:
		report.add_step(e)

	# T4.3c — Bring-down: collectible turun mengikuti gravity; kalau sampai baris
	# playable terbawah → delivered (hilang + event untuk objektif bring_down).
	_process_bring_down(report)

	# Refill → event TileSpawned.
	var spawn_events := Gravity.apply_refill(self, rng)
	for e in spawn_events:
		report.add_step(e)


## T4.3c — Proses bring-down collectible. Per kolom: collectible "jatuh" melewati
## sel kosong di bawahnya; kalau mencapai baris playable terbawah → delivered.
## Model: collectible disimpan di obstacle_layer; cell.color cell itu EMPTY (slot item).
func _process_bring_down(report: TurnReport) -> void:
	for x in range(width):
		# Cari baris playable terbawah di kolom ini (yang bukan blocker).
		var bottom := -1
		for y in range(height - 1, -1, -1):
			if is_playable(x, y) and not _cell_is_box(x, y):
				bottom = y
				break
		if bottom < 0:
			continue
		# Dari bawah ke atas: pindahkan collectible turun ke sel kosong di bawahnya.
		for y in range(height - 1, -1, -1):
			if not is_playable(x, y):
				continue
			var enc := get_obstacle(x, y)
			if TileCodes.obstacle_type(enc) != TileCodes.ObstacleType.COLLECTIBLE:
				continue
			# Cari posisi turun terjauh (sel di bawah yang kosong tile & tanpa obstacle).
			var ny := y
			while ny + 1 <= bottom and is_playable(x, ny + 1) \
					and TileCodes.is_empty_cell(get_cell(x, ny + 1)) \
					and get_obstacle(x, ny + 1) == TileCodes.OBS_NONE:
				ny += 1
			if ny != y:
				obstacle_layer[idx(x, ny)] = enc
				obstacle_layer[idx(x, y)] = TileCodes.OBS_NONE
				report.add_step(MoveAction.make(
					MoveAction.Type.TILE_FELL, [], {"from": Vector2i(x, y), "to": Vector2i(x, ny)}
				))
			# Kalau sudah di baris terbawah → delivered.
			if ny == bottom:
				obstacle_layer[idx(x, ny)] = TileCodes.OBS_NONE
				report.add_step(MoveAction.make(
					MoveAction.Type.OBSTACLE_DESTROYED, [Vector2i(x, ny)],
					{"pos": Vector2i(x, ny), "type": TileCodes.ObstacleType.COLLECTIBLE, "delivered": true}
				))


## Apakah cell punya obstacle box/crate (menahan gerakan)?
func _cell_is_box(x: int, y: int) -> bool:
	return TileCodes.obstacle_type(get_obstacle(x, y)) == TileCodes.ObstacleType.CRATE


## Terapkan combo special+special (dok 14 §3.2): tandai area efek untuk di-clear
## pada step cascade pertama (lewat _pending_clear, masuk alur biasa).
func _apply_combo(pivot: Vector2i, special_a: int, special_b: int, _report: TurnReport) -> void:
	_pending_clear = SpecialItems.combo_affected_cells(self, pivot, special_a, special_b)


## T4.3a — Damage obstacle yang bersebelahan (ortogonal) dgn cell yang baru di-clear.
## Ice & crate kena damage; collectible TIDAK (ia bring-down, bukan dipecah match).
## Emit OBSTACLE_DAMAGED / OBSTACLE_DESTROYED (dok 14 §5). Hp dari encoding obstacle_layer.
func _damage_adjacent_obstacles(cleared_positions: Array, report: TurnReport) -> void:
	if cleared_positions.is_empty():
		return
	# Kumpulkan cell obstacle yang tersentuh (dedupe), maksimal 1 damage per giliran-step.
	var hit := {}
	for cpos in cleared_positions:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var p: Vector2i = cpos + d
			if not in_bounds(p.x, p.y):
				continue
			var enc := get_obstacle(p.x, p.y)
			if enc == TileCodes.OBS_NONE:
				continue
			var otype := TileCodes.obstacle_type(enc)
			# Collectible tidak dipecah oleh match (di-handle bring-down via gravity).
			if otype == TileCodes.ObstacleType.COLLECTIBLE:
				continue
			hit[p] = true
	for p in hit:
		_apply_obstacle_damage(p, report)


## Kurangi hp obstacle di (p) sebanyak 1; emit event; hapus kalau hp habis.
func _apply_obstacle_damage(p: Vector2i, report: TurnReport) -> void:
	var enc := get_obstacle(p.x, p.y)
	var otype := TileCodes.obstacle_type(enc)
	var hp := TileCodes.obstacle_hp(enc)
	var layer := TileCodes.obstacle_layer_of(enc)
	hp -= 1
	if hp <= 0:
		obstacle_layer[idx(p.x, p.y)] = TileCodes.OBS_NONE
		report.add_step(MoveAction.make(
			MoveAction.Type.OBSTACLE_DESTROYED, [p], {"pos": p, "type": otype}
		))
	else:
		obstacle_layer[idx(p.x, p.y)] = TileCodes.encode_obstacle(otype, hp, layer)
		report.add_step(MoveAction.make(
			MoveAction.Type.OBSTACLE_DAMAGED, [p], {"pos": p, "type": otype, "hp_left": hp}
		))


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
			# Cell yang menampung collectible (bring-down) sengaja kosong warnanya — skip.
			if TileCodes.obstacle_type(get_obstacle(x, y)) == TileCodes.ObstacleType.COLLECTIBLE:
				continue
			if TileCodes.is_empty_cell(get_cell(x, y)):
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
## CEPAT: setelah swap, match hanya MUNGKIN melibatkan salah satu dari 2 cell yang
## ditukar → cukup cek lokal di kedua cell (MatchDetector.match_at), bukan pindai
## seluruh papan (krusial utk perf solver, dok 05 §6.1). Prasyarat: papan ter-resolve.
func _swap_creates_match(x1: int, y1: int, x2: int, y2: int) -> bool:
	_swap_cells(x1, y1, x2, y2)
	var has_match := MatchDetector.match_at(self, x1, y1) or MatchDetector.match_at(self, x2, y2)
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
			if not TileCodes.is_empty_cell(get_cell(x, y)):
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
