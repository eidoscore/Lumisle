extends Control
## GameScreen (T1.13) — 1 level hardcoded yang bisa dimenangkan/kalah.
## Struktur dok 04 §14.2. Board logic = Board (core); view = BoardView.
## Objektif pakai CollectObjective (kontrak ObjectiveBase) — Fase 4 tinggal nambah tipe.

const LEVEL_WIDTH := 7
const LEVEL_HEIGHT := 8
var _level_colors := PackedInt32Array([1, 2, 3, 4, 5])
const LEVEL_SEED := 20260531
const MOVE_LIMIT := 20
const OBJECTIVE_COLOR := 1
const OBJECTIVE_TARGET := 25

var _board: Board = null
var _board_view: Node2D = null
var _objective: CollectObjective = null
var _moves_left := MOVE_LIMIT
var _finished := false

@onready var _moves_label: Label = $HUD/MovesLabel
@onready var _objective_label: Label = $HUD/ObjectiveLabel
@onready var _result_label: Label = $HUD/ResultLabel
@onready var _instruction_label: Label = $HUD/InstructionLabel


func _ready() -> void:
	GameState.is_game_active = true
	_setup_level()
	_update_hud()


func _setup_level() -> void:
	_board = Board.new()
	_board.setup(LEVEL_WIDTH, LEVEL_HEIGHT, _level_colors, GameRNG.new(LEVEL_SEED))
	_objective = CollectObjective.new(OBJECTIVE_COLOR, OBJECTIVE_TARGET)
	_moves_left = MOVE_LIMIT

	_board_view = $BoardView
	# Posisikan board view di tengah-atas area bermain.
	_board_view.position = Vector2(60, 280)
	_board_view.setup_board(_board, GameRNG.new(LEVEL_SEED + 1))
	_board_view.on_tiles_cleared = Callable(self, "_on_tiles_cleared")
	_board_view.level_won.connect(_on_level_won)
	_board_view.move_consumed.connect(consume_move)
	_board_view.swap_rejected.connect(_on_swap_rejected)


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


## Setelah satu giliran selesai (dipanggil dari handler swap via BoardView).
## Kita pantau melalui polling sederhana: kurangi langkah saat swap accepted.
func _on_swap_consumed() -> void:
	pass


func _update_hud() -> void:
	if _moves_label:
		_moves_label.text = "Langkah: %d" % _moves_left
	if _objective_label:
		_objective_label.text = "Kumpulkan merah: %d/%d" % [_objective.get_progress(), _objective.get_target()]


func _process(_delta: float) -> void:
	# Cek kondisi menang/kalah tiap frame (sederhana untuk Fase 1).
	if _finished or _board == null:
		return
	if _objective.is_complete():
		_finish(true)


func _finish(won: bool) -> void:
	_finished = true
	GameState.is_game_active = false
	if _result_label:
		_result_label.text = "MENANG!" if won else "KALAH"
		_result_label.visible = true
		_animate_result(won)
	# SFX + haptic (T2.6/T2.7).
	AudioManager.play_sfx("win" if won else "lose")
	if won and Settings.haptic_enabled:
		Input.vibrate_handheld(120)


## Animasi reward sederhana (T2.7): label hasil "pop" + (menang) bintang terbang.
func _animate_result(won: bool) -> void:
	_result_label.pivot_offset = _result_label.size * 0.5
	_result_label.scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.tween_property(_result_label, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_result_label, "scale", Vector2(1.0, 1.0), 0.12)
	if won:
		_spawn_win_stars()


## Bintang/koin terbang dari tengah layar ke atas (placeholder reward menang).
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
## (Di Fase 1 kita hubungkan via signal sederhana di board_view.)
func consume_move() -> void:
	if _finished:
		return
	# Sembunyikan instruksi tutorial setelah langkah valid pertama.
	if _instruction_label:
		_instruction_label.visible = false
	_moves_left -= 1
	_update_hud()
	if _moves_left <= 0 and not _objective.is_complete():
		_finish(false)
