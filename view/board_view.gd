extends Node2D
## BoardView (T1.11/T1.12) — render papan via MultiMeshInstance2D + replay TurnReport.
## Logika ada di Board (RefCounted); view hanya menampilkan & menganimasikan.
## Dok 04 §4, §14.2, §14.5. Tile placeholder = quad berwarna (art di T1.16/Fase 2).

signal level_won
signal level_lost
signal move_consumed

const TILE_SIZE := 110          # px per tile (placeholder)
const GAP := 6

# 6 warna placeholder (palet sementara; final di T1.16). Index 1-6.
const COLOR_PALETTE := [
	Color(0.20, 0.20, 0.24),   # 0 = empty (tak dipakai)
	Color(0.91, 0.30, 0.35),   # 1 merah
	Color(0.27, 0.62, 0.95),   # 2 biru
	Color(0.45, 0.80, 0.40),   # 3 hijau
	Color(0.98, 0.78, 0.28),   # 4 kuning
	Color(0.70, 0.45, 0.90),   # 5 ungu
	Color(0.95, 0.58, 0.30),   # 6 oranye
]

var board: Board = null
var _multimesh: MultiMeshInstance2D = null
var _mm: MultiMesh = null
var _input_enabled := true
var _selected := Vector2i(-1, -1)     # tile tersorot (mode tap-tap) / awal drag
var _press_grid := Vector2i(-1, -1)   # tile tempat jari/mouse mulai menekan
var _press_pos := Vector2.ZERO        # posisi pixel (lokal) saat mulai menekan
var _drag_swapped := false            # sudah memicu swap dalam satu gesture drag
var _move_rng: GameRNG = null
var _highlight: Line2D = null         # outline tile terpilih (feedback jelas)
var _animating := false               # true selagi animasi swap/bounce berjalan
var _use_touch := false               # latch: sekali ada sentuhan native, abaikan emulated mouse
var _idle_time := 0.0                 # detik sejak interaksi terakhir (untuk hint)
var _hint_a: Line2D = null            # outline hint tile 1
var _hint_b: Line2D = null            # outline hint tile 2
var _hint_shown := false
const HINT_DELAY := 0.5               # tampilkan hint cepat setelah board diam
const DRAG_THRESHOLD := 24.0          # px geser minimum untuk memicu swap berarah

# Callback opsional: dipanggil tiap TILE_CLEARED untuk credit objektif (di-set GameScreen).
var on_tiles_cleared: Callable = Callable()


func setup_board(p_board: Board, move_rng: GameRNG) -> void:
	board = p_board
	_move_rng = move_rng
	_build_multimesh()
	_build_overlay()
	_refresh_all()


func _build_multimesh() -> void:
	if _multimesh != null:
		_multimesh.queue_free()
	_multimesh = MultiMeshInstance2D.new()
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_colors = true
	# Mesh quad ukuran tile.
	var quad := QuadMesh.new()
	quad.size = Vector2(TILE_SIZE - GAP, TILE_SIZE - GAP)
	_mm.mesh = quad
	_mm.instance_count = board.width * board.height
	_multimesh.multimesh = _mm
	add_child(_multimesh)


## Overlay outline untuk tile terpilih — feedback yang jelas terbaca di placeholder.
func _build_overlay() -> void:
	if _highlight != null and is_instance_valid(_highlight):
		_highlight.queue_free()
	_highlight = Line2D.new()
	_highlight.width = 6.0
	_highlight.default_color = Color(1, 1, 1, 0.95)
	_highlight.closed = true
	_highlight.z_index = 10
	_highlight.visible = false
	var half := (TILE_SIZE - GAP) * 0.5
	_highlight.points = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	add_child(_highlight)
	# Dua outline hint (kuning) untuk menunjukkan satu langkah valid saat idle.
	_hint_a = _make_outline(Color(1, 0.9, 0.2, 0.95))
	_hint_b = _make_outline(Color(1, 0.9, 0.2, 0.95))


## Buat satu outline kotak (Line2D) seukuran tile, awalnya tak terlihat.
func _make_outline(col: Color) -> Line2D:
	var ln := Line2D.new()
	ln.width = 6.0
	ln.default_color = col
	ln.closed = true
	ln.z_index = 9
	ln.visible = false
	var half := (TILE_SIZE - GAP) * 0.5
	ln.points = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	add_child(ln)
	return ln


## Tampilkan/sembunyikan outline pada tile grid (atau sembunyikan kalau (-1,-1)).
func _update_highlight() -> void:
	if _highlight == null:
		return
	if _selected == Vector2i(-1, -1):
		_highlight.visible = false
	else:
		_highlight.visible = true
		_highlight.position = _tile_pos(_selected.x, _selected.y)


