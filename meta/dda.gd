extends Node
## DDA — Dynamic Difficulty Adjustment (autoload, T7.5).
## Kalah ≥3× di level yang sama → bonus moves halus (+1 atau +2).
## Persist via SaveManager merge pattern. Tidak visible ke pemain.
## GDD §8, dok 05 §5.4.

## Berapa tambahan langkah per tier kekalahan:
## streak 3 → +1, streak 5+ → +2.
const BONUS_MOVES_TIER_1 := 1   # streak 3-4
const BONUS_MOVES_TIER_2 := 2   # streak 5+

var _loss_streaks: Dictionary = {}   # {level_id: String → count: int}


func _ready() -> void:
	set_process(false)
	_load()


## Catat kekalahan di level ini. Kembalikan loss streak terbaru.
func record_loss(level_id: String) -> int:
	var current := int(_loss_streaks.get(level_id, 0))
	current += 1
	_loss_streaks[level_id] = current
	_save()
	return current


## Catat kemenangan — reset loss streak untuk level ini.
func record_win(level_id: String) -> void:
	if _loss_streaks.has(level_id):
		_loss_streaks.erase(level_id)
		_save()


## Bonus langkah untuk level ini berdasarkan loss streak.
## 0 = tidak ada bonus (streak < 3).
func get_bonus_moves(level_id: String) -> int:
	var streak := int(_loss_streaks.get(level_id, 0))
	if streak >= 5:
		return BONUS_MOVES_TIER_2
	if streak >= 3:
		return BONUS_MOVES_TIER_1
	return 0


## Loss streak saat ini untuk level.
func get_streak(level_id: String) -> int:
	return int(_loss_streaks.get(level_id, 0))


func _save() -> void:
	var data := SaveManager.load_game()
	var raw: Dictionary = {}
	for k in _loss_streaks:
		raw[str(k)] = int(_loss_streaks[k])
	data["dda_loss_streaks"] = raw
	SaveManager.save_game(data)


func _load() -> void:
	var data := SaveManager.load_game()
	_loss_streaks.clear()
	var raw: Variant = data.get("dda_loss_streaks", {})
	if typeof(raw) == TYPE_DICTIONARY:
		for k in raw:
			_loss_streaks[str(k)] = int(raw[k])
