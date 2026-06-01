extends SceneTree
## T5.6 — "Level Forge" pipeline headless (dok 05 §6). Single-process sequential.
## Alur: generate → solve (ensemble adaptive) → filter (band+gate kualitas) →
## kalibrasi move_limit → simpan JSON chunk + laporan distribusi.
##
## Pakai:
##   godot --headless --path . -s tools/forge.gd -- --from=101 --to=150 --seed=12345 --out=res://data/levels/generated/
## Argumen:
##   --from=N --to=M   rentang nomor level (inklusif). Default 101..120.
##   --seed=S          base seed generator. Default 777.
##   --out=DIR         folder output. Default res://data/levels/generated/
##   --max-regen=K     percobaan regenerate per level kalau gagal gate. Default 6.
##   --report-only     jangan tulis pack, cuma cetak laporan.

func _init() -> void:
	var from_n := 101
	var to_n := 120
	var base_seed := 777
	var out_dir := "res://data/levels/generated/"
	var max_regen := 6
	var report_only := false
	# Run count practical (dok 05 §6.1: batch kecil ~20-50 run; full 500 = overnight).
	# Default kecil supaya batch interaktif feasible; naikkan untuk run final semalaman.
	var start_runs := 20
	var step_runs := 20
	var max_runs := 60
	var max_iter := 4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="): from_n = int(a.substr(7))
		elif a.begins_with("--to="): to_n = int(a.substr(5))
		elif a.begins_with("--seed="): base_seed = int(a.substr(7))
		elif a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--max-regen="): max_regen = int(a.substr(12))
		elif a.begins_with("--start-runs="): start_runs = int(a.substr(13))
		elif a.begins_with("--step-runs="): step_runs = int(a.substr(12))
		elif a.begins_with("--max-runs="): max_runs = int(a.substr(11))
		elif a.begins_with("--max-iter="): max_iter = int(a.substr(11))
		elif a == "--report-only": report_only = true

	var curve := _load_curve()
	var model := DifficultyModel.new(curve)
	var generator := LevelGenerator.new(model)

	var accepted: Array = []
	var report_rows: Array = []
	var t0 := Time.get_ticks_msec()

	for n in range(from_n, to_n + 1):
		var band := model.band_for_level(n)
		var band_target := model.target_winrate_for_band(band)
		var best_level: LevelDefinition = null
		var best_stats: SolverStats = null
		var attempt := 0
		var calibrated := false

		while attempt < max_regen:
			attempt += 1
			var gen_seed := base_seed + attempt * 100003
			var lv := generator.generate(n, gen_seed)
			var v := generator.validate(lv)
			if not v["valid"]:
				continue
			var cal := EnsembleRunner.calibrate_move_limit(lv, band_target, base_seed + n, max_iter, start_runs, step_runs, max_runs)
			var stats: SolverStats = cal["stats"]
			# Simpan kandidat terbaik (terdekat ke tengah band) sbg fallback.
			if best_stats == null or _band_distance(stats.win_rate, band_target) < _band_distance(best_stats.win_rate, band_target):
				best_level = lv
				best_stats = stats
			if cal["calibrated"] and _passes_quality_gate(stats):
				best_level = lv
				best_stats = stats
				calibrated = true
				break

		if best_level == null:
			report_rows.append({"level": n, "status": "FAILED_GEN", "band": model.band_name(band)})
			print("L%d  GAGAL generate valid" % n)
			continue

		_write_metadata(best_level, best_stats, model, band)
		accepted.append(best_level)
		var status := "OK" if calibrated else "BEST_EFFORT"
		report_rows.append({
			"level": n, "status": status, "band": model.band_name(band),
			"archetype": best_level.get_meta("archetype", ""),
			"move_limit": best_level.move_limit,
			"win_rate": best_stats.win_rate, "near_miss": best_stats.near_miss_rate,
			"stuck": best_stats.stuck_rate, "runs": best_stats.total_runs,
		})
		print("L%d  %-12s wr=%.2f near=%.2f stuck=%.2f ml=%d runs=%d arch=%s" % [
			n, status, best_stats.win_rate, best_stats.near_miss_rate, best_stats.stuck_rate,
			best_level.move_limit, best_stats.total_runs, best_level.get_meta("archetype", "")])

	var elapsed := (Time.get_ticks_msec() - t0) / 1000.0
	_print_distribution(report_rows, elapsed)

	if not report_only and not accepted.is_empty():
		_write_pack(accepted, out_dir, from_n, to_n)
		_write_report(report_rows, out_dir, from_n, to_n, elapsed)
	quit()


