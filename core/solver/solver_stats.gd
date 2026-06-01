class_name SolverStats extends RefCounted
## T5.4 — Metrik kualitas level dari kumpulan RunResult (dok 05 §5.4). Formula:
##   win_rate          = wins / total_runs
##   near_miss_rate    = (menang sisa langkah 1-3) / wins   (target ADA, jangan 0)
##   moves_variance    = variance(moves_used pada run MENANG)
##   stuck_rate        = run stuck (progress objektif mandek >5) / total_runs
##   reshuffle_per_run = total_reshuffle / total_runs
##   easy_win_rate     = menang dgn >30% langkah tersisa / wins (terlalu mudah kalau tinggi)
## + 95% confidence interval win-rate (Wald) untuk adaptive run count (T5.5).

const NEAR_MISS_MOVES := 3       # sisa langkah 1-3 = "hampir kalah" (seru)
const EASY_REMAIN_FRAC := 0.30   # menang dgn >30% langkah tersisa = mudah

var total_runs: int = 0
var wins: int = 0
var win_rate: float = 0.0
var near_miss_rate: float = 0.0
var moves_variance: float = 0.0
var moves_mean_win: float = 0.0
var stuck_rate: float = 0.0
var reshuffle_per_run: float = 0.0
var easy_win_rate: float = 0.0
var dead_board_rate: float = 0.0


## Agregasi dari Array[SolverBot.RunResult]. move_limit untuk hitung near-miss/easy.
static func from_runs(runs: Array, move_limit: int) -> SolverStats:
	var s := SolverStats.new()
	s.total_runs = runs.size()
	if s.total_runs == 0:
		return s
	var win_moves: Array = []
	var near := 0
	var easy := 0
	var stuck := 0
	var dead := 0
	var reshuffle_total := 0
	for r in runs:
		reshuffle_total += r.reshuffles
		if r.stuck:
			stuck += 1
		if r.dead_board:
			dead += 1
		if r.won:
			s.wins += 1
			win_moves.append(r.moves_used)
			if r.moves_left >= 1 and r.moves_left <= NEAR_MISS_MOVES:
				near += 1
			if float(r.moves_left) > EASY_REMAIN_FRAC * float(maxi(move_limit, 1)):
				easy += 1
	s.win_rate = float(s.wins) / float(s.total_runs)
	s.near_miss_rate = float(near) / float(s.wins) if s.wins > 0 else 0.0
	s.easy_win_rate = float(easy) / float(s.wins) if s.wins > 0 else 0.0
	s.stuck_rate = float(stuck) / float(s.total_runs)
	s.dead_board_rate = float(dead) / float(s.total_runs)
	s.reshuffle_per_run = float(reshuffle_total) / float(s.total_runs)
	s.moves_mean_win = _mean(win_moves)
	s.moves_variance = _variance(win_moves, s.moves_mean_win)
	return s


## 95% CI win-rate (Wald). Mengembalikan Vector2(low, high) ter-clamp [0,1].
## Dipakai T5.5: kalau CI TIDAK overlap pita band → data cukup, stop.
func winrate_ci95() -> Vector2:
	if total_runs == 0:
		return Vector2(0.0, 1.0)
	var p := win_rate
	var margin := 1.96 * sqrt(maxf(p * (1.0 - p), 0.0) / float(total_runs))
	return Vector2(clampf(p - margin, 0.0, 1.0), clampf(p + margin, 0.0, 1.0))


## Apakah CI win-rate JELAS di luar pita target (tidak overlap)? → keputusan stop pasti.
func ci_outside_band(band_target: Vector2) -> bool:
	var ci := winrate_ci95()
	# Tidak overlap kalau CI seluruhnya di bawah min ATAU seluruhnya di atas max.
	return ci.y < band_target.x or ci.x > band_target.y


## Apakah win-rate (titik) masuk pita band?
func in_band(band_target: Vector2) -> bool:
	return win_rate >= band_target.x and win_rate <= band_target.y


func to_dict() -> Dictionary:
	return {
		"total_runs": total_runs,
		"wins": wins,
		"win_rate": snappedf(win_rate, 0.001),
		"near_miss_rate": snappedf(near_miss_rate, 0.001),
		"moves_variance": snappedf(moves_variance, 0.01),
		"moves_mean_win": snappedf(moves_mean_win, 0.01),
		"stuck_rate": snappedf(stuck_rate, 0.001),
		"easy_win_rate": snappedf(easy_win_rate, 0.001),
		"reshuffle_per_run": snappedf(reshuffle_per_run, 0.001),
		"dead_board_rate": snappedf(dead_board_rate, 0.001),
	}


static func _mean(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var sum := 0.0
	for v in arr:
		sum += float(v)
	return sum / float(arr.size())


static func _variance(arr: Array, mean: float) -> float:
	if arr.size() < 2:
		return 0.0
	var acc := 0.0
	for v in arr:
		var d := float(v) - mean
		acc += d * d
	return acc / float(arr.size())
