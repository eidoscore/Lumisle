extends SceneTree
## T4.5 — Hasilkan pack kurikulum 30 level (JSON) sesuai schema dok 05 §2.
## Kurikulum (saran review GPT-5.5: early pass-rate tinggi, konsep bertahap):
##   L1-3   : 3 warna, collect, langkah longgar (tutorial/sangat mudah)
##   L4-8   : 4 warna, collect, target naik
##   L9-14  : 4-5 warna, collect, langkah lebih mepet (perkenalan special alami)
##   L15-20 : 5 warna + ICE (clear_obstacle diperkenalkan)
##   L21-25 : 5 warna + ICE/BOX campur, objektif majemuk (collect + clear_obstacle)
##   L26-30 : 5 warna + COLLECTIBLE (bring_down) + score, paling menantang
## Semua hand_crafted=true, ruleset_version=2.

func _init() -> void:
	var levels: Array = []
	for n in range(1, 31):
		levels.append(_make_level(n))
	var pack := {"schema_version": 1, "levels": levels}
	var dir := "res://data/levels/handcrafted/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir + "pack_001_030.json"
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(JSON.stringify(pack, "  "))
	fa.close()
	print("WROTE ", path, " levels=", levels.size())
	quit()


func _make_level(n: int) -> Dictionary:
	var colors := _colors_for(n)
	var move_limit := _moves_for(n)
	var objectives := _objectives_for(n)
	var obstacles := _obstacles_for(n)
	return {
		"id": "lvl_%03d" % n,
		"title": _title_for(n),
		"board_width": 7,
		"board_height": 8,
		"color_subset": colors,
		"num_colors": colors.size(),
		"move_limit": move_limit,
		"objectives": objectives,
		"obstacles": obstacles,
		"seed": 1000 + n,
		"tutorial": n <= 2,
		"hand_crafted": true,
		"ruleset_version": 2,
		"rng_algorithm_version": 1,
	}


func _colors_for(n: int) -> Array:
	if n <= 3:
		return [1, 2, 3]
	elif n <= 8:
		return [1, 2, 3, 4]
	elif n <= 14:
		return [1, 2, 3, 4, 5] if n > 11 else [1, 2, 3, 4]
	return [1, 2, 3, 4, 5]


func _moves_for(n: int) -> int:
	# Longgar di awal, makin mepet. Tetap "fair" (tak pernah < 16).
	if n <= 3:
		return 28
	elif n <= 8:
		return 24
	elif n <= 14:
		return 22
	elif n <= 20:
		return 20
	elif n <= 25:
		return 19
	return 18


func _objectives_for(n: int) -> Array:
	var color := ((n - 1) % 4) + 1   # rotasi warna objektif 1-4
	if n <= 14:
		# collect murni, target naik bertahap.
		var target := 8 + n            # L1=9 ... L14=22
		return [{"type": "collect", "tile_color": color, "target": target}]
	elif n <= 20:
		# collect + clear ice.
		return [
			{"type": "collect", "tile_color": color, "target": 18},
			{"type": "clear_obstacle", "obstacle_type": TileCodes.ObstacleType.ICE, "target": 4 + (n - 15)},
		]
	elif n <= 25:
		# collect + clear obstacle (campur ice/box) majemuk.
		return [
			{"type": "collect", "tile_color": color, "target": 20},
			{"type": "clear_obstacle", "obstacle_type": TileCodes.ObstacleType.ICE, "target": 6},
		]
	# L26-30: bring_down + score.
	return [
		{"type": "bring_down", "target": 1 + int((n - 26) / 2)},
		{"type": "score", "target": 1500 + (n - 26) * 400},
	]


func _obstacles_for(n: int) -> Array:
	if n <= 14:
		return []
	elif n <= 20:
		# Beberapa ice di tengah.
		return [{"type": "ice", "layer": 1, "positions": [[3, 3], [3, 4], [4, 3], [4, 4]], "hp": 2}]
	elif n <= 25:
		# Ice + box.
		return [
			{"type": "ice", "layer": 1, "positions": [[2, 3], [4, 3]], "hp": 2},
			{"type": "crate", "layer": 1, "positions": [[3, 5]], "hp": 1},
		]
	# L26-30: collectible di baris atas (harus diturunkan) + sedikit ice.
	return [
		{"type": "collectible", "layer": 1, "positions": [[1, 0], [5, 0]], "hp": 1},
		{"type": "ice", "layer": 1, "positions": [[3, 2]], "hp": 1},
	]


func _title_for(n: int) -> String:
	if n <= 3: return "Percikan %d" % n
	elif n <= 8: return "Warna Bertambah %d" % n
	elif n <= 14: return "Latihan %d" % n
	elif n <= 20: return "Es Pertama %d" % n
	elif n <= 25: return "Rintangan %d" % n
	return "Ujian Pulau %d" % n
