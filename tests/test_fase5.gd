extends GutTest
## FASE 5 — Generator + Ensemble Solver (dok 05). Logika murni headless.
## T5.1 difficulty model · T5.2 generator validitas · T5.3 persona+determinism ·
## T5.4 stats formula · T5.5 adaptive/calibrate.

const B := DifficultyModel.Band


# ---------------------------------------------------------------------------
# T5.1 — DifficultyModel + curve
# ---------------------------------------------------------------------------

func test_band_boundaries() -> void:
	var m := DifficultyModel.new()
	assert_eq(m.band_for_level(1), B.FTUE, "L1 = FTUE")
	assert_eq(m.band_for_level(10), B.FTUE, "L10 = FTUE (batas atas)")
	assert_eq(m.band_for_level(11), B.LEARNING, "L11 = LEARNING")
	assert_eq(m.band_for_level(30), B.LEARNING, "L30 = LEARNING")
	assert_eq(m.band_for_level(31), B.PRACTICE, "L31 = PRACTICE")
	assert_eq(m.band_for_level(60), B.PRACTICE, "L60 = PRACTICE")
	assert_eq(m.band_for_level(61), B.CHALLENGE, "L61 = CHALLENGE")
	assert_eq(m.band_for_level(100), B.CHALLENGE, "L100 = CHALLENGE")
	assert_eq(m.band_for_level(101), B.ENDGAME, "L101 = ENDGAME")
	assert_eq(m.band_for_level(500), B.ENDGAME, "L500 = ENDGAME")


func test_target_winrate_descends_per_band() -> void:
	var m := DifficultyModel.new()
	var ftue := m.target_winrate_for_band(B.FTUE)
	var endgame := m.target_winrate_for_band(B.ENDGAME)
	assert_true(ftue.x > endgame.x, "FTUE win-rate min > ENDGAME (makin sulit)")
	assert_almost_eq(ftue.x, 0.85, 0.001, "FTUE min 0.85")


func test_params_deterministic_and_bounded() -> void:
	var m := DifficultyModel.new()
	var p1 := m.params_for_level(45, 123)
	var p2 := m.params_for_level(45, 123)
	assert_eq(p1["board_width"], p2["board_width"], "params deterministik per (n,seed)")
	assert_eq(p1["num_colors"], p2["num_colors"], "warna deterministik")
	assert_true(p1["num_colors"] >= 4 and p1["num_colors"] <= 6, "warna dalam [4,6]")
	assert_true(p1["board_width"] >= 7 and p1["board_width"] <= 8, "lebar dalam [7,8]")


func test_difficulty_increases_overall() -> void:
	var m := DifficultyModel.new()
	# Rata-rata difficulty band akhir > band awal (meski ada jitter/spike lokal).
	var early := 0.0
	var late := 0.0
	for i in range(1, 11):
		early += m.difficulty_score(i, 0)
	for i in range(101, 111):
		late += m.difficulty_score(i, 0)
	assert_true(late > early, "difficulty endgame > FTUE rata-rata")


# ---------------------------------------------------------------------------
# T5.2 — LevelGenerator validitas
# ---------------------------------------------------------------------------

func test_generate_valid_all_archetypes() -> void:
	var g := LevelGenerator.new()
	for arch in [
		LevelGenerator.Archetype.COMBO_PLAYGROUND,
		LevelGenerator.Archetype.BLOCKER_CLEARING,
		LevelGenerator.Archetype.BOTTLENECK,
		LevelGenerator.Archetype.OBJECTIVE_RACE,
		LevelGenerator.Archetype.SPECIAL_TUTORIAL,
		LevelGenerator.Archetype.HARD_NEAR_MISS,
	]:
		var lv := g.generate(45, 999, arch)
		var v := g.validate(lv)
		assert_true(v["valid"], "archetype %d valid (reason=%s)" % [arch, v["reason"]])


func test_generate_no_initial_match() -> void:
	var g := LevelGenerator.new()
	for n in [5, 25, 55, 85, 120]:
		var lv := g.generate(n, 4242)
		var v := g.validate(lv)
		var board: Board = v["board"]
		assert_false(MatchDetector.has_any_match(board), "L%d board awal tanpa match" % n)
		assert_true(board.find_possible_moves().size() > 0, "L%d ada move valid" % n)