## Render semua tile dari state board (1 draw call via MultiMesh).
func _refresh_all() -> void:
	if board == null or _mm == null:
		return
	for y in range(board.height):
		for x in range(board.width):
			var i := board.idx(x, y)
			_mm.set_instance_transform_2d(i, Transform2D(0.0, _tile_pos(x, y)))
			_mm.set_instance_color(i, _color_for(x, y))


func _color_for(x: int, y: int) -> Color:
	if not board.is_playable(x, y):
		return Color(0, 0, 0, 0)   # transparan untuk non-playable
	if board.cell_blocks_movement(x, y):
		return Color(0.5, 0.4, 0.3)   # crate placeholder (coklat)
	var c := board.get_color(x, y)
	if c == TileCodes.EMPTY:
		return Color(0, 0, 0, 0.12)
	var col: Color = COLOR_PALETTE[c] if c < COLOR_PALETTE.size() else Color.WHITE
	# Tandai special dengan lebih terang (placeholder, detail visual Fase 2).
	if board.get_special(x, y) != TileCodes.SPECIAL_NONE:
		col = col.lightened(0.35)
	# Sorot tile terpilih (feedback tap-tap; placeholder sampai juice Fase 2).
	if _selected == Vector2i(x, y):
		col = col.lightened(0.5)
	return col


func _tile_pos(x: int, y: int) -> Vector2:
	return Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5)


# ---------------------------------------------------------------------------
# Idle hint (dibawa maju dari T2.7, versi minimal) — setelah idle beberapa detik,
# tunjukkan SATU langkah valid (2 tile) supaya pemain tahu swap mana yang "bisa".
# Ini krusial di Fase 1 karena tile masih placeholder (sulit baca match by eye).
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if board == null or _animating or not _input_enabled:
		return
	if _hint_shown:
		return
	_idle_time += delta
	if _idle_time >= HINT_DELAY:
		_show_hint()


