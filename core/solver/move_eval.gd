class_name MoveEval extends RefCounted
## T5.3 helper — ringkas TurnReport jadi metrik untuk SKOR move (persona solver).
## Dihitung dgn me-resolve swap di Board CLONE (tanpa memutasi board asli).
## Reuse logika game ASLI (resolve_swap) → bukan implementasi kedua (dok 05 §6.1).

var accepted: bool = false
var tiles_cleared: int = 0
var cleared_by_color: Dictionary = {}   # warna(int) → jumlah ter-clear (untuk objektif collect)
var specials_created: int = 0
var specials_triggered: int = 0
var obstacles_damaged: int = 0
var obstacles_destroyed: int = 0
var collectibles_delivered: int = 0
var cascade_depth: int = 0          # jumlah step TILE_CLEARED (kedalaman cascade)
var reshuffles: int = 0
var score_delta_x2: int = 0


## Evaluasi swap (a→b) pada CLONE board. run_seed untuk refill deterministik.
static func evaluate(board: Board, a: Vector2i, b: Vector2i, run_seed: int) -> MoveEval:
	var ev := MoveEval.new()
	var clone := board.clone()
	var report := clone.resolve_swap(a.x, a.y, b.x, b.y, GameRNG.new(run_seed))
	ev._summarize(report)
	return ev


func _summarize(report: TurnReport) -> void:
	accepted = report.is_accepted
	score_delta_x2 = report.score_delta_x2
	for step in report.steps:
		match step.type:
			MoveAction.Type.TILE_CLEARED:
				tiles_cleared += step.positions.size()
				cascade_depth += 1
				for c in step.data.get("colors", []):
					cleared_by_color[int(c)] = int(cleared_by_color.get(int(c), 0)) + 1
			MoveAction.Type.SPECIAL_CREATED:
				specials_created += 1
			MoveAction.Type.SPECIAL_TRIGGERED:
				specials_triggered += 1
			MoveAction.Type.OBSTACLE_DAMAGED:
				obstacles_damaged += 1
			MoveAction.Type.OBSTACLE_DESTROYED:
				obstacles_destroyed += 1
				if bool(step.data.get("delivered", false)):
					collectibles_delivered += 1
			MoveAction.Type.RESHUFFLE:
				reshuffles += 1
