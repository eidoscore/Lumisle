extends Node2D
## BoardView (T1.11/T1.12) — render papan via SATU node per tile (ColorRect).
## Logika ada di Board (RefCounted); view hanya menampilkan & menganimasikan.
## Dok 04 §4, §14.2, §14.5. Tile placeholder = kotak berwarna (art di T1.16/Fase 2).
##
## CATATAN ARSITEKTUR (2026-06-01): dulu pakai MultiMeshInstance2D (1 draw call) tapi
## sulit dianimasikan & sulit di-debug (tak ada node di tree), dan urutan animasi
## salah (board dimutasi sebelum slide → warna stale). Untuk board 7×8 (56 tile),
## per-tile node jauh lebih sederhana, feedback jelas, draw call tetap murah.

signal level_won
signal level_lost
signal move_consumed

const TILE_SIZE := 110          # px per sel (termasuk gap)
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

const HINT_DELAY := 0.5               # tampilkan hint cepat setelah board diam
const DRAG_THRESHOLD := 24.0          # px geser minimum untuk memicu swap berarah

var board: Board = null
var _move_rng: GameRNG = null
var _tiles: Array = []                # ColorRect per cell, index = board.idx(x,y)
var _tiles_root: Node2D = null

var _input_enabled := true
var _animating := false
var _selected := Vector2i(-1, -1)     # tile tersorot (tap-tap) / awal drag
var _press_grid := Vector2i(-1, -1)   # tile tempat jari mulai menekan
var _press_pos := Vector2.ZERO        # posisi pixel lokal saat mulai menekan
var _drag_swapped := false            # sudah memicu swap dalam satu gesture
var _use_touch := false               # latch: kalau ada sentuhan native, abaikan emulated mouse

var _highlight: Panel = null          # outline tile terpilih
var _hint_a: Panel = null
var _hint_b: Panel = null
var _hint_shown := false
var _idle_time := 0.0

# Callback opsional: dipanggil tiap TILE_CLEARED untuk credit objektif (di-set GameScreen).
var on_tiles_cleared: Callable = Callable()


func setup_board(p_board: Board, move_rng: GameRNG) -> void:
	board = p_board
	_move_rng = move_rng
	_build_tiles()
	_build_overlay()
	_refresh_all()


# ---------------------------------------------------------------------------
# Build per-tile nodes
# ---------------------------------------------------------------------------

func _build_tiles() -> void:
	if _tiles_root != null and is_instance_valid(_tiles_root):
		_tiles_root.queue_free()
	_tiles_root = Node2D.new()
	add_child(_tiles_root)
	_tiles.clear()
	_tiles.resize(board.width * board.height)
	var vis := float(TILE_SIZE - GAP)
	for y in range(board.height):
		for x in range(board.width):
			var rect := ColorRect.new()
			rect.size = Vector2(vis, vis)
			rect.pivot_offset = Vector2(vis, vis) * 0.5
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_tiles_root.add_child(rect)
			_tiles[board.idx(x, y)] = rect
	_layout_tiles()


func _layout_tiles() -> void:
	for y in range(board.height):
		for x in range(board.width):
			var rect: ColorRect = _tiles[board.idx(x, y)]
			rect.position = _tile_topleft(x, y)
			rect.scale = Vector2.ONE
			rect.pivot_offset = rect.size * 0.5


## Posisi sudut kiri-atas ColorRect untuk sel (x,y).
func _tile_topleft(x: int, y: int) -> Vector2:
	return Vector2(x * TILE_SIZE + GAP * 0.5, y * TILE_SIZE + GAP * 0.5)


## Pusat sel (x,y) — untuk overlay & hint.
func _tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5)


# ---------------------------------------------------------------------------
# Overlay (highlight + hint) — Panel kotak transparan dengan border.
# ---------------------------------------------------------------------------

func _build_overlay() -> void:
	_highlight = _make_outline(Color(1, 1, 1, 0.95))
	_highlight.z_index = 10
	_hint_a = _make_outline(Color(1, 0.9, 0.2, 0.95))
	_hint_b = _make_outline(Color(1, 0.9, 0.2, 0.95))


func _make_outline(col: Color) -> Panel:
	var p := Panel.new()
	var sz := float(TILE_SIZE - GAP)
	p.size = Vector2(sz, sz)
	p.pivot_offset = Vector2(sz, sz) * 0.5
	p.z_index = 9
	p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	return p


func _place_outline(p: Panel, grid: Vector2i) -> void:
	if p == null:
		return
	if grid == Vector2i(-1, -1):
		p.visible = false
		return
	p.position = _tile_topleft(grid.x, grid.y)
	p.visible = true


# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------

func _refresh_all() -> void:
	if board == null:
		return
	for y in range(board.height):
		for x in range(board.width):
			_refresh_tile(x, y)


func _refresh_tile(x: int, y: int) -> void:
	var rect: ColorRect = _tiles[board.idx(x, y)]
	if rect == null:
		return
	rect.position = _tile_topleft(x, y)
	rect.scale = Vector2.ONE
	rect.modulate = Color.WHITE
	rect.color = _color_for(x, y)
	rect.visible = rect.color.a > 0.0


func _color_for(x: int, y: int) -> Color:
	if not board.is_playable(x, y):
		return Color(0, 0, 0, 0)
	if board.cell_blocks_movement(x, y):
		return Color(0.5, 0.4, 0.3)
	var c := board.get_color(x, y)
	if c == TileCodes.EMPTY:
		return Color(0, 0, 0, 0.12)
	var col: Color = COLOR_PALETTE[c] if c < COLOR_PALETTE.size() else Color.WHITE
	if board.get_special(x, y) != TileCodes.SPECIAL_NONE:
		col = col.lightened(0.35)
	return col


