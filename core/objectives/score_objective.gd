class_name ScoreObjective extends ObjectiveBase
## T4.2 — Objektif "capai skor N". Memakai core/score.gd (fungsi murni). Credit dari
## EVENT (TILE_CLEARED/SPECIAL_CREATED) via Score.delta_for_event (dok 14 §5/§6).
## Target & progress disimpan dalam skor ASLI (bukan ×2) untuk tampilan natural.

var target: int = 1000          # skor asli
var _score_x2: int = 0
var _cascade_index: int = 0


func _init(p_target: int = 1000) -> void:
	target = p_target


## Catatan: cascade_index naik tiap TILE_CLEARED dalam satu giliran. Reset per giliran
## tidak wajib akurat untuk objektif (akumulatif), tapi multiplier tetap diterapkan.
func credit_from_event(action) -> void:
	if action.type == MoveAction.Type.TILE_CLEARED:
		_score_x2 += Score.delta_for_event(action, _cascade_index)
		_cascade_index += 1
	elif action.type == MoveAction.Type.SPECIAL_CREATED:
		_score_x2 += Score.delta_for_event(action, _cascade_index)


func is_complete() -> bool:
	return Score.to_display(_score_x2) >= target


func get_progress() -> int:
	return mini(Score.to_display(_score_x2), target)


func get_target() -> int:
	return target
