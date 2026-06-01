class_name SolverPersonas extends RefCounted
## T5.3 — 5 persona heuristik (dok 05 §5.3). Tiap persona = cara berbeda memilih
## move valid, mensimulasikan tipe pemain berbeda. Win-rate level = RATA-RATA ensemble
## (bukan satu strategi). + noise 10-20% (human error).
##
## Tiap persona deterministik per (board, rng). Move dievaluasi di CLONE (MoveEval) →
## pakai logika game asli. random_valid = baseline; greedy_* & strategic = makin "pintar".

enum Persona {
	RANDOM_VALID,     # baseline bawah
	GREEDY_COMBO,     # prioritas cascade/special (pemain agresif)
	GREEDY_OBSTACLE,  # prioritas clear rintangan target (fokus-objektif)
	HORIZONTAL_SCAN,  # scan kiri→kanan, match pertama cukup baik (kasual)
	STRATEGIC_SETUP,  # setup match-4/5, lookahead 2-ply (berpengalaman)
}

const PERSONA_NAMES := {
	Persona.RANDOM_VALID: "random_valid",
	Persona.GREEDY_COMBO: "greedy_combo",
	Persona.GREEDY_OBSTACLE: "greedy_obstacle",
	Persona.HORIZONTAL_SCAN: "horizontal_scan",
	Persona.STRATEGIC_SETUP: "strategic_setup",
}

const ALL_PERSONAS := [
	Persona.RANDOM_VALID, Persona.GREEDY_COMBO, Persona.GREEDY_OBSTACLE,
	Persona.HORIZONTAL_SCAN, Persona.STRATEGIC_SETUP,
]

const NOISE_PROB := 0.15   # 15% peluang ambil move acak (human error, dok 05 §5.3)
const MAX_CANDIDATES := 12 # batas move yang dievaluasi/turn (perf; dok 05 §6.1). Pemain
                           # nyata pun tak memindai semua ~50 move; ini jaga solver feasible.


static func persona_name(p: int) -> String:
	return PERSONA_NAMES.get(p, "unknown")


## Pilih move {a,b} untuk persona dari daftar move valid board. rng = stream per-run
## (move pick + noise). run_seed = seed untuk evaluasi clone (refill deterministik).
## Mengembalikan Dictionary kosong {} kalau tak ada move (caller: dead-board/reshuffle).
static func choose_move(board: Board, objectives: Array, persona: int, rng: GameRNG, run_seed: int) -> Dictionary:
	var moves := board.find_possible_moves()
	if moves.is_empty():
		return {}

	# Noise: human error — sesekali ambil move acak, bukan "optimal".
	if rng.next_int(1000) < int(NOISE_PROB * 1000.0):
		return moves[rng.next_int(moves.size())]

	match persona:
		Persona.RANDOM_VALID:
			return moves[rng.next_int(moves.size())]
		Persona.HORIZONTAL_SCAN:
			return _horizontal_scan(board, moves, run_seed)
		Persona.GREEDY_COMBO:
			return _best_by_score(board, moves, run_seed, rng, _ScoreKind.COMBO, objectives)
		Persona.GREEDY_OBSTACLE:
			return _best_by_objective(board, moves, run_seed, rng, objectives)
		Persona.STRATEGIC_SETUP:
			return _strategic(board, moves, run_seed, rng, objectives)
		_:
			return moves[rng.next_int(moves.size())]


enum _ScoreKind { COMBO, OBSTACLE }


## Batasi jumlah move yang dievaluasi (perf). Kalau melebihi cap, ambil sampel
## deterministik (berseed) — bukan selalu yang pertama, supaya tak bias posisi.
static func _cap_candidates(moves: Array, rng: GameRNG) -> Array:
	if moves.size() <= MAX_CANDIDATES:
		return moves
	var pool := moves.duplicate()
	rng.shuffle(pool)
	return pool.slice(0, MAX_CANDIDATES)


## Scan baris atas→bawah, kolom kiri→kanan; ambil move PERTAMA yang "cukup baik"
## (accepted & clear >=3). Mensimulasikan mata kasual yang ambil match pertama terlihat.
static func _horizontal_scan(board: Board, moves: Array, run_seed: int) -> Dictionary:
	# Urutkan move berdasar posisi (baca kiri→kanan, atas→bawah).
	var sorted_moves := moves.duplicate()
	sorted_moves.sort_custom(func(m1, m2):
		var a1: Vector2i = m1["a"]; var a2: Vector2i = m2["a"]
		if a1.y != a2.y:
			return a1.y < a2.y
		return a1.x < a2.x)
	for mv in sorted_moves:
		var ev := MoveEval.evaluate(board, mv["a"], mv["b"], run_seed)
		if ev.accepted and ev.tiles_cleared >= 3:
			return mv
	return sorted_moves[0]

