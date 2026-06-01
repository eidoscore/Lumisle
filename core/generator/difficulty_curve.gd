class_name DifficultyCurve extends Resource
## T5.1 — Kurva kesulitan TUNABLE (dok 05 §3). Dipisah dari logika (difficulty_model.gd)
## supaya bisa di-tweak via .tres tanpa ubah kode. Semua nilai = "knob" desainer.
##
## Konsep kurva (dok 05 §3.2): naik bertahap + variasi berseed + sesekali spike lalu
## "napas". difficulty_model membaca knob ini untuk memetakan nomor level → parameter.

# --- Batas band (nomor level inklusif atas tiap band; dok 05 §2 enum DifficultyBand) ---
@export var band_ftue_max: int = 10        # 1..10   FTUE
@export var band_learning_max: int = 30    # 11..30  Learning
@export var band_practice_max: int = 60    # 31..60  Practice
@export var band_challenge_max: int = 100  # 61..100 Challenge
# > band_challenge_max → Endgame (101+)

# --- Target win-rate per band (ensemble), [min,max] (dok 05 §5.4) ---
@export var winrate_ftue := Vector2(0.85, 0.95)
@export var winrate_learning := Vector2(0.80, 0.90)
@export var winrate_practice := Vector2(0.70, 0.85)
@export var winrate_challenge := Vector2(0.60, 0.80)
@export var winrate_endgame := Vector2(0.45, 0.70)

# --- Ukuran papan (lebar/tinggi) per progres ---
@export var board_w_min: int = 7
@export var board_w_max: int = 8
@export var board_h_min: int = 7
@export var board_h_max: int = 9

# --- Jumlah warna aktif (subset) ---
@export var colors_min: int = 4
@export var colors_max: int = 6

# --- Rasio langkah (move_limit awal) terhadap "kebutuhan kasar" objektif ---
# move_limit_awal = ceil(objective_total / clears_per_move_est * move_ratio)
@export var move_ratio_easy: float = 2.0   # band awal: longgar
@export var move_ratio_hard: float = 1.25  # band akhir: mepet
@export var clears_per_move_est: float = 3.5  # estimasi tile ter-clear per langkah

# --- Rintangan: kepadatan (proporsi cell playable) per band akhir ---
@export var obstacle_density_max: float = 0.18

# --- Variasi/jitter berseed (supaya level berdekatan tak identik) + spike ---
@export var jitter_strength: float = 0.12  # ±12% di parameter numerik
@export var spike_every: int = 9           # tiap ~9 level, 1 level lebih sulit
@export var spike_boost: float = 0.18      # +18% kesulitan saat spike
@export var relief_after_spike: float = 0.10  # -10% (napas) sesudah spike


## Nomor level (1-based) → progres 0..1 sepanjang kurva yang relevan (cap di endgame_ref).
func progress_for_level(n: int, endgame_ref: int = 150) -> float:
	return clampf(float(n - 1) / float(maxi(endgame_ref - 1, 1)), 0.0, 1.0)
