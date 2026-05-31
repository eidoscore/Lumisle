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
var _selected := Vector2i(-1, -1)
var _move_rng: GameRNG = null

# Callback opsional: dipanggil tiap TILE_CLEARED untuk credit objektif (di-set GameScreen).
var on_tiles_cleared: Callable = Callable()


func setup_board(p_board: Board, move_rng: GameRNG) -> void:
	board = p_board
	_move_rng = move_rng
	_build_multimesh()
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
	return col


func _tile_pos(x: int, y: int) -> Vector2:
	return Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5)


# ---------------------------------------------------------------------------
# Input (T1.12) — tap dua tile bersebelahan untuk swap.
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or board == null:
		return
	# Catatan: dengan emulate_mouse_from_touch (default ON), sentuhan di Android
	# juga menghasilkan InputEventMouseButton. Cukup tangani mouse-button saja agar
	# tidak dobel-proses di perangkat (touch + emulated mouse). Berlaku untuk
	# desktop (editor) maupun Android.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(make_input_local(event).position)


func _handle_tap(local_pos: Vector2) -> void:
	var gx := int(local_pos.x / TILE_SIZE)
	var gy := int(local_pos.y / TILE_SIZE)
	if not board.is_playable(gx, gy):
		return
	if _selected == Vector2i(-1, -1):
		_selected = Vector2i(gx, gy)
		return
	var first := _selected
	_selected = Vector2i(-1, -1)
	# Hanya proses kalau bersebelahan.
	if absi(first.x - gx) + absi(first.y - gy) == 1:
		_do_swap(first.x, first.y, gx, gy)
	else:
		# Tap jauh → jadikan seleksi baru.
		_selected = Vector2i(gx, gy)


func _do_swap(x1: int, y1: int, x2: int, y2: int) -> void:
	var report := board.resolve_swap(x1, y1, x2, y2, _move_rng)
	if not report.is_accepted:
		# Swap invalid / no match → bounce (placeholder: refresh saja).
		_refresh_all()
		return
	_input_enabled = false
	move_consumed.emit()   # giliran valid → kurangi langkah (GameScreen)
	await _play_report(report)
	_input_enabled = true


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
