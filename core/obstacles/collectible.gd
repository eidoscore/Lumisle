class_name Collectible extends ObstacleBase
## T4.3c — Collectible (bring-down): item yang harus DITURUNKAN ke baris bawah.
## Beda dari statis: TIDAK pecah dari match, TIDAK menahan gravity penuh — ia JATUH
## seperti tile biasa, dan saat mencapai baris playable terbawah → "delivered" (hilang +
## emit OBSTACLE_DESTROYED data.delivered=true → objektif bring_down).
## Impl kontrak ObstacleBase. Pergerakan ditangani Gravity.apply_gravity (bring-down pass).

var layer: int = 1


func _init(p_layer: int = 1) -> void:
	layer = p_layer


func get_type() -> int:
	return TileCodes.ObstacleType.COLLECTIBLE


func blocks_movement() -> bool:
	# Collectible JATUH (tidak menahan tile lain & tidak ditahan seperti box).
	return false


func on_adjacent_match(_match_size: int) -> int:
	return 0   # tidak dipecah oleh match di sebelah


func is_destroyed() -> bool:
	return false   # "hilang" hanya saat delivered (di-handle board/gravity)


func get_layer() -> int:
	return layer
