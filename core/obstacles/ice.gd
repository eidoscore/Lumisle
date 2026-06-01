class_name Ice extends ObstacleBase
## T4.3b — Ice: pecah dari match di sebelah (hp), TIDAK menahan gravity.
## Impl kontrak ObstacleBase. CATATAN: damage runtime di board lewat encoding
## obstacle_layer (no instantiate per cell). Class ini = model tipe + helper/test.

var hp: int = 2
var layer: int = 1


func _init(p_hp: int = 2, p_layer: int = 1) -> void:
	hp = p_hp
	layer = p_layer


func get_type() -> int:
	return TileCodes.ObstacleType.ICE


func blocks_movement() -> bool:
	return false   # ice tidak menahan tile jatuh (dok 14 §4.1)


func on_adjacent_match(_match_size: int) -> int:
	# 1 damage per giliran-step yang menyentuh (board yang menerapkan).
	hp -= 1
	return 1


func is_destroyed() -> bool:
	return hp <= 0


func get_layer() -> int:
	return layer
