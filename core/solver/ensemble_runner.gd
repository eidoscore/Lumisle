class_name EnsembleRunner extends RefCounted
## T5.5 — Jalankan ensemble 5 persona dgn ADAPTIVE run count + early-exit (dok 05 §5.3).
## Win-rate level = rata-rata ensemble (BUKAN satu strategi). Rigor statistik:
##   - mulai START_RUNS; hitung 95% CI win-rate.
##   - kalau CI TIDAK overlap pita band target → STOP (data cukup, keputusan pasti).
##   - kalau overlap → +STEP_RUNS, hitung ulang. Cap MAX_RUNS.
## (early-exit per-run ada di SolverBot.play: dead-board→reshuffle, stuck>5, langkah habis.)

const START_RUNS := 50
const STEP_RUNS := 100
const MAX_RUNS := 500


## Evaluasi satu level → SolverStats. Run dibagi RATA ke 5 persona (ensemble).
## base_seed untuk reproducibility. band_target Vector2(min,max) win-rate band.
## start_runs/step_runs/max_runs bisa di-override (default = konstanta spec dok 05).
static func evaluate_level(level: LevelDefinition, band_target: Vector2, base_seed: int = 0,
		start_runs: int = START_RUNS, step_runs: int = STEP_RUNS, max_runs: int = MAX_RUNS) -> SolverStats:
	var runs: Array = []
	var total := 0
	var personas := SolverPersonas.ALL_PERSONAS
	var target_runs := start_runs

	while total < target_runs and total < max_runs:
		# Tambah run sampai mencapai target_runs (bagi rata ke persona).
		while total < target_runs:
			var persona = personas[total % personas.size()]
			var run_seed := base_seed + total * 131 + 17
			runs.append(SolverBot.play(level, run_seed, persona))
			total += 1

		var stats := SolverStats.from_runs(runs, level.move_limit)
		# Keputusan stop berbasis CI (bukan cutoff naif).
		if stats.ci_outside_band(band_target):
			return stats          # jelas di luar band → tak perlu run lagi
		if stats.in_band(band_target) and total >= start_runs + step_runs:
			# Dalam band & sudah cukup sampel → cukup.
			return stats
		target_runs = mini(target_runs + step_runs, max_runs)

	return SolverStats.from_runs(runs, level.move_limit)


## T5.5/§5.5 — Auto-kalibrasi move_limit agar win-rate masuk pita band.
## Naik/turun langkah, uji ulang (hill-climb sederhana). Mengubah level.move_limit
## in-place + mengembalikan {"stats":SolverStats, "iterations":int, "calibrated":bool}.
## eval_runs (start,step,max) opsional → bisa dikecilkan utk tes cepat.
static func calibrate_move_limit(level: LevelDefinition, band_target: Vector2, base_seed: int = 0,
		max_iter: int = 8, start_runs: int = START_RUNS, step_runs: int = STEP_RUNS, max_runs: int = MAX_RUNS) -> Dictionary:
	var iterations := 0
	var stats := evaluate_level(level, band_target, base_seed, start_runs, step_runs, max_runs)
	while iterations < max_iter:
		iterations += 1
		if stats.in_band(band_target):
			return {"stats": stats, "iterations": iterations, "calibrated": true}
		if stats.win_rate < band_target.x:
			# Terlalu sulit → tambah langkah (lebih longgar).
			level.move_limit = mini(level.move_limit + _step_for(band_target.x - stats.win_rate), 60)
		else:
			# Terlalu mudah → kurangi langkah (lebih ketat).
			level.move_limit = maxi(level.move_limit - _step_for(stats.win_rate - band_target.y), 8)
		stats = evaluate_level(level, band_target, base_seed, start_runs, step_runs, max_runs)
	return {"stats": stats, "iterations": iterations, "calibrated": stats.in_band(band_target)}


## Besar langkah penyesuaian proporsional jarak ke band (konvergensi lebih cepat).
static func _step_for(gap: float) -> int:
	if gap > 0.25:
		return 4
	elif gap > 0.12:
		return 2
	return 1
