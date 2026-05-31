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


func _ready() -> void:
	# Tidak butuh frame update — hemat overhead di low-end (dok 04 §12).
	set_process(false)


## Skor untuk ditampilkan ke pemain (basis x2 -> nilai asli). Lihat dok 14 §6.
func score_display() -> int:
	return score_x2 / 2


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
