class_name ClearObstacleObjective extends ObjectiveBase
## T4.2 — Objektif "hancurkan N obstacle tipe X". Credit dari EVENT OBSTACLE_DESTROYED
## (dok 14 §5), BUKAN scan board. Acuan dok 05 §2 ("clear_obstacle").

var obstacle_type: int = TileCodes.ObstacleType.ICE
var target: int = 10
var _current: int = 0


func _init(p_obstacle: int = TileCodes.ObstacleType.ICE, p_target: int = 10) -> void:
	obstacle_type = p_obstacle
	target = p_target


func credit_from_event(action) -> void:
	if action.type != MoveAction.Type.OBSTACLE_DESTROYED:
		return
	if int(action.data.get("type", -1)) == obstacle_type:
		_current += 1


func is_complete() -> bool:
	return _current >= target


func get_progress() -> int:
	return mini(_current, target)


func get_target() -> int:
	return target
