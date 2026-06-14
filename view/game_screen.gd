extends Control
## GameScreen — Fase 4. Memuat LevelDefinition dari JSON (LevelLoader) via
## GameState.current_level_id, mendukung MULTI-objektif (collect/clear_obstacle/
## bring_down/score), obstacle (ice/box/collectible), skor, HUD lengkap, analytics.
## Fallback ke LevelSet (vertical-slice hardcoded) kalau id tak ada di JSON.

var _level: LevelDefinition = null
var _board: Board = null
var _board_view: Node2D = null
var _objectives: Array[ObjectiveBase] = []
var _objective_entries: Array[ObjectiveEntry] = []
var _move_limit := 20
var _moves_left := 20
var _score_x2 := 0
var _finished := false
var _level_start_msec := 0

@onready var _moves_label: Label = $HUD/MovesLabel
@onready var _objective_label: Label = $HUD/ObjectiveLabel
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _result_label: Label = $HUD/ResultLabel
@onready var _instruction_label: Label = $HUD/InstructionLabel
@onready var _title_label: Label = $HUD/TitleLabel
@onready var _debug_label: Label = $HUD/DebugLabel
@onready var _near_miss_label: Label = $HUD/NearMissLabel
@onready var _action_panel: VBoxContainer = $HUD/ActionPanel
@onready var _next_level_btn: Button = $HUD/ActionPanel/NextLevelButton
@onready var _retry_btn: Button = $HUD/ActionPanel/RetryButton
@onready var _back_to_map_btn: Button = $HUD/ActionPanel/BackToMapButton
@onready var _back_button: Button = $HUD/BackButton

var _debug_on := false


func _ready() -> void:
	GameState.is_game_active = true
	_setup_level()
	_update_hud()
	_level_start_msec = Time.get_ticks_msec()
	Analytics.log_event("level_start", {
		"level": _level.id, "move_limit": _move_limit, "objectives": _objective_entries.size(),
	})


func _setup_level() -> void:
	var lid := GameState.current_level_id
	if lid == "":
		lid = LevelLoader.id_at(0)
		GameState.current_level_id = lid
	_level = LevelLoader.get_level(lid)
	if _level == null:
		# Fallback: bangun LevelDefinition dari LevelSet hardcoded (kompat lama).
		_level = _level_from_set(lid)

	_move_limit = _level.move_limit
	_moves_left = _move_limit
	_score_x2 = 0

	# Bangun objektif (bisa lebih dari satu).
	_objective_entries = _level.objectives
	_objectives = []
	for e in _objective_entries:
		_objectives.append(ObjectiveFactory.create(e))

	_board = Board.new()
	_board.setup(_level.board_width, _level.board_height, _level.colors_packed(),
		GameRNG.new(_level.seed), _level.playable_mask, _level.obstacles_for_setup())

	_board_view = $BoardView
	var board_px := _level.board_width * 110
	var ox := int((1080 - board_px) / 2.0)
	_board_view.position = Vector2(ox, 240)
	_board_view.setup_board(_board, GameRNG.new(_level.seed + 1))
	_board_view.on_tiles_cleared = Callable(self, "_on_event")
	_board_view.level_won.connect(_on_level_won)
	_board_view.move_consumed.connect(consume_move)
	_board_view.swap_rejected.connect(_on_swap_rejected)

	if _title_label:
		_title_label.text = "%s — %s" % [_level.id, _level.title]
	if _level.tutorial and _instruction_label:
		_instruction_label.visible = true
		_instruction_label.text = "Geser tile agar 3+ WARNA SAMA sebaris. Ikuti panah kuning!"


## Bangun LevelDefinition dari LevelSet lama (id "1".."5") kalau JSON tak punya.
func _level_from_set(lid: String) -> LevelDefinition:
	var s := LevelSet.get_level(lid)
	if s.is_empty():
		s = LevelSet.get_by_index(0)
	var lv := LevelDefinition.new()
	lv.id = s.get("id", "1")
	lv.title = s.get("title", "")
	lv.board_width = s.get("width", 7)
	lv.board_height = s.get("height", 8)
	var cs: Array[int] = []
	for c in s.get("colors", [1, 2, 3, 4, 5]):
		cs.append(int(c))
	lv.color_subset = cs
	lv.move_limit = s.get("move_limit", 20)
	lv.seed = s.get("seed", 1001)
	lv.tutorial = s.get("tutorial", false)
	var obj: Dictionary = s.get("objective", {"type": "collect", "color": 1, "target": 20})
	var oe := ObjectiveEntry.new(str(obj.get("type", "collect")), int(obj.get("target", 20)), int(obj.get("color", 1)))
	lv.objectives = [oe] as Array[ObjectiveEntry]
	return lv


