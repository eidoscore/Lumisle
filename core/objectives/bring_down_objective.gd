class_name BringDownObjective extends ObjectiveBase
## T4.2 — Objektif "turunkan N item ke baris bawah". Credit dari EVENT ItemDelivered
## (MoveAction.Type.OBSTACLE_DESTROYED dgn flag delivered, atau event khusus).
## Acuan dok 05 §2 ("bring_down"). Collectible (T4.3c) memancarkan event saat sampai bawah.

var target: int = 1
var _current: int = 0


func _init(p_target: int = 1) -> void:
	target = p_target


## Collectible yang sampai baris bawah → OBSTACLE_DESTROYED dgn data.delivered=true.
func credit_from_event(action) -> void:
	if action.type != MoveAction.Type.OBSTACLE_DESTROYED:
		return
	if int(action.data.get("type", -1)) == TileCodes.ObstacleType.COLLECTIBLE \
			and bool(action.data.get("delivered", false)):
		_current += 1


func is_complete() -> bool:
	return _current >= target


func get_progress() -> int:
	return mini(_current, target)


func get_target() -> int:
	return target
