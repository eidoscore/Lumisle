class_name Box extends ObstacleBase
## T4.3b — Box/Crate: MENAHAN gravity (tile tidak lewat), pecah dari match di sebelah.
## Impl kontrak ObstacleBase. Damage runtime di board lewat encoding obstacle_layer.

var hp: int = 1
var layer: int = 1


func _init(p_hp: int = 1, p_layer: int = 1) -> void:
	hp = p_hp
	layer = p_layer


func get_type() -> int:
	return TileCodes.ObstacleType.CRATE


func blocks_movement() -> bool:
	return true   # crate menahan jatuh (dok 14 §4.1)


func on_adjacent_match(_match_size: int) -> int:
	hp -= 1
	return 1


func is_destroyed() -> bool:
	return hp <= 0


func get_layer() -> int:
	return layer
