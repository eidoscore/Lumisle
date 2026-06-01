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
signal swap_rejected          # swap valid posisi tapi tak bikin match (untuk feedback edukasi)

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
var _backdrop: Panel = null           # papan gelap di belakang grid (kontras tile)
var _disp: PackedInt32Array = PackedInt32Array()  # state TAMPILAN (encoded), di-replay dari report — BUKAN baca board final

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
var _hint_arrow: Line2D = null        # panah antar dua tile hint (jelaskan arah swap)
var _hint_shown := false
var _idle_time := 0.0

# --- Juice (T2.5) ---
var _fx_root: Node2D = null           # parent partikel
var _particle_pool: Array = []        # CPUParticles2D pooled
var _particle_next := 0
const PARTICLE_POOL_SIZE := 16
var _shake_amount := 0.0              # intensitas shake aktif
var _base_offset := Vector2.ZERO     # posisi dasar _tiles_root (untuk shake)
var _cascade_depth := 0              # untuk pitch SFX naik per cascade

# Callback opsional: dipanggil tiap TILE_CLEARED untuk credit objektif (di-set GameScreen).
var on_tiles_cleared: Callable = Callable()


func setup_board(p_board: Board, move_rng: GameRNG) -> void:
	board = p_board
	_move_rng = move_rng
	_sync_disp_from_board()
	_build_tiles()
	_build_overlay()
	_build_fx()
	_refresh_all()


## Salin state board → grid tampilan (_disp). Dipakai saat init & sinkron pra-swap.
func _sync_disp_from_board() -> void:
	_disp = board.cells.duplicate()


func _disp_cell(x: int, y: int) -> int:
	return _disp[board.idx(x, y)]


func _disp_color(x: int, y: int) -> int:
	return TileCodes.decode_color(_disp_cell(x, y))


func _disp_special(x: int, y: int) -> int:
	return TileCodes.decode_special(_disp_cell(x, y))


# ---------------------------------------------------------------------------
# Juice infra (T2.5) — pool partikel + screen shake.
# ---------------------------------------------------------------------------

func _build_fx() -> void:
	if _fx_root != null and is_instance_valid(_fx_root):
		_fx_root.queue_free()
	_fx_root = Node2D.new()
	_fx_root.z_index = 20
	add_child(_fx_root)
	_particle_pool.clear()
	for i in range(PARTICLE_POOL_SIZE):
		var pt := CPUParticles2D.new()
		pt.emitting = false
		pt.one_shot = true
		pt.explosiveness = 0.95
		pt.amount = 10
		pt.lifetime = 0.5
		pt.direction = Vector2(0, -1)
		pt.spread = 180.0
		pt.gravity = Vector2(0, 600)
		pt.initial_velocity_min = 80.0
		pt.initial_velocity_max = 220.0
		pt.scale_amount_min = 3.0
		pt.scale_amount_max = 6.0
		_fx_root.add_child(pt)
		_particle_pool.append(pt)


## Semburan partikel di posisi sel (warna mengikuti tile).
func _burst_particles(grid: Vector2i, col: Color) -> void:
	if _particle_pool.is_empty():
		return
	var pt: CPUParticles2D = _particle_pool[_particle_next]
	_particle_next = (_particle_next + 1) % _particle_pool.size()
	pt.position = _tile_center(grid.x, grid.y)
	pt.color = col
	pt.restart()
	pt.emitting = true


## Picu screen shake (intensitas px). Di-decay di _process.
func _shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)


# ---------------------------------------------------------------------------
# Build per-tile nodes
# ---------------------------------------------------------------------------

## Panel gelap membulat di belakang grid → tile permata terang lebih "pop".
func _build_board_backdrop() -> void:
	if _backdrop != null and is_instance_valid(_backdrop):
		_backdrop.queue_free()
	_backdrop = Panel.new()
	var pad := 18.0
	_backdrop.position = Vector2(-pad, -pad)
	_backdrop.size = Vector2(board.width * TILE_SIZE + pad * 2.0, board.height * TILE_SIZE + pad * 2.0)
	_backdrop.z_index = -5
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.16, 0.55)
	sb.set_corner_radius_all(28)
	sb.border_color = Color(0.5, 0.55, 0.85, 0.30)
	sb.set_border_width_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 12
	_backdrop.add_theme_stylebox_override("panel", sb)
	add_child(_backdrop)