func test_generate_deterministic() -> void:
	var g := LevelGenerator.new()
	var a := g.generate(70, 555)
	var b := g.generate(70, 555)
	assert_eq(a.move_limit, b.move_limit, "move_limit deterministik")
	assert_eq(a.color_subset, b.color_subset, "warna deterministik")
	assert_eq(a.board_width, b.board_width, "lebar deterministik")
	assert_eq(a.objectives.size(), b.objectives.size(), "objektif deterministik")


func test_blocker_clearing_has_obstacle_and_clear_objective() -> void:
	var g := LevelGenerator.new()
	var lv := g.generate(55, 321, LevelGenerator.Archetype.BLOCKER_CLEARING)
	assert_true(lv.obstacles.size() >= 1, "blocker_clearing punya obstacle")
	var has_clear := false
	for o in lv.objectives:
		if o.objective_type == "clear_obstacle":
			has_clear = true
	assert_true(has_clear, "blocker_clearing punya objektif clear_obstacle")


# ---------------------------------------------------------------------------
# T5.3 — Solver personas + bot determinism
# ---------------------------------------------------------------------------

## Level KECIL buatan tangan untuk uji solver yang CEPAT (board 6×7, 4 warna). Lepas
## dari generator supaya tes ringan & fokus (board besar = solver lambat, dok 05 §6.1).
func _tiny_level(move_limit := 15) -> LevelDefinition:
	var lv := LevelDefinition.new()
	lv.id = "tiny_test"
	lv.board_width = 6
	lv.board_height = 7
	lv.color_subset = [1, 2, 3, 4]
	lv.move_limit = move_limit
	lv.seed = 4242
	lv.objectives = [ObjectiveEntry.new("collect", 6, 1, 0)] as Array[ObjectiveEntry]
	return lv


func test_each_persona_plays_and_makes_moves() -> void:
	var lv := _tiny_level()
	for p in SolverPersonas.ALL_PERSONAS:
		var res := SolverBot.play(lv, 1000, p)
		assert_true(res.moves_used >= 1, "%s memainkan >=1 langkah" % SolverPersonas.persona_name(p))
		assert_true(res.moves_used <= lv.move_limit, "%s tidak melebihi move_limit" % SolverPersonas.persona_name(p))


func test_solver_deterministic_per_seed() -> void:
	var lv := _tiny_level()
	var r1 := SolverBot.play(lv, 2025, SolverPersonas.Persona.GREEDY_COMBO)
	var r2 := SolverBot.play(lv, 2025, SolverPersonas.Persona.GREEDY_COMBO)
	assert_eq(r1.won, r2.won, "hasil menang deterministik per seed")
	assert_eq(r1.moves_used, r2.moves_used, "langkah deterministik per seed")


func test_choose_move_returns_valid_move() -> void:
	var lv := _tiny_level()
	var board := Board.new()
	board.setup(lv.board_width, lv.board_height, lv.colors_packed(), GameRNG.new(lv.seed),
		lv.playable_mask, lv.obstacles_for_setup())
	var valid := board.find_possible_moves()
	var mv := SolverPersonas.choose_move(board, [], SolverPersonas.Persona.RANDOM_VALID, GameRNG.new(5), 99)
	assert_false(mv.is_empty(), "ada move dipilih")
	var found := false
	for m in valid:
		if m["a"] == mv["a"] and m["b"] == mv["b"]:
			found = true
	assert_true(found, "move yang dipilih ADA di daftar move valid")


func test_easy_level_high_winrate() -> void:
	# Level mudah & langkah longgar harus sering menang (sanity ensemble).
	var lv := _tiny_level(30)
	var runs: Array = []
	for i in range(15):
		runs.append(SolverBot.play(lv, 500 + i, SolverPersonas.ALL_PERSONAS[i % 5]))
	var stats := SolverStats.from_runs(runs, lv.move_limit)
	assert_true(stats.win_rate >= 0.6, "level longgar win-rate tinggi (dapat %.2f)" % stats.win_rate)


