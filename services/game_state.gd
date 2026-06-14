extends Node
## GameState (autoload) — jembatan state global view <-> core.
## Spec: docs/04-tdd-arsitektur.md §5.1. Field detail diisi seiring fase berikutnya.
## T0.7 skeleton: field & signature ke-set; logika level diisi Fase 1+.

# --- Level aktif (null/0 kalau tidak in-game) ---
var current_level_id: String = ""
var current_level_def: Resource = null      # LevelDefinition (data/) — Fase 4
var current_board: RefCounted = null        # Board (core/) — dibuat saat level mulai (Fase 1)
var current_rng: RefCounted = null          # GameRNG (core/) — Fase 1

# --- Progress giliran ---
var moves_used: int = 0
var moves_limit: int = 0
var objectives_tracker: RefCounted = null   # pelacak objektif — Fase 1/4
var score_x2: int = 0                        # skor basis x2 (dok 14 §6); bagi 2 saat display
var is_game_active: bool = false

# --- Progress vertical slice (T3.1/T3.3) ---
# Bintang per level: { level_id(String) -> stars(int 1-3) }. Persist via SaveManager.
var level_stars: Dictionary = {}
# Hasil level terakhir (untuk transisi ke meta): {level_id, won, stars, moves_left}.
var last_result: Dictionary = {}
# ID level berikutnya setelah menang (di-set game_screen, dikonsumsi meta_scene).
var next_level_id: String = ""


func _ready() -> void:
	# Tidak butuh frame update — hemat overhead di low-end (dok 04 §12).
	set_process(false)
	_load_progress()


## Skor untuk ditampilkan ke pemain (basis x2 -> nilai asli). Lihat dok 14 §6.
func score_display() -> int:
	return score_x2 / 2


## Catat hasil menang level: simpan bintang terbaik + persist. (T3.1/T3.3)
func record_level_win(level_id: String, stars: int, moves_left: int) -> void:
	var best: int = int(level_stars.get(level_id, 0))
	if stars > best:
		level_stars[level_id] = stars
	last_result = {"level_id": level_id, "won": true, "stars": stars, "moves_left": moves_left}
	_save_progress()


## Total bintang terkumpul (untuk meta island upgrade).
func total_stars() -> int:
	var t := 0
	for k in level_stars:
		t += int(level_stars[k])
	return t


## Sudah berapa level diselesaikan (>=1 bintang).
func levels_cleared() -> int:
	return level_stars.size()


func _save_progress() -> void:
	var data := SaveManager.load_game()
	data["level_stars"] = level_stars
	SaveManager.save_game(data)


func _load_progress() -> void:
	var data := SaveManager.load_game()
	if data.has("level_stars") and typeof(data["level_stars"]) == TYPE_DICTIONARY:
		# JSON keys selalu String — pastikan nilai int.
		level_stars = {}
		for k in data["level_stars"]:
			level_stars[str(k)] = int(data["level_stars"][k])


## Reset state saat keluar/selesai level. Dipakai Fase 1+.
func reset_level_state() -> void:
	current_level_id = ""
	current_level_def = null
	current_board = null
	current_rng = null
	moves_used = 0
	moves_limit = 0
	objectives_tracker = null
	score_x2 = 0
	is_game_active = false