func _show_hint() -> void:
	var moves := board.find_possible_moves()
	if moves.is_empty():
		return
	var mv = moves[0]
	var a: Vector2i = mv["a"]
	var b: Vector2i = mv["b"]
	_hint_a.position = _tile_pos(a.x, a.y)
	_hint_b.position = _tile_pos(b.x, b.y)
	_hint_a.visible = true
	_hint_b.visible = true
	_hint_shown = true
	# Kedip lembut untuk menarik perhatian.
	var t := create_tween().set_loops()
	t.tween_property(_hint_a, "modulate:a", 0.25, 0.5)
	t.parallel().tween_property(_hint_b, "modulate:a", 0.25, 0.5)
	t.tween_property(_hint_a, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(_hint_b, "modulate:a", 1.0, 0.5)
	_hint_a.set_meta("tween", t)


func _clear_hint() -> void:
	_idle_time = 0.0
	_hint_shown = false
	if _hint_a:
		if _hint_a.has_meta("tween"):
			var t = _hint_a.get_meta("tween")
			if t and t.is_valid():
				t.kill()
			_hint_a.remove_meta("tween")
		_hint_a.visible = false
		_hint_a.modulate.a = 1.0
	if _hint_b:
		_hint_b.visible = false
		_hint_b.modulate.a = 1.0


## Reset timer idle TANPA menyembunyikan hint (hint tetap terlihat selagi pemain
## mengatur langkah). Hint baru dihitung ulang hanya setelah swap selesai.
func _touch_activity() -> void:
	_idle_time = 0.0


# ---------------------------------------------------------------------------
# Input (T1.12) — DUA gestur didukung:
#   1) DRAG: tekan satu tile → geser ke tetangga → lepas = swap (gestur utama match-3).
#   2) TAP-TAP: tap satu tile (tersorot) → tap tetangga = swap.
#
# PENTING: jari ASLI di Android menghasilkan InputEventScreenTouch / ScreenDrag
# (BUKAN selalu mouse-emulasi dengan button_mask). Maka kita tangani event TOUCH
# native langsung, dan mouse hanya sebagai fallback desktop (editor). Latch _use_touch
# mencegah dobel-proses dari emulated mouse begitu sentuhan native terdeteksi.
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or _animating or board == null:
		return

	# --- Jalur TOUCH native (Android / layar sentuh) ---
	if event is InputEventScreenTouch:
		_use_touch = true
		_touch_activity()
		var lp: Vector2 = make_input_local(event).position
		if event.pressed:
			_on_press(lp)
		else:
			_on_release(lp)
		return
	elif event is InputEventScreenDrag:
		_use_touch = true
		_touch_activity()
		_on_drag(make_input_local(event).position)
		return

	# --- Jalur MOUSE (desktop/editor) — diabaikan kalau sudah ada sentuhan native ---
	if _use_touch:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_touch_activity()
		var lpm: Vector2 = make_input_local(event).position
		if event.pressed:
			_on_press(lpm)
		else:
			_on_release(lpm)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_touch_activity()
		_on_drag(make_input_local(event).position)


## Konversi posisi lokal → koordinat grid (atau (-1,-1) kalau di luar papan).
func _grid_at(local_pos: Vector2) -> Vector2i:
	if local_pos.x < 0 or local_pos.y < 0:
		return Vector2i(-1, -1)
	var gx := int(local_pos.x / TILE_SIZE)
	var gy := int(local_pos.y / TILE_SIZE)
	if gx < 0 or gy < 0 or gx >= board.width or gy >= board.height:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


func _on_press(local_pos: Vector2) -> void:
	var grid := _grid_at(local_pos)
	if grid == Vector2i(-1, -1) or not board.is_playable(grid.x, grid.y):
		_press_grid = Vector2i(-1, -1)
		return
	_press_grid = grid
	_press_pos = local_pos
	_drag_swapped = false
	# Mode tap-tap: kalau sudah ada tile tersorot & ini tetangganya → swap.
	if _selected != Vector2i(-1, -1) and _is_adjacent(_selected, grid):
		var first := _selected
		_set_selected(Vector2i(-1, -1))
		_press_grid = Vector2i(-1, -1)
		_do_swap(first.x, first.y, grid.x, grid.y)
	else:
		# Sorot tile ini sebagai kandidat (untuk tap-tap & sebagai awal drag/flick).
		_set_selected(grid)


## FLICK berarah: begitu jari bergeser melewati ambang dari titik tekan, tentukan
## arah dominan (atas/bawah/kiri/kanan) lalu swap dengan tetangga di arah itu.
## Ini jauh lebih toleran daripada "harus masuk sel tetangga" (dukung 4 arah merata).
func _on_drag(local_pos: Vector2) -> void:
	if _press_grid == Vector2i(-1, -1) or _drag_swapped:
		return
	var d := local_pos - _press_pos
	if d.length() < DRAG_THRESHOLD:
		return
	# Arah dominan: horizontal vs vertikal.
	var dir: Vector2i
	if absf(d.x) >= absf(d.y):
		dir = Vector2i(1, 0) if d.x > 0 else Vector2i(-1, 0)
	else:
		dir = Vector2i(0, 1) if d.y > 0 else Vector2i(0, -1)
	var target := _press_grid + dir
	if not board.is_playable(target.x, target.y):
		return
	var from := _press_grid
	_drag_swapped = true
	_press_grid = Vector2i(-1, -1)
	_set_selected(Vector2i(-1, -1))
	_do_swap(from.x, from.y, target.x, target.y)


func _on_release(local_pos: Vector2) -> void:
	# Lepas tanpa flick: kalau dilepas di tetangga tile awal, swap (drag pelan).
	if not _drag_swapped and _press_grid != Vector2i(-1, -1):
		var grid := _grid_at(local_pos)
		if grid != Vector2i(-1, -1) and _is_adjacent(_press_grid, grid) and board.is_playable(grid.x, grid.y):
			var from := _press_grid
			_set_selected(Vector2i(-1, -1))
			_do_swap(from.x, from.y, grid.x, grid.y)
	_press_grid = Vector2i(-1, -1)
	_drag_swapped = false


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


## Set tile tersorot & perbarui outline highlight.
func _set_selected(grid: Vector2i) -> void:
	if _selected == grid:
		return
	_selected = grid
	_update_highlight()
	_refresh_all()


func _do_swap(x1: int, y1: int, x2: int, y2: int) -> void:
	_set_selected(Vector2i(-1, -1))
	if _animating:
		return
	# Cek dulu hasilnya TANPA mengubah board (resolve_swap akan mengubah kalau valid).
	# Kita jalankan resolve_swap; kalau ditolak, mainkan bounce; kalau diterima, slide.
	var report := board.resolve_swap(x1, y1, x2, y2, _move_rng)
	if not report.is_accepted:
		# Swap invalid (mis. warna sama / tak bikin match) → animasi bounce supaya
		# jelas "ditolak", bukan terasa mati. Board tak berubah → hint lama masih valid.
		await _play_invalid_bounce(x1, y1, x2, y2)
		_idle_time = 0.0   # biar hint muncul lagi cepat
		return
	_input_enabled = false
	move_consumed.emit()   # giliran valid → kurangi langkah (GameScreen)
	# Board berubah → hint lama tak relevan, sembunyikan; dihitung ulang oleh _process.
	_clear_hint()
	# Animasi slide tukar posisi dulu (juice ringan Fase 1), lalu replay hasil.
	await _play_swap_slide(x1, y1, x2, y2)
	await _play_report(report)
	_input_enabled = true
	_idle_time = 0.0
	_clear_hint()   # reset timer hint setelah giliran selesai


## Animasi tukar dua tile (valid) — geser visual sebelum board di-refresh penuh.
func _play_swap_slide(x1: int, y1: int, x2: int, y2: int) -> void:
	_animating = true
	var i1 := board.idx(x1, y1)
	var i2 := board.idx(x2, y2)
	var p1 := _tile_pos(x1, y1)
	var p2 := _tile_pos(x2, y2)
	var t := create_tween().set_parallel(true)
	t.tween_method(func(p): _mm.set_instance_transform_2d(i1, Transform2D(0.0, p)), p1, p2, 0.12)
	t.tween_method(func(p): _mm.set_instance_transform_2d(i2, Transform2D(0.0, p)), p2, p1, 0.12)
	await t.finished
	_animating = false


## Animasi bounce untuk swap invalid — geser sebagian lalu balik, beri rasa "ditolak".
func _play_invalid_bounce(x1: int, y1: int, x2: int, y2: int) -> void:
	_animating = true
	var i1 := board.idx(x1, y1)
	var i2 := board.idx(x2, y2)
	var p1 := _tile_pos(x1, y1)
	var p2 := _tile_pos(x2, y2)
	var mid1 := p1.lerp(p2, 0.4)
	var mid2 := p2.lerp(p1, 0.4)
	var t := create_tween().set_parallel(true)
	t.tween_method(func(p): _mm.set_instance_transform_2d(i1, Transform2D(0.0, p)), p1, mid1, 0.09)
	t.tween_method(func(p): _mm.set_instance_transform_2d(i2, Transform2D(0.0, p)), p2, mid2, 0.09)
	await t.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_method(func(p): _mm.set_instance_transform_2d(i1, Transform2D(0.0, p)), mid1, p1, 0.09)
	t2.tween_method(func(p): _mm.set_instance_transform_2d(i2, Transform2D(0.0, p)), mid2, p2, 0.09)
	await t2.finished
	_animating = false
	_refresh_all()


## Replay TurnReport dengan animasi yang TERLIHAT (Fase 1 sederhana):
## - TILE_CLEARED: tampilkan "pop" (quad mengecil+memudar) di tiap sel yang hilang,
##   supaya jelas tile match LENYAP (bukan cuma ganti warna seketika).
## - lalu refresh board (gravity/refill) per langkah.
## Juice penuh (partikel, shake) = Fase 2 (T2.5).
func _play_report(report: TurnReport) -> void:
	for step in report.steps:
		match step.type:
			MoveAction.Type.TILE_CLEARED:
				if on_tiles_cleared.is_valid():
					on_tiles_cleared.call(step)
				# Board sudah dikosongkan core; mainkan pop di posisi yang hilang.
				await _play_clear_pop(step)
				_refresh_all()
			MoveAction.Type.TILE_FELL, MoveAction.Type.TILE_SPAWNED:
				_refresh_all()
				await get_tree().create_timer(0.06).timeout
			MoveAction.Type.SWAP:
				_refresh_all()
			_:
				_refresh_all()
	_refresh_all()


## Animasi "pop" untuk tile yang di-clear: quad warna asli, scale 1→0 + fade.
func _play_clear_pop(step) -> void:
	var positions: Array = step.positions
	var colors: Array = step.data.get("colors", [])
	if positions.is_empty():
		return
	_animating = true
	var pops: Array[Polygon2D] = []
	var size := float(TILE_SIZE - GAP)
	var half := size * 0.5
	var base_pts := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	])
	for k in range(positions.size()):
		var pos: Vector2i = positions[k]
		var col := Color.WHITE
		if k < colors.size():
			var ci := int(colors[k])
			col = COLOR_PALETTE[ci] if ci < COLOR_PALETTE.size() else Color.WHITE
		var poly := Polygon2D.new()
		poly.polygon = base_pts
		poly.color = col
		poly.position = _tile_pos(pos.x, pos.y)
		poly.z_index = 8
		add_child(poly)
		pops.append(poly)
	# Tween paralel: scale mengecil + fade out.
	var t := create_tween().set_parallel(true)
	for poly in pops:
		t.tween_property(poly, "scale", Vector2(0.1, 0.1), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(poly, "modulate:a", 0.0, 0.16)
	await t.finished
	for poly in pops:
		poly.queue_free()
	_animating = false