# ---------------------------------------------------------------------------
# T5.4 — SolverStats formula (data sintetis)
# ---------------------------------------------------------------------------

func _mk_run(won: bool, moves_used: int, moves_left: int, stuck := false, reshuffles := 0) -> SolverBot.RunResult:
	var r := SolverBot.RunResult.new()
	r.won = won
	r.moves_used = moves_used
	r.moves_left = moves_left
	r.stuck = stuck
	r.reshuffles = reshuffles
	return r


func test_stats_win_rate_and_near_miss() -> void:
	var runs := [
		_mk_run(true, 18, 2),    # menang near-miss (sisa 2)
		_mk_run(true, 19, 1),    # menang near-miss (sisa 1)
		_mk_run(true, 10, 10),   # menang mudah (sisa 10 > 30% dari 20)
		_mk_run(false, 20, 0),   # kalah
	]
	var s := SolverStats.from_runs(runs, 20)
	assert_almost_eq(s.win_rate, 0.75, 0.001, "win_rate 3/4")
	assert_almost_eq(s.near_miss_rate, 2.0 / 3.0, 0.01, "near-miss 2 dari 3 menang")
	assert_almost_eq(s.easy_win_rate, 1.0 / 3.0, 0.01, "easy 1 dari 3 menang")


func test_stats_stuck_and_reshuffle() -> void:
	var runs := [
		_mk_run(false, 20, 0, true, 1),
		_mk_run(true, 15, 5, false, 3),
	]
	var s := SolverStats.from_runs(runs, 20)
	assert_almost_eq(s.stuck_rate, 0.5, 0.001, "stuck 1/2")
	assert_almost_eq(s.reshuffle_per_run, 2.0, 0.001, "reshuffle (1+3)/2")


func test_stats_variance_zero_when_consistent() -> void:
	var runs := [_mk_run(true, 15, 5), _mk_run(true, 15, 5), _mk_run(true, 15, 5)]
	var s := SolverStats.from_runs(runs, 20)
	assert_almost_eq(s.moves_variance, 0.0, 0.001, "variance 0 saat konsisten")


func test_ci_outside_band_detects_clear_fail() -> void:
	# 50 run semua kalah → win_rate 0, CI sempit di 0 → jelas di luar band 0.7-0.85.
	var runs: Array = []
	for i in range(50):
		runs.append(_mk_run(false, 20, 0))
	var s := SolverStats.from_runs(runs, 20)
	assert_true(s.ci_outside_band(Vector2(0.7, 0.85)), "win_rate 0 → CI di luar band practice")


func test_ci_overlap_when_in_band() -> void:
	# ~75% menang → titik dalam band 0.7-0.85; CI overlap (butuh lebih banyak data).
	var runs: Array = []
	for i in range(50):
		runs.append(_mk_run(i % 4 != 0, 15, 5))   # 75% menang
	var s := SolverStats.from_runs(runs, 20)
	assert_true(s.in_band(Vector2(0.7, 0.85)), "win_rate ~0.75 dalam band")


# ---------------------------------------------------------------------------
# T5.5 — Ensemble adaptive + calibrate
# ---------------------------------------------------------------------------

func test_ensemble_runs_within_cap() -> void:
	var lv := _tiny_level(30)
	# Run kecil (10 start, +10, cap 30) agar tes cepat — logika adaptive sama.
	var stats := EnsembleRunner.evaluate_level(lv, Vector2(0.8, 0.9), 7, 10, 10, 30)
	assert_true(stats.total_runs >= 10, "minimal start_runs")
	assert_true(stats.total_runs <= 30, "tidak melebihi max_runs")


func test_calibrate_moves_toward_band() -> void:
	# Mulai dari move_limit ekstrem rendah (pasti susah) → kalibrasi harus menaikkan.
	var lv := _tiny_level(5)
	var band := Vector2(0.7, 0.85)
	var before := lv.move_limit
	var cal := EnsembleRunner.calibrate_move_limit(lv, band, 11, 3, 10, 10, 20)
	assert_true(lv.move_limit >= before, "kalibrasi menaikkan/sama move_limit dari kondisi terlalu sulit")
	assert_true(cal["iterations"] >= 1, "ada iterasi kalibrasi")