## Callback BoardView per step penting (TILE_CLEARED & lainnya) → credit semua objektif + skor.
func _on_event(action) -> void:
	for o in _objectives:
		o.credit_from_event(action)
	# Skor akumulatif (cascade index disederhanakan: pakai 0 utk event tunggal).
	_score_x2 += Score.delta_for_event(action, 0)
	GameState.score_x2 = _score_x2
	_update_hud()


func _on_swap_rejected() -> void:
	if _instruction_label:
		_instruction_label.visible = true
		_instruction_label.text = "Belum cocok! Susun 3+ tile WARNA SAMA dalam satu garis. Ikuti panah kuning."
		_instruction_label.modulate = Color(1, 0.7, 0.3)


func _update_hud() -> void:
	if _moves_label:
		_moves_label.text = "Langkah: %d" % _moves_left
	if _objective_label:
		var parts: Array[String] = []
		for i in range(_objectives.size()):
			parts.append(ObjectiveFactory.label_for(_objective_entries[i], _objectives[i]))
		_objective_label.text = "  |  ".join(parts)
	if _score_label:
		_score_label.text = "Skor: %d" % Score.to_display(_score_x2)


func _all_objectives_complete() -> bool:
	for o in _objectives:
		if not o.is_complete():
			return false
	return _objectives.size() > 0


func _process(_delta: float) -> void:
	if _debug_on and _debug_label:
		_debug_label.text = "FPS: %d\np95: %.1fms\nlvl: %s\nstars: %d" % [
			Engine.get_frames_per_second(), PerformanceMonitor.last_p95_frame_ms,
			_level.id, GameState.total_stars(),
		]
	if _finished or _board == null:
		return
	if _all_objectives_complete():
		_finish(true)


func _on_debug_pressed() -> void:
	_debug_on = not _debug_on
	if _debug_label:
		_debug_label.visible = _debug_on


func _finish(won: bool) -> void:
	_finished = true
	GameState.is_game_active = false
	var elapsed := (Time.get_ticks_msec() - _level_start_msec) / 1000.0
	if won:
		var stars := 1  # GDD §6.0: binary 1 star per win
		GameState.record_level_win(_level.id, stars, _moves_left)
		Analytics.log_event("level_complete", {
			"level": _level.id, "moves_left": _moves_left, "stars": stars,
			"score": Score.to_display(_score_x2), "secs": elapsed,
		})
		_show_result(true, stars)
	else:
		Analytics.log_event("level_fail", {
			"level": _level.id, "moves_left": _moves_left, "secs": elapsed,
		})
		_show_result(false, 0)
	AudioManager.play_sfx("win" if won else "lose")
	if won and Settings.haptic_enabled:
		Input.vibrate_handheld(120)


func _show_result(won: bool, stars: int) -> void:
	if _result_label:
		var txt := "MENANG! ★" if won else "HAMPIR!"
		_result_label.text = txt
		_result_label.visible = true
		_animate_result(won)
	if _back_button:
		_back_button.visible = false
	if not won and _near_miss_label:
		var short := _tiles_remaining_total()
		_near_miss_label.text = "Kurang %d tile lagi..." % short
		_near_miss_label.visible = true
	if _action_panel:
		_next_level_btn.visible = won
		_retry_btn.visible = true
		_back_to_map_btn.visible = true
		await get_tree().create_timer(0.8).timeout
		_action_panel.visible = true


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


func _tiles_remaining_total() -> int:
	var total := 0
	for i in range(_objectives.size()):
		var remaining := _objectives[i].get_target() - _objectives[i].get_progress()
		total += maxi(0, remaining)
	return total


func _on_level_won() -> void:
	_finish(true)


func _on_back_pressed() -> void:
	GameState.is_game_active = false
	SceneManager.change_screen("level_map")


func _on_next_level_pressed() -> void:
	var cur_index := LevelLoader.index_of(_level.id)
	var next_index := cur_index + 1
	if next_index < LevelLoader.count():
		GameState.current_level_id = LevelLoader.id_at(next_index)
		SceneManager.change_screen("game")
	else:
		SceneManager.change_screen("meta")


func _on_retry_pressed() -> void:
	SceneManager.change_screen("game")


func _on_back_to_map_pressed() -> void:
	GameState.is_game_active = false
	SceneManager.change_screen("level_map")


func consume_move() -> void:
	if _finished:
		return
	if _instruction_label:
		_instruction_label.visible = false
	_moves_left -= 1
	_update_hud()
	Analytics.log_event("move", {"level": _level.id, "moves_left": _moves_left})
	if _moves_left <= 0 and not _all_objectives_complete():
		_finish(false)