func _build_tiles() -> void:
	if _tiles_root != null and is_instance_valid(_tiles_root):
		_tiles_root.queue_free()
	_build_board_backdrop()
	_tiles_root = Node2D.new()
	add_child(_tiles_root)
	_tiles.clear()
	_tiles.resize(board.width * board.height)
	var vis := float(TILE_SIZE - GAP)
	for y in range(board.height):
		for x in range(board.width):
			# TileGfx = bentuk permata prosedural unik per warna (dok 07 §2.3).
			var rect := TileGfx.new()
			rect.size = Vector2(vis, vis)
			rect.pivot_offset = Vector2(vis, vis) * 0.5
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Marker glyph putih untuk special (di atas glow permata).
			var marker := Label.new()
			marker.size = Vector2(vis, vis)
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			marker.add_theme_font_size_override("font_size", 52)
			marker.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
			marker.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.18, 0.9))
			marker.add_theme_constant_override("outline_size", 8)
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			marker.text = ""
			rect.add_child(marker)
			rect.set_meta("marker", marker)
			_tiles_root.add_child(rect)
			_tiles[board.idx(x, y)] = rect
	_layout_tiles()


func _layout_tiles() -> void:
	for y in range(board.height):
		for x in range(board.width):
			var rect: TileGfx = _tiles[board.idx(x, y)]
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
	# Panah hint: garis tebal kuning dari tile a → b untuk menunjukkan ARAH swap.
	_hint_arrow = Line2D.new()
	_hint_arrow.width = 22.0
	_hint_arrow.default_color = Color(1, 0.8, 0.0, 1.0)
	_hint_arrow.z_index = 30
	_hint_arrow.visible = false
	_hint_arrow.joint_mode = Line2D.LINE_JOINT_ROUND
	_hint_arrow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_hint_arrow.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_hint_arrow)


func _make_outline(col: Color) -> Panel:
	var p := Panel.new()
	var sz := float(TILE_SIZE - GAP)
	p.size = Vector2(sz, sz)
	p.pivot_offset = Vector2(sz, sz) * 0.5
	p.z_index = 25
	p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.22)   # isi semi-transparan agar menonjol
	sb.border_color = Color(1, 1, 1, 1)              # border putih tebal = kontras di semua warna
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(8)
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
	var rect: TileGfx = _tiles[board.idx(x, y)]
	if rect == null:
		return
	rect.position = _tile_topleft(x, y)
	rect.scale = Vector2.ONE
	rect.modulate = Color.WHITE
	var playable := board.is_playable(x, y)
	var blocker := playable and board.cell_blocks_movement(x, y)
	var ccode := _disp_color(x, y) if playable else 0
	var sp := _disp_special(x, y) if playable else 0
	var empty_slot := playable and not blocker and ccode == TileCodes.EMPTY
	rect.set_tile(ccode, sp, _color_for(x, y), blocker, empty_slot)
	rect.visible = playable
	# Marker special (glyph putih di atas permata).
	if rect.has_meta("marker"):
		var marker: Label = rect.get_meta("marker")
		marker.text = _special_glyph(sp) if playable else ""


## Glyph placeholder per tipe special (dibedakan jelas; ikon final = art Fase 2).
func _special_glyph(special_type: int) -> String:
	match special_type:
		TileCodes.SPECIAL_ROCKET_H: return "↔"
		TileCodes.SPECIAL_ROCKET_V: return "↕"
		TileCodes.SPECIAL_BOMB: return "✸"
		TileCodes.SPECIAL_COLORBOMB: return "◎"
		TileCodes.SPECIAL_PROPELLER: return "✜"
		_: return ""


## Warna tile dari grid TAMPILAN (_disp), bukan board final (penting utk animasi replay).
func _color_for(x: int, y: int) -> Color:
	if not board.is_playable(x, y):
		return Color(0, 0, 0, 0)
	if board.cell_blocks_movement(x, y):
		return Color(0.5, 0.4, 0.3)
	var c := _disp_color(x, y)
	if c == TileCodes.EMPTY:
		return Color(0, 0, 0, 0.12)
	var col: Color = COLOR_PALETTE[c] if c < COLOR_PALETTE.size() else Color.WHITE
	if _disp_special(x, y) != TileCodes.SPECIAL_NONE:
		col = col.lightened(0.35)
	return col


