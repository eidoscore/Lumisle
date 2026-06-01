class_name DifficultyModel extends RefCounted
## T5.1 — Pemetaan nomor level → parameter generator (dok 05 §3). Disetir oleh
## DifficultyCurve (knob tunable). Berseed: dua level berdekatan tak identik tapi
## reproducible. Output dipakai LevelGenerator (T5.2).

## 5 band konsisten dengan dok 05 §2.
enum Band { FTUE, LEARNING, PRACTICE, CHALLENGE, ENDGAME }

const BAND_NAMES := {
	Band.FTUE: "FTUE_1_10",
	Band.LEARNING: "LEARNING_11_30",
	Band.PRACTICE: "PRACTICE_31_60",
	Band.CHALLENGE: "CHALLENGE_61_100",
	Band.ENDGAME: "ENDGAME_101_PLUS",
}

var curve: DifficultyCurve


func _init(p_curve: DifficultyCurve = null) -> void:
	curve = p_curve if p_curve != null else DifficultyCurve.new()


## Band untuk nomor level (1-based).
func band_for_level(n: int) -> int:
	if n <= curve.band_ftue_max:
		return Band.FTUE
	elif n <= curve.band_learning_max:
		return Band.LEARNING
	elif n <= curve.band_practice_max:
		return Band.PRACTICE
	elif n <= curve.band_challenge_max:
		return Band.CHALLENGE
	return Band.ENDGAME


func band_name(band: int) -> String:
	return BAND_NAMES.get(band, "UNKNOWN")


## Pita target win-rate (Vector2 min,max) untuk band.
func target_winrate_for_band(band: int) -> Vector2:
	match band:
		Band.FTUE: return curve.winrate_ftue
		Band.LEARNING: return curve.winrate_learning
		Band.PRACTICE: return curve.winrate_practice
		Band.CHALLENGE: return curve.winrate_challenge
		_: return curve.winrate_endgame


## Skor kesulitan 0..1 untuk level n (dengan spike & relief berpola + jitter berseed).
func difficulty_score(n: int, seed_value: int = 0) -> float:
	var base := curve.progress_for_level(n)
	# Spike sesekali + napas sesudahnya (ritme, dok 05 §3.2).
	var phase := n % maxi(curve.spike_every, 1)
	if phase == 0:
		base += curve.spike_boost
	elif phase == 1:
		base -= curve.relief_after_spike
	# Jitter berseed deterministik (tak pakai global rng).
	var jitter := _hash01(n * 2654435761 + seed_value) * 2.0 - 1.0
	base += jitter * curve.jitter_strength
	return clampf(base, 0.0, 1.0)


## Parameter level lengkap → Dictionary (dikonsumsi LevelGenerator).
## Semua field deterministik dari (n, seed).
func params_for_level(n: int, seed_value: int = 0) -> Dictionary:
	var band := band_for_level(n)
	var d := difficulty_score(n, seed_value)

	var board_w := _lerp_int(curve.board_w_min, curve.board_w_max, d)
	var board_h := _lerp_int(curve.board_h_min, curve.board_h_max, d)
	var num_colors := _lerp_int(curve.colors_min, curve.colors_max, d)
	var move_ratio := lerpf(curve.move_ratio_easy, curve.move_ratio_hard, d)
	# Kepadatan rintangan: 0 di FTUE, naik ke obstacle_density_max di endgame.
	var obstacle_density := 0.0
	if band >= Band.PRACTICE:
		obstacle_density = curve.obstacle_density_max * d

	return {
		"level": n,
		"band": band,
		"band_name": band_name(band),
		"difficulty": d,
		"board_width": board_w,
		"board_height": board_h,
		"num_colors": num_colors,
		"move_ratio": move_ratio,
		"clears_per_move_est": curve.clears_per_move_est,
		"obstacle_density": obstacle_density,
		"target_winrate": target_winrate_for_band(band),
	}


# --- Helper deterministik ---

## Hash → float 0..1 (deterministik, tanpa RNG global). Untuk jitter berseed.
func _hash01(v: int) -> float:
	var h := hash(v)
	return float(absi(h) % 100000) / 100000.0


func _lerp_int(a: int, b: int, t: float) -> int:
	return int(round(lerpf(float(a), float(b), clampf(t, 0.0, 1.0))))