## Pilih move dengan skor tertinggi menurut prioritas (combo vs obstacle).
static func _best_by_score(board: Board, moves: Array, run_seed: int, rng: GameRNG, kind: int, objectives: Array) -> Dictionary:
	var candidates := _cap_candidates(moves, rng)
	var best: Dictionary = candidates[0]
	var best_score := -1.0
	for mv in candidates:
		var ev := MoveEval.evaluate(board, mv["a"], mv["b"], run_seed)
		var s := _score(ev, kind)
		if s > best_score:
			best_score = s
			best = mv
	return best


## Pilih move yang paling memajukan OBJEKTIF aktif (persona fokus-objektif, dok 05 §5.3).
static func _best_by_objective(board: Board, moves: Array, run_seed: int, rng: GameRNG, objectives: Array) -> Dictionary:
	var candidates := _cap_candidates(moves, rng)
	var best: Dictionary = candidates[0]
	var best_score := -2.0
	for mv in candidates:
		var ev := MoveEval.evaluate(board, mv["a"], mv["b"], run_seed)
		var s := _objective_score(ev, objectives)
		if s > best_score:
			best_score = s
			best = mv
	return best


static func _score(ev: MoveEval, kind: int) -> float:
	if not ev.accepted:
		return -1.0
	if kind == _ScoreKind.OBSTACLE:
		# Fokus rintangan: bobot besar untuk damage/destroy obstacle + bring-down.
		return ev.obstacles_destroyed * 10.0 + ev.obstacles_damaged * 4.0 \
			+ ev.collectibles_delivered * 12.0 + ev.tiles_cleared * 0.5 \
			+ ev.specials_created * 2.0
	# COMBO/agresif: bobot besar untuk special + cascade dalam + banyak clear.
	return ev.specials_created * 6.0 + ev.specials_triggered * 4.0 \
		+ ev.cascade_depth * 3.0 + ev.tiles_cleared * 1.0


## Skor seberapa besar move MEMAJUKAN objektif aktif (pemain fokus-objektif, dok 05 §5.3).
## Menangani SEMUA tipe objektif (collect/clear_obstacle/bring_down/score), bukan hanya
## obstacle — sebelumnya solver "fokus-objektif" buta terhadap objektif collect → stuck palsu.
static func _objective_score(ev: MoveEval, objectives: Array) -> float:
	if not ev.accepted:
		return -1.0
	var s := 0.0
	for o in objectives:
		if o == null or o.is_complete():
			continue
		if o is CollectObjective:
			s += float(ev.cleared_by_color.get(o.tile_color, 0)) * 10.0
		elif o is ClearObstacleObjective:
			s += ev.obstacles_destroyed * 12.0 + ev.obstacles_damaged * 5.0
		elif o is BringDownObjective:
			s += ev.collectibles_delivered * 15.0
		elif o is ScoreObjective:
			s += float(ev.score_delta_x2) * 0.02
	# Komponen kecil "kemajuan umum" (special/cascade) sebagai tie-breaker.
	s += ev.specials_created * 2.0 + ev.cascade_depth * 1.0 + ev.tiles_cleared * 0.2
	return s


## Strategic 2-ply ringan: skor = clear sekarang + 0.5 × best move SETELAHNYA
## (favor setup match-4/5 / posisi yang membuka cascade berikut). Evaluasi hanya
## top-K move (hemat) untuk kandidat 2-ply.
static func _strategic(board: Board, moves: Array, run_seed: int, rng: GameRNG, objectives: Array) -> Dictionary:
	var candidates := _cap_candidates(moves, rng)
	# Skor 1-ply dulu untuk kandidat (di-cap).
	var scored: Array = []
	for mv in candidates:
		var ev := MoveEval.evaluate(board, mv["a"], mv["b"], run_seed)
		var s1 := _score(ev, _ScoreKind.COMBO) + ev.specials_created * 8.0  # ekstra suka bikin special
		scored.append({"mv": mv, "s1": s1})
	scored.sort_custom(func(p, q): return p["s1"] > q["s1"])

	# 2-ply hanya untuk top-K (mahal: tiap evaluasi me-resolve board).
	var k := mini(3, scored.size())
	var best: Dictionary = scored[0]["mv"]
	var best_total := -INF
	for i in range(k):
		var mv = scored[i]["mv"]
		var s1: float = scored[i]["s1"]
		# Terapkan move di clone, lalu skor move terbaik berikutnya.
		var clone := board.clone()
		clone.resolve_swap(mv["a"].x, mv["a"].y, mv["b"].x, mv["b"].y, GameRNG.new(run_seed))
		var next_moves := clone.find_possible_moves()
		var best_next := 0.0
		var lim := mini(4, next_moves.size())
		for j in range(lim):
			var nev := MoveEval.evaluate(clone, next_moves[j]["a"], next_moves[j]["b"], run_seed + 1)
			best_next = maxf(best_next, _score(nev, _ScoreKind.COMBO))
		var total := s1 + 0.5 * best_next
		if total > best_total:
			best_total = total
			best = mv
	return best