# ---------------------------------------------------------------------------
# Idle hint — tampilkan SATU langkah valid agar pemain tahu swap mana yang bisa.
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	# Screen shake decay (T2.5) — jalan walau animasi/locked.
	if _shake_amount > 0.01 and _tiles_root != null:
		var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
		_tiles_root.position = _base_offset + off
		_shake_amount = lerpf(_shake_amount, 0.0, clampf(delta * 12.0, 0.0, 1.0))
		if _shake_amount <= 0.01:
			_tiles_root.position = _base_offset
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
	_draw_hint_arrow(a, b)
	_hint_shown = true
	var t := create_tween().set_loops()
	t.tween_property(_hint_a, "modulate:a", 0.2, 0.45)
	t.parallel().tween_property(_hint_b, "modulate:a", 0.2, 0.45)
	t.tween_property(_hint_a, "modulate:a", 1.0, 0.45)
	t.parallel().tween_property(_hint_b, "modulate:a", 1.0, 0.45)
	_hint_a.set_meta("tween", t)


## Gambar panah dari pusat tile a ke pusat tile b (menjelaskan: "geser a ke arah b").
## Dibuat TEBAL & jelas supaya kebaca di HP (sebelumnya terlalu tipis).
func _draw_hint_arrow(a: Vector2i, b: Vector2i) -> void:
	var ca := _tile_center(a.x, a.y)
	var cb := _tile_center(b.x, b.y)
	var dir := (cb - ca).normalized()
	var start := ca + dir * 10.0
	var tip := cb - dir * 8.0
	var perp := Vector2(-dir.y, dir.x)
	var head := 30.0
	var h1 := tip - dir * head + perp * head * 0.7
	var h2 := tip - dir * head - perp * head * 0.7
	_hint_arrow.points = PackedVector2Array([start, tip, h1, tip, h2])
	_hint_arrow.visible = true


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
	if _hint_arrow:
		_hint_arrow.visible = false


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
		AudioManager.play_sfx("invalid")
		swap_rejected.emit()
		await _anim_swap_visual(x1, y1, x2, y2)
		await _anim_swap_visual(x2, y2, x1, y1)
		_refresh_all()
		# Langsung tampilkan hint langkah valid (bantu pemain yang bingung).
		_idle_time = HINT_DELAY
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
	var r1: TileGfx = _tiles[board.idx(x1, y1)]
	var r2: TileGfx = _tiles[board.idx(x2, y2)]
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


## Replay TurnReport: animasikan clear (pop+partikel), special trigger (flash+shake),
## gravity & refill (tile turun bounce), + SFX/haptic. Juice = T2.5/T2.6.
func _play_report(report: TurnReport) -> void:
	_animating = true
	_cascade_depth = 0
	for step in report.steps:
		match step.type:
			MoveAction.Type.TILE_CLEARED:
				if on_tiles_cleared.is_valid():
					on_tiles_cleared.call(step)
				_cascade_depth += 1
				# SFX pitch naik per cascade (lebih dalam → lebih tinggi/heboh).
				AudioManager.play_sfx("match", 1.0 + 0.12 * float(_cascade_depth - 1))
				if Settings.haptic_enabled and step.positions.size() >= 4:
					Input.vibrate_handheld(20)
				await _anim_clear_pop(step)
				_refresh_all()
			MoveAction.Type.SPECIAL_TRIGGERED:
				AudioManager.play_sfx("special")
				_shake(6.0)
				if Settings.haptic_enabled:
					Input.vibrate_handheld(30)
				await get_tree().create_timer(0.04).timeout
			MoveAction.Type.COMBO_TRIGGERED:
				AudioManager.play_sfx("combo")
				_shake(12.0)
				if Settings.haptic_enabled:
					Input.vibrate_handheld(50)
			MoveAction.Type.TILE_FELL, MoveAction.Type.TILE_SPAWNED:
				_refresh_all()
				await get_tree().create_timer(0.05).timeout
			_:
				_refresh_all()
	# Sinkronkan state tampilan ke board final (PENTING: tanpa ini _disp basi →
	# display & board diverge → tile yang user lihat beda dgn board sebenarnya).
	_sync_disp_from_board()
	_refresh_all()
	_animating = false


## Pop tile yang di-clear: kecilkan + fade ColorRect + semburan partikel, lalu refresh.
func _anim_clear_pop(step) -> void:
	var positions: Array = step.positions
	if positions.is_empty():
		return
	var t := create_tween().set_parallel(true)
	for pos in positions:
		var p: Vector2i = pos
		var rect: TileGfx = _tiles[board.idx(p.x, p.y)]
		if rect == null:
			continue
		_burst_particles(p, rect.base_color)
		rect.pivot_offset = rect.size * 0.5
		t.tween_property(rect, "scale", Vector2(0.1, 0.1), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(rect, "modulate:a", 0.0, 0.16)
	# Shake ringan proporsional jumlah tile (cap supaya tidak lebay).
	_shake(minf(2.0 + positions.size() * 0.6, 8.0))
	await t.finished
