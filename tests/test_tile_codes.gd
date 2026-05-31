extends GutTest
## T1.2 — TileCodes: encode/decode warna+special & obstacle.


func test_color_special_roundtrip_all() -> void:
	for color in range(0, 7):
		for special in [
			TileCodes.SPECIAL_NONE, TileCodes.SPECIAL_ROCKET_H,
			TileCodes.SPECIAL_ROCKET_V, TileCodes.SPECIAL_BOMB, TileCodes.SPECIAL_COLORBOMB
		]:
			var v := TileCodes.encode(color, special)
			assert_eq(TileCodes.decode_color(v), color, "decode warna (c=%d s=%d)" % [color, special])
			assert_eq(TileCodes.decode_special(v), special, "decode special (c=%d s=%d)" % [color, special])


func test_empty_is_zero() -> void:
	assert_eq(TileCodes.EMPTY, 0, "EMPTY = 0")
	assert_eq(TileCodes.encode(TileCodes.EMPTY, TileCodes.SPECIAL_NONE), 0, "encode kosong = 0")


func test_obstacle_encode_roundtrip() -> void:
	var e := TileCodes.encode_obstacle(TileCodes.ObstacleType.ICE, 2, 1)
	assert_eq(TileCodes.obstacle_type(e), TileCodes.ObstacleType.ICE, "type ice")
	assert_eq(TileCodes.obstacle_hp(e), 2, "hp 2")
	assert_eq(TileCodes.obstacle_layer_of(e), 1, "layer 1")


func test_obstacle_blocks_movement() -> void:
	assert_true(TileCodes.obstacle_blocks_movement(TileCodes.ObstacleType.CRATE), "crate menahan")
	assert_false(TileCodes.obstacle_blocks_movement(TileCodes.ObstacleType.ICE), "ice tidak menahan")
	assert_false(TileCodes.obstacle_blocks_movement(TileCodes.OBS_NONE), "none tidak menahan")
	var crate := TileCodes.encode_obstacle(TileCodes.ObstacleType.CRATE, 1, 2)
	assert_true(TileCodes.encoded_blocks_movement(crate), "encoded crate menahan")
