class_name SolverBot extends RefCounted
## T5.3 — Simulasi penuh memainkan satu level (dok 05 §5.2). Pakai Board + objektif
## + resolve_swap yang SAMA dengan game (BUKAN implementasi kedua, dok 05 §6.1).
## Deterministik per (level, run_seed, persona). Early-exit (T5.5, dok 05 §5.3).
##
## Objektif di-credit dari EVENT report.steps (sama persis seperti GameScreen) → win =
## semua objektif selesai sebelum langkah habis.

const STUCK_LIMIT := 5   # moves_since_last_objective_progress > 5 → stuck (dok 05 §5.4)


## Hasil satu run.
class RunResult extends RefCounted:
	var won: bool = false
	var moves_used: int = 0
	var moves_left: int = 0
	var stuck: bool = false                    # berakhir karena stuck objective-focused
	var dead_board: bool = false               # tak ada move & reshuffle tak menolong
	var reshuffles: int = 0
	var specials_created: int = 0
	var max_moves_without_progress: int = 0


## Mainkan level. p_level = LevelDefinition; run_seed = variasi run; persona = SolverPersonas.Persona.
static func play(level: LevelDefinition, run_seed: int, persona: int) -> RunResult:
	var res := RunResult.new()

	# Board awal: seed level (papan awal SAMA tiap run = pemain lihat board sama).
	# Variasi antar-run datang dari refill (run_seed) + pilihan move persona (rng).
	var board := Board.new()
	board.setup(level.board_width, level.board_height, level.colors_packed(),
		GameRNG.new(level.seed), level.playable_mask, level.obstacles_for_setup())

	# Objektif instance (kontrak sama dgn game).
	var objectives: Array = []
	for e in level.objectives:
		objectives.append(ObjectiveFactory.create(e))

	var refill_rng := GameRNG.new(run_seed * 2 + 1)        # stream refill resolve
	var pick_rng := GameRNG.new(run_seed * 7919 + persona) # stream pilih move + noise

	var moves_left := level.move_limit
	var since_progress := 0
	var last_progress := _total_progress(objectives)

	while moves_left > 0:
		if _all_complete(objectives):
			res.won = true
			break

		var mv := SolverPersonas.choose_move(board, objectives, persona, pick_rng, refill_rng.next_int(1 << 30))
		if mv.is_empty():
			# Tak ada move valid → reshuffle (gratis), coba lagi sekali.
			board.reshuffle(refill_rng)
			res.reshuffles += 1
			mv = SolverPersonas.choose_move(board, objectives, persona, pick_rng, refill_rng.next_int(1 << 30))
			if mv.is_empty():
				res.dead_board = true
				break

		var a: Vector2i = mv["a"]
		var b: Vector2i = mv["b"]
		var report := board.resolve_swap(a.x, a.y, b.x, b.y, refill_rng)
		if not report.is_accepted:
			# Move yang dipilih ternyata tak diterima (jarang: board berubah) — jangan
			# makan langkah; ambil lagi. Tapi cegah loop tak hingga via counter.
			since_progress += 1
			if since_progress > STUCK_LIMIT * 3:
				res.stuck = true
				break
			continue

		moves_left -= report.move_cost

		# Credit objektif dari event (persis GameScreen).
		for step in report.steps:
			for o in objectives:
				o.credit_from_event(step)
			if step.type == MoveAction.Type.SPECIAL_CREATED:
				res.specials_created += 1
			elif step.type == MoveAction.Type.RESHUFFLE:
				res.reshuffles += 1

		# Stuck objective-focused (dok 05 §5.4): progres objektif tidak naik >5 langkah.
		var prog := _total_progress(objectives)
		if prog > last_progress:
			last_progress = prog
			since_progress = 0
		else:
			since_progress += 1
		res.max_moves_without_progress = maxi(res.max_moves_without_progress, since_progress)
		if since_progress > STUCK_LIMIT and not _all_complete(objectives):
			res.stuck = true
			break

	if _all_complete(objectives):
		res.won = true
	res.moves_left = maxi(moves_left, 0)
	res.moves_used = level.move_limit - res.moves_left
	return res


static func _all_complete(objectives: Array) -> bool:
	if objectives.is_empty():
		return false
	for o in objectives:
		if not o.is_complete():
			return false
	return true


## Jumlah progres semua objektif (untuk deteksi stuck).
static func _total_progress(objectives: Array) -> int:
	var t := 0
	for o in objectives:
		t += o.get_progress()
	return t
