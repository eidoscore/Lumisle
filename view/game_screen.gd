extends Control
## GameScreen — vertical slice (Fase 3). Memuat level dari LevelSet (T3.1) via
## GameState.current_level_id, objektif, FTUE tutorial (T3.2), analytics (T3.4),
## dan catat bintang → meta saat menang (T3.3).
## Struktur dok 04 §14.2. Board logic = Board (core); view = BoardView.

var _level: Dictionary = {}
var _board: Board = null
var _board_view: Node2D = null
var _objective: CollectObjective = null
var _move_limit := 20
var _moves_left := 20
var _finished := false
var _level_start_msec := 0

@onready var _moves_label: Label = $HUD/MovesLabel
@onready var _objective_label: Label = $HUD/ObjectiveLabel
@onready var _result_label: Label = $HUD/ResultLabel
@onready var _instruction_label: Label = $HUD/InstructionLabel
@onready var _title_label: Label = $HUD/TitleLabel
@onready var _debug_label: Label = $HUD/DebugLabel

var _debug_on := false


func _ready() -> void:
	GameState.is_game_active = true
	_setup_level()
	_update_hud()
	_level_start_msec = Time.get_ticks_msec()
	Analytics.log_event("level_start", {
		"level": _level.get("id", "?"),
		"move_limit": _move_limit,
		"objective": _level.get("objective", {}),
	})


func _setup_level() -> void:
	# Ambil level aktif (default level 1 kalau belum di-set).
	var lid := GameState.current_level_id
	if lid == "":
		lid = "1"
		GameState.current_level_id = lid
	_level = LevelSet.get_level(lid)
	if _level.is_empty():
		_level = LevelSet.get_by_index(0)
		GameState.current_level_id = _level.get("id", "1")

	var w: int = _level.get("width", 7)
	var h: int = _level.get("height", 8)
	var colors := LevelSet.colors_packed(_level)
	var seed: int = _level.get("seed", 20260531)
	_move_limit = _level.get("move_limit", 20)
	_moves_left = _move_limit

	var obj: Dictionary = _level.get("objective", {"type": "collect", "color": 1, "target": 20})
	_objective = CollectObjective.new(int(obj.get("color", 1)), int(obj.get("target", 20)))

	_board = Board.new()
	_board.setup(w, h, colors, GameRNG.new(seed))

	_board_view = $BoardView
	# Pusatkan board secara horizontal: lebar board = w*110, layar 1080.
	var board_px := w * 110
	var ox := int((1080 - board_px) / 2.0)
	_board_view.position = Vector2(ox, 300)
	_board_view.setup_board(_board, GameRNG.new(seed + 1))
	_board_view.on_tiles_cleared = Callable(self, "_on_tiles_cleared")
	_board_view.level_won.connect(_on_level_won)
	_board_view.move_consumed.connect(consume_move)
	_board_view.swap_rejected.connect(_on_swap_rejected)

	if _title_label:
		_title_label.text = "Level %s — %s" % [_level.get("id", "?"), _level.get("title", "")]

	# FTUE (T3.2): tutorial level menampilkan instruksi + hint cepat.
	if _level.get("tutorial", false):
		if _instruction_label:
			_instruction_label.visible = true
			_instruction_label.text = "Geser tile agar 3+ WARNA SAMA sebaris. Ikuti panah kuning!"


## Dipanggil BoardView tiap TILE_CLEARED → credit objektif + cek menang.
func _on_tiles_cleared(action) -> void:
	_objective.credit_from_event(action)
	_update_hud()


## Swap ditolak (tak bikin 3 sebaris) → kasih tahu pemain alasannya (edukasi aturan).
func _on_swap_rejected() -> void:
	if _instruction_label:
		_instruction_label.visible = true
		_instruction_label.text = "Belum cocok! Susun 3+ tile WARNA SAMA dalam satu garis. Ikuti panah kuning."
		_instruction_label.modulate = Color(1, 0.7, 0.3)