# ---------------------------------------------------------------------------
# Idle hint — tampilkan SATU langkah valid agar pemain tahu swap mana yang bisa.
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
	_place_outline(_hint_a, a)
	_place_outline(_hint_b, b)
	_hint_shown = true
	var t := create_tween().set_loops()
	t.tween_property(_hint_a, "modulate:a", 0.2, 0.45)
	t.parallel().tween_property(_hint_b, "modulate:a", 0.2, 0.45)
	t.tween_property(_hint_a, "modulate:a", 1.0, 0.45)
	t.parallel().tween_property(_hint_b, "modulate:a", 1.0, 0.45)
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


## Reset timer idle TANPA menyembunyikan hint (hint tetap terlihat selagi menimbang).
func _touch_activity() -> void:
	_idle_time = 0.0


# ---------------------------------------------------------------------------
# Input — flick berarah (4 arah) + tap-tap. Tangani touch native; mouse = fallback.
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or _animating or board == null:
		return

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
	if _selected != Vector2i(-1, -1) and _is_adjacent(_selected, grid):
		var first := _selected
		_set_selected(Vector2i(-1, -1))
		_press_grid = Vector2i(-1, -1)
		_do_swap(first.x, first.y, grid.x, grid.y)
	else:
		_set_selected(grid)


func _on_drag(local_pos: Vector2) -> void:
	if _press_grid == Vector2i(-1, -1) or _drag_swapped:
		return
	var d := local_pos - _press_pos
	if d.length() < DRAG_THRESHOLD:
		return
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


func _set_selected(grid: Vector2i) -> void:
	if _selected == grid:
		return
	_selected = grid
	_place_outline(_highlight, grid)


# ---------------------------------------------------------------------------
# Swap flow — URUTAN BENAR (saran DeepSeek):
#   1) validasi TANPA mutasi (swap_will_match)
#   2) animasi slide (state board masih lama → warna benar) ATAU bounce
#   3) BARU resolve_swap (mutasi board)
#   4) replay cascade (pop clear, gravity, refill)
# ---------------------------------------------------------------------------

func _do_swap(x1: int, y1: int, x2: int, y2: int) -> void:
	_set_selected(Vector2i(-1, -1))
	if _animating:
		return

	var will_match := board.swap_will_match(x1, y1, x2, y2)

	if not will_match:
		# Slide ke tetangga lalu balik — jelas "ditolak", warna tetap benar (board tak berubah).
		await _anim_swap_visual(x1, y1, x2, y2)
		await _anim_swap_visual(x2, y2, x1, y1)
		_refresh_all()
		_idle_time = 0.0
		return

	_input_enabled = false
	_clear_hint()
	# 1) Animasi slide kedua tile bertukar (board masih state lama → warna benar).
	await _anim_swap_visual(x1, y1, x2, y2)
	# 2) Mutasi board + dapatkan replay log.
	var report := board.resolve_swap(x1, y1, x2, y2, _move_rng)
	move_consumed.emit()
	# 3) Sinkronkan grid ke state pasca-swap, lalu replay cascade.
	_refresh_all()
	await _play_report(report)
	_input_enabled = true
	_idle_time = 0.0
	_clear_hint()


## Animasi 2 tile bertukar posisi secara visual (geser node). TIDAK mengubah board.
## Setelah selesai, posisi node dikembalikan ke grid masing-masing (caller refresh).
func _anim_swap_visual(x1: int, y1: int, x2: int, y2: int) -> void:
	_animating = true
	var r1: ColorRect = _tiles[board.idx(x1, y1)]
	var r2: ColorRect = _tiles[board.idx(x2, y2)]
	var p1 := _tile_topleft(x1, y1)
	var p2 := _tile_topleft(x2, y2)
	var t := create_tween().set_parallel(true)
	t.tween_property(r1, "position", p2, 0.12).set_trans(Tween.TRANS_QUAD)
	t.tween_property(r2, "position", p1, 0.12).set_trans(Tween.TRANS_QUAD)
	await t.finished
	# Kembalikan posisi node (data board yang otoritatif; caller akan _refresh_all).
	r1.position = p1
	r2.position = p2
	_animating = false


## Replay TurnReport: animasikan clear (pop), gravity & refill (tile turun).
func _play_report(report: TurnReport) -> void:
	_animating = true
	for step in report.steps:
		match step.type:
			MoveAction.Type.TILE_CLEARED:
				if on_tiles_cleared.is_valid():
					on_tiles_cleared.call(step)
				await _anim_clear_pop(step)
				_refresh_all()
			MoveAction.Type.TILE_FELL, MoveAction.Type.TILE_SPAWNED:
				_refresh_all()
				await get_tree().create_timer(0.05).timeout
			_:
				_refresh_all()
	_refresh_all()
	_animating = false


## Pop tile yang di-clear: kecilkan + fade ColorRect-nya, lalu refresh balikin.
func _anim_clear_pop(step) -> void:
	var positions: Array = step.positions
	if positions.is_empty():
		return
	var t := create_tween().set_parallel(true)
	for pos in positions:
		var p: Vector2i = pos
		var rect: ColorRect = _tiles[board.idx(p.x, p.y)]
		if rect == null:
			continue
		rect.pivot_offset = rect.size * 0.5
		t.tween_property(rect, "scale", Vector2(0.1, 0.1), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(rect, "modulate:a", 0.0, 0.16)
	await t.finished
