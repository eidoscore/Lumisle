class_name ObstacleBase extends RefCounted
## Kontrak abstract untuk semua rintangan. T0.7b — interface ada SEBELUM gravity (T1.6)
## & impl konkret (Fase 4) butuh. Acuan: docs/04-tdd-arsitektur.md §3.4, dok 14 §0.2.
## Semua method = abstract (push_error). Implementasi konkret: ice.gd/box.gd/collectible.gd (Fase 4).


## Tipe obstacle (TileCodes.ObstacleType). 0 = none.
func get_type() -> int:
	push_error("ObstacleBase.get_type() abstract — override di subclass")
	return TileCodes.ObstacleType.NONE


## Apakah menahan jatuhnya tile (gravity)? box=true, ice=false.
func blocks_movement() -> bool:
	push_error("ObstacleBase.blocks_movement() abstract — override di subclass")
	return false


## Dipanggil saat ada match di sel yang berdekatan. Kembalikan damage yang diterima.
func on_adjacent_match(_match_size: int) -> int:
	push_error("ObstacleBase.on_adjacent_match() abstract — override di subclass")
	return 0


## Sudah hancur (hp habis)?
func is_destroyed() -> bool:
	push_error("ObstacleBase.is_destroyed() abstract — override di subclass")
	return false


## Layer Z-order (dok 14 §0.2). V1: maks 1 obstacle/cell.
func get_layer() -> int:
	push_error("ObstacleBase.get_layer() abstract — override di subclass")
	return 0
