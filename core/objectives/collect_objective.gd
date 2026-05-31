class_name CollectObjective extends ObjectiveBase
## Objektif "kumpulkan N tile warna X". Impl pertama dari ObjectiveBase (T1.13).
## Credit dari EVENT TileCleared (dok 14 §5), BUKAN scan board.
## T4.2 menambah tipe objektif lain TANPA mengubah kontrak ini.

var tile_color: int = 1
var target: int = 30
var _current: int = 0


func _init(p_color: int = 1, p_target: int = 30) -> void:
	tile_color = p_color
	target = p_target


## Update dari MoveAction. Hanya TILE_CLEARED dengan warna == tile_color yang dihitung.
func credit_from_event(action) -> void:
	if action.type != MoveAction.Type.TILE_CLEARED:
		return
	var colors: Array = action.data.get("colors", [])
	for c in colors:
		if c == tile_color:
			_current += 1


func is_complete() -> bool:
	return _current >= target


func get_progress() -> int:
	return mini(_current, target)


func get_target() -> int:
	return target