func _update_hud() -> void:
	if _moves_label:
		_moves_label.text = "Langkah: %d" % _moves_left
	if _objective_label and _objective:
		_objective_label.text = "Objektif: %d/%d" % [_objective.get_progress(), _objective.get_target()]


func _process(_delta: float) -> void:
	if _debug_on and _debug_label:
		_debug_label.text = "FPS: %d\np95: %.1fms\nlevel: %s\nstars total: %d" % [
			Engine.get_frames_per_second(),
			PerformanceMonitor.last_p95_frame_ms,
			_level.get("id", "?"),
			GameState.total_stars(),
		]
	if _finished or _board == null:
		return
	if _objective.is_complete():
		_finish(true)


## Toggle debug HUD (T3.4).
func _on_debug_pressed() -> void:
	_debug_on = not _debug_on
	if _debug_label:
		_debug_label.visible = _debug_on


func _finish(won: bool) -> void:
	_finished = true
	GameState.is_game_active = false
	var elapsed := (Time.get_ticks_msec() - _level_start_msec) / 1000.0
	var lid: String = _level.get("id", "?")
	if won:
		var stars := LevelSet.stars_for(_moves_left, _move_limit)
		GameState.record_level_win(lid, stars, _moves_left)
		Analytics.log_event("level_complete", {
			"level": lid, "moves_left": _moves_left, "stars": stars, "secs": elapsed,
		})
		_show_result(true, stars)
	else:
		Analytics.log_event("level_fail", {
			"level": lid, "moves_left": _moves_left,
			"progress": _objective.get_progress(), "secs": elapsed,
		})
		_show_result(false, 0)
	AudioManager.play_sfx("win" if won else "lose")
	if won and Settings.haptic_enabled:
		Input.vibrate_handheld(120)


func _show_result(won: bool, stars: int) -> void:
	if _result_label:
		var txt := "MENANG!" if won else "KALAH"
		if won:
			txt += "\n" + "★".repeat(stars) + "☆".repeat(3 - stars)
		_result_label.text = txt
		_result_label.visible = true
		_animate_result(won)
	# Setelah jeda, ke meta (menang) atau kembali ke peta (kalah).
	await get_tree().create_timer(1.8).timeout
	if won:
		SceneManager.change_screen("meta")
	else:
		SceneManager.change_screen("level_map")


## Animasi reward (T2.7): label hasil "pop" + (menang) bintang terbang.
func _animate_result(won: bool) -> void:
	_result_label.pivot_offset = _result_label.size * 0.5
	_result_label.scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.tween_property(_result_label, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_result_label, "scale", Vector2(1.0, 1.0), 0.12)
	if won:
		_spawn_win_stars()


func _spawn_win_stars() -> void:
	var pt := CPUParticles2D.new()
	pt.position = Vector2(540, 1100)
	pt.z_index = 50
	pt.emitting = false
	pt.one_shot = true
	pt.explosiveness = 0.8
	pt.amount = 40
	pt.lifetime = 1.2
	pt.direction = Vector2(0, -1)
	pt.spread = 70.0
	pt.gravity = Vector2(0, 300)
	pt.initial_velocity_min = 300.0
	pt.initial_velocity_max = 700.0
	pt.scale_amount_min = 4.0
	pt.scale_amount_max = 8.0
	pt.color = Color(1.0, 0.85, 0.2)
	$HUD.add_child(pt)
	pt.restart()
	pt.emitting = true


func _on_level_won() -> void:
	_finish(true)


# --- Tombol HUD ---

func _on_back_pressed() -> void:
	GameState.is_game_active = false
	SceneManager.change_screen("level_map")


## Dipanggil oleh BoardView setiap giliran valid untuk mengurangi langkah.
func consume_move() -> void:
	if _finished:
		return
	if _instruction_label:
		_instruction_label.visible = false
	_moves_left -= 1
	_update_hud()
	Analytics.log_event("move", {"level": _level.get("id", "?"), "moves_left": _moves_left})
	if _moves_left <= 0 and not _objective.is_complete():
		_finish(false)
