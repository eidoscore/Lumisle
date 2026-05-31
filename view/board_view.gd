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
var _move_rng: GameRNG = null
var _highlight: Line2D = null         # outline tile terpilih (feedback jelas)
var _animating := false               # true selagi animasi swap/bounce berjalan

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
# Input (T1.12) — DUA gestur didukung:
#   1) DRAG: tekan satu tile → geser ke tetangga → lepas = swap (gestur utama match-3).
#   2) TAP-TAP: tap satu tile (tersorot) → tap tetangga = swap.
# Catatan: emulate_mouse_from_touch (default ON) membuat sentuhan Android juga
# memunculkan InputEventMouse*, jadi cukup tangani jalur mouse saja (mouse + touch
# tidak dobel-proses). Berlaku untuk desktop (editor) maupun Android.
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or _animating or board == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var grid := _grid_at(make_input_local(event).position)
		if event.pressed:
			_on_press(grid)
		else:
			_on_release(grid)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		# Drag aktif: kalau jari sudah pindah ke tetangga tile awal, langsung swap.
		var grid := _grid_at(make_input_local(event).position)
		_on_drag(grid)


## Konversi posisi lokal → koordinat grid (atau (-1,-1) kalau di luar papan).
func _grid_at(local_pos: Vector2) -> Vector2i:
	if local_pos.x < 0 or local_pos.y < 0:
		return Vector2i(-1, -1)
	var gx := int(local_pos.x / TILE_SIZE)
	var gy := int(local_pos.y / TILE_SIZE)
	if gx < 0 or gy < 0 or gx >= board.width or gy >= board.height:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


func _on_press(grid: Vector2i) -> void:
	if grid == Vector2i(-1, -1) or not board.is_playable(grid.x, grid.y):
		_press_grid = Vector2i(-1, -1)
		return
	_press_grid = grid
	# Mode tap-tap: kalau sudah ada tile tersorot & ini tetangganya → swap.
	if _selected != Vector2i(-1, -1) and _is_adjacent(_selected, grid):
		var first := _selected
		_set_selected(Vector2i(-1, -1))
		_do_swap(first.x, first.y, grid.x, grid.y)
		_press_grid = Vector2i(-1, -1)
	else:
		# Sorot tile ini sebagai kandidat (untuk tap-tap & sebagai awal drag).
		_set_selected(grid)


## Selama drag: jika geser melewati batas ke tile tetangga, lakukan swap.
func _on_drag(grid: Vector2i) -> void:
	if _press_grid == Vector2i(-1, -1) or grid == Vector2i(-1, -1):
		return
	if grid == _press_grid:
		return
	if _is_adjacent(_press_grid, grid) and board.is_playable(grid.x, grid.y):
		var from := _press_grid
		_press_grid = Vector2i(-1, -1)
		_set_selected(Vector2i(-1, -1))
		_do_swap(from.x, from.y, grid.x, grid.y)


func _on_release(grid: Vector2i) -> void:
	# Kalau lepas di tetangga tile awal (drag pelan tanpa memicu motion threshold) → swap.
	if _press_grid != Vector2i(-1, -1) and grid != Vector2i(-1, -1) \
			and _is_adjacent(_press_grid, grid) and board.is_playable(grid.x, grid.y):
		var from := _press_grid
		_press_grid = Vector2i(-1, -1)
		_set_selected(Vector2i(-1, -1))
		_do_swap(from.x, from.y, grid.x, grid.y)
		return
	# Lepas di tile yang sama = tap → biarkan tersorot untuk mode tap-tap.
	_press_grid = Vector2i(-1, -1)


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
		# jelas "ditolak", bukan terasa mati.
		await _play_invalid_bounce(x1, y1, x2, y2)
		return
	_input_enabled = false
	move_consumed.emit()   # giliran valid → kurangi langkah (GameScreen)
	# Animasi slide tukar posisi dulu (juice ringan Fase 1), lalu replay hasil.
	await _play_swap_slide(x1, y1, x2, y2)
	await _play_report(report)
	_input_enabled = true


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


## Replay TurnReport: untuk Fase 1, animasi disederhanakan (refresh per step).
## Juice penuh (tween/partikel) = Fase 2 (T2.5).
func _play_report(report: TurnReport) -> void:
	for step in report.steps:
		match step.type:
			MoveAction.Type.TILE_CLEARED:
				if on_tiles_cleared.is_valid():
					on_tiles_cleared.call(step)
				_refresh_all()
				await get_tree().create_timer(0.08).timeout
			MoveAction.Type.TILE_FELL, MoveAction.Type.TILE_SPAWNED:
				_refresh_all()
			MoveAction.Type.SWAP:
				_refresh_all()
				await get_tree().create_timer(0.05).timeout
			_:
				_refresh_all()
	_refresh_all()
