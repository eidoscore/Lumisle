extends Node
## Booster (autoload T6.6) — tipe, harga koin, dan aplikasi booster ke game.
## Pre-level: mulai dengan special di board.
## In-level: hammer (hapus 1 tile), extra_swap (swap bebas), extra_moves (+5 langkah).

const COST := {
	"pre_rocket": 20,
	"pre_bomb":   30,
	"in_hammer":  20,
	"in_swap":    15,
	"in_moves":   30,
}

# Mode booster in-level aktif. Di-set oleh game_screen, dibaca oleh board_view.
var in_level_mode: String = ""


func _ready() -> void:
	set_process(false)


## Terapkan pre-level booster ke board. Kembalikan false kalau koin tidak cukup.
func apply_pre_rocket(board: Board, rng: GameRNG) -> bool:
	if not Economy.spend_coins(COST["pre_rocket"]):
		return false
	var pos := _random_empty_normal(board, rng)
	if pos.x < 0:
		Economy.add_coins(COST["pre_rocket"])  # refund koin kalau tidak ada slot
		return false
	var color := int(board.color_subset[rng.next_range(0, board.color_subset.size())])
	board.set_cell(pos.x, pos.y, TileCodes.encode(color, TileCodes.SPECIAL_ROCKET_H))
	return true


func apply_pre_bomb(board: Board, rng: GameRNG) -> bool:
	if not Economy.spend_coins(COST["pre_bomb"]):
		return false
	var pos := _random_empty_normal(board, rng)
	if pos.x < 0:
		Economy.add_coins(COST["pre_bomb"])
		return false
	var color := int(board.color_subset[rng.next_range(0, board.color_subset.size())])
	board.set_cell(pos.x, pos.y, TileCodes.encode(color, TileCodes.SPECIAL_BOMB))
	return true


## Aktifkan mode hammer in-level (board_view cek flag ini di _on_press).
func activate_hammer() -> bool:
	if not Economy.spend_coins(COST["in_hammer"]):
		return false
	in_level_mode = "hammer"
	return true


## Aktifkan mode extra_swap in-level.
func activate_extra_swap() -> bool:
	if not Economy.spend_coins(COST["in_swap"]):
		return false
	in_level_mode = "extra_swap"
	return true


## +5 langkah. Kembalikan true kalau berhasil (potong koin).
func buy_extra_moves() -> bool:
	return Economy.spend_coins(COST["in_moves"])


## Reset mode setelah dipakai.
func clear_mode() -> void:
	in_level_mode = ""


## Cari posisi tile normal (bukan special, bukan obstacle) secara acak untuk pre-booster.
func _random_empty_normal(board: Board, rng: GameRNG) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in range(board.height):
		for x in range(board.width):
			if board.is_playable(x, y) \
					and TileCodes.decode_special(board.get_cell(x, y)) == TileCodes.SPECIAL_NONE \
					and TileCodes.obstacle_type(board.get_obstacle(x, y)) == TileCodes.ObstacleType.NONE:
				candidates.append(Vector2i(x, y))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[rng.next_range(0, candidates.size())]