func _load_curve() -> DifficultyCurve:
	var path := "res://data/config/difficulty_curve.tres"
	if ResourceLoader.exists(path):
		var c = ResourceLoader.load(path)
		if c is DifficultyCurve:
			return c
	push_warning("forge: difficulty_curve.tres tak ada, pakai default")
	return DifficultyCurve.new()


## Gate kualitas selain win-rate (dok 05 §5.4).
func _passes_quality_gate(s: SolverStats) -> bool:
	if s.stuck_rate > 0.20:
		return false               # terlalu membingungkan/sulit
	if s.dead_board_rate > 0.05:
		return false
	if s.easy_win_rate > 0.55:
		return false               # terlalu sering menang dgn langkah sisa banyak
	return true


func _band_distance(wr: float, band: Vector2) -> float:
	if wr < band.x:
		return band.x - wr
	if wr > band.y:
		return wr - band.y
	return 0.0


## Isi metadata solver ke meta (untuk to_dict diperluas) — disimpan di JSON via _level_to_dict.
func _write_metadata(lv: LevelDefinition, stats: SolverStats, model: DifficultyModel, band: int) -> void:
	lv.set_meta("estimated_winrate", stats.win_rate)
	lv.set_meta("near_miss_rate", stats.near_miss_rate)
	lv.set_meta("validated", stats.in_band(model.target_winrate_for_band(band)))
	lv.set_meta("difficulty_band", model.band_name(band))


## LevelDefinition → dict JSON + metadata generator/solver (superset to_dict).
func _level_to_dict(lv: LevelDefinition) -> Dictionary:
	var d := lv.to_dict()
	d["archetype"] = lv.get_meta("archetype", "")
	d["difficulty_band"] = lv.get_meta("difficulty_band", lv.get_meta("band_name", ""))
	d["generator_version"] = lv.get_meta("generator_version", LevelGenerator.GENERATOR_VERSION)
	d["estimated_winrate"] = snappedf(float(lv.get_meta("estimated_winrate", 0.0)), 0.001)
	d["near_miss_rate"] = snappedf(float(lv.get_meta("near_miss_rate", 0.0)), 0.001)
	d["validated"] = bool(lv.get_meta("validated", false))
	d["hand_crafted"] = false
	return d


func _write_pack(levels: Array, out_dir: String, from_n: int, to_n: int) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var arr: Array = []
	for lv in levels:
		arr.append(_level_to_dict(lv))
	var pack := {"schema_version": 1, "levels": arr}
	var path := out_dir + "pack_%03d_%03d.json" % [from_n, to_n]
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(JSON.stringify(pack, "  "))
	fa.close()
	print("\nWROTE PACK ", path, " (", levels.size(), " level)")


func _write_report(rows: Array, out_dir: String, from_n: int, to_n: int, elapsed: float) -> void:
	var rep := {"generated_at_unix": int(Time.get_unix_time_from_system()), "elapsed_s": elapsed, "rows": rows}
	var path := out_dir + "report_%03d_%03d.json" % [from_n, to_n]
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(JSON.stringify(rep, "  "))
	fa.close()
	print("WROTE REPORT ", path)


## Cetak distribusi ringkas per band (spot-check cepat).
func _print_distribution(rows: Array, elapsed: float) -> void:
	print("\n=== DISTRIBUSI (", rows.size(), " level, ", snappedf(elapsed, 0.1), "s) ===")
	var by_band := {}
	var ok := 0
	for r in rows:
		if not r.has("win_rate"):
			continue
		var b: String = r["band"]
		if not by_band.has(b):
			by_band[b] = []
		by_band[b].append(r["win_rate"])
		if r["status"] == "OK":
			ok += 1
	for b in by_band:
		var wrs: Array = by_band[b]
		var sum := 0.0
		for w in wrs:
			sum += w
		print("  %-18s n=%d  avg_wr=%.2f" % [b, wrs.size(), sum / maxf(wrs.size(), 1)])
	print("  status OK (lolos gate+kalibrasi): %d/%d" % [ok, rows.size()])
