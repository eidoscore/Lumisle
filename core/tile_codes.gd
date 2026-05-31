class_name TileCodes extends RefCounted
## Encoding cell + konstanta. Acuan: docs/04-tdd-arsitektur.md §3.1, dok 14 §0.1.
## 1 int32 per cell: bit 0-5 = warna, bit 6-10 = tipe special.
## CATATAN: implementasi penuh & unit test = T1.2. Di T0.7b ini disediakan
## minimal (konstanta + ObstacleType) karena kontrak obstacle_base butuh ObstacleType.

# --- Warna (bit 0-5). 0 = kosong/blocked, 1..6 = warna pool. ---
const EMPTY := 0
const COLOR_1 := 1
const COLOR_2 := 2
const COLOR_3 := 3
const COLOR_4 := 4
const COLOR_5 := 5
const COLOR_6 := 6
const COLOR_COUNT := 6

# --- Tipe special (bit 6-10). 0 = normal. ---
const SPECIAL_NONE := 0
const SPECIAL_ROCKET_H := 1
const SPECIAL_ROCKET_V := 2
const SPECIAL_BOMB := 3
const SPECIAL_COLORBOMB := 4

# --- Bit layout ---
const _COLOR_MASK := 0x3F          # bit 0-5
const _SPECIAL_SHIFT := 6
const _SPECIAL_MASK := 0x1F        # bit 6-10 (setelah shift)

# --- Tipe obstacle (untuk obstacle_layer paralel; dok 14 §0.2). 0 = none. ---
enum ObstacleType {
	NONE = 0,
	ICE = 1,
	CRATE = 2,     # box — blocks_movement = true
	COLLECTIBLE = 3,
}


## Encode warna + special jadi satu int32. (Detail/uji penuh: T1.2.)
static func encode(color: int, special: int = SPECIAL_NONE) -> int:
	return (color & _COLOR_MASK) | ((special & _SPECIAL_MASK) << _SPECIAL_SHIFT)


static func decode_color(value: int) -> int:
	return value & _COLOR_MASK


static func decode_special(value: int) -> int:
	return (value >> _SPECIAL_SHIFT) & _SPECIAL_MASK


## Apakah tipe obstacle ini menahan gravity? (dipakai gravity.gd T1.6 tanpa instantiate)
static func obstacle_blocks_movement(obstacle_type: int) -> bool:
	return obstacle_type == ObstacleType.CRATE


# --- Obstacle layer encoding (dok 14 §0.2). 1 int32 paralel dgn cells. ---
# bit 0-7 = type_id, bit 8-15 = hp, bit 16-23 = layer.
const _OBS_TYPE_MASK := 0xFF
const _OBS_HP_SHIFT := 8
const _OBS_HP_MASK := 0xFF
const _OBS_LAYER_SHIFT := 16
const _OBS_LAYER_MASK := 0xFF
const OBS_NONE := 0


## Encode obstacle jadi int32 untuk obstacle_layer.
static func encode_obstacle(obstacle_type: int, hp: int = 1, layer: int = 1) -> int:
	return (obstacle_type & _OBS_TYPE_MASK) \
		| ((hp & _OBS_HP_MASK) << _OBS_HP_SHIFT) \
		| ((layer & _OBS_LAYER_MASK) << _OBS_LAYER_SHIFT)


static func obstacle_type(encoded: int) -> int:
	return encoded & _OBS_TYPE_MASK


static func obstacle_hp(encoded: int) -> int:
	return (encoded >> _OBS_HP_SHIFT) & _OBS_HP_MASK


static func obstacle_layer_of(encoded: int) -> int:
	return (encoded >> _OBS_LAYER_SHIFT) & _OBS_LAYER_MASK


## Apakah cell (encoded obstacle) menahan gravity? OBS_NONE = tidak.
static func encoded_blocks_movement(encoded: int) -> bool:
	return obstacle_blocks_movement(obstacle_type(encoded))
