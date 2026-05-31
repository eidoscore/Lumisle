class_name LevelSet extends RefCounted
## T3.1 — Vertical slice: 5 level hand-crafted (hardcoded ringan).
## CATATAN SCOPE: ini SENGAJA sederhana (Dictionary statis), BUKAN LevelDefinition
## Resource + JSON loader — itu Fase 4 (T4.0/T4.1). Vertical slice cukup hardcoded.
##
## Lever kesulitan (saran review GPT-5.5: early pass-rate tinggi 95%+):
##   - jumlah warna lebih sedikit = lebih banyak match = lebih mudah (early game)
##   - move_limit lebih longgar di awal
##   - target objektif naik bertahap
## Kurva: L1 sangat mudah (tutorial, guaranteed-win) → L5 mulai menantang.

# Tiap level: id, judul, width, height, colors(subset), seed, move_limit,
# objective {type,color,target}, tutorial(bool).
const LEVELS := [
	{
		"id": "1", "title": "Percikan Pertama",
		"width": 7, "height": 8, "colors": [1, 2, 3], "seed": 1001,
		"move_limit": 25,
		"objective": {"type": "collect", "color": 1, "target": 10},
		"tutorial": true,
	},
	{
		"id": "2", "title": "Dua Warna Lagi",
		"width": 7, "height": 8, "colors": [1, 2, 3, 4], "seed": 1002,
		"move_limit": 22,
		"objective": {"type": "collect", "color": 2, "target": 16},
		"tutorial": false,
	},
	{
		"id": "3", "title": "Mulai Ramai",
		"width": 7, "height": 8, "colors": [1, 2, 3, 4], "seed": 1003,
		"move_limit": 20,
		"objective": {"type": "collect", "color": 3, "target": 20},
		"tutorial": false,
	},
	{
		"id": "4", "title": "Lima Cahaya",
		"width": 7, "height": 8, "colors": [1, 2, 3, 4, 5], "seed": 1004,
		"move_limit": 20,
		"objective": {"type": "collect", "color": 4, "target": 24},
		"tutorial": false,
	},
	{
		"id": "5", "title": "Ujian Pulau",
		"width": 7, "height": 8, "colors": [1, 2, 3, 4, 5], "seed": 1005,
		"move_limit": 18,
		"objective": {"type": "collect", "color": 1, "target": 28},
		"tutorial": false,
	},
]


## Jumlah level di slice.
static func count() -> int:
	return LEVELS.size()


## Ambil definisi level berdasarkan id (string). Kembalikan {} kalau tak ada.
static func get_level(level_id: String) -> Dictionary:
	for lv in LEVELS:
		if lv["id"] == level_id:
			return lv
	return {}


## Ambil berdasarkan index (0-based).
static func get_by_index(i: int) -> Dictionary:
	if i < 0 or i >= LEVELS.size():
		return {}
	return LEVELS[i]


## Warna subset sebagai PackedInt32Array (untuk Board.setup).
static func colors_packed(lv: Dictionary) -> PackedInt32Array:
	var arr := PackedInt32Array()
	for c in lv.get("colors", [1, 2, 3, 4, 5]):
		arr.append(int(c))
	return arr


## Hitung bintang dari sisa langkah (3 = banyak sisa, 1 = mepet). Untuk meta.
static func stars_for(moves_left: int, move_limit: int) -> int:
	if move_limit <= 0:
		return 1
	var ratio := float(moves_left) / float(move_limit)
	if ratio >= 0.40:
		return 3
	if ratio >= 0.15:
		return 2
	return 1
