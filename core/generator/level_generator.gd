class_name LevelGenerator extends RefCounted
## T5.2 — Generator level archetype-based (dok 05 §4). Memetakan parameter
## (DifficultyModel) + ARCHETYPE (niat desain) + seed → LevelDefinition kandidat.
## Berseed & deterministik. Validitas dasar (dok 05 §4.2): no initial match (dijamin
## Board._fill_no_initial_match), objektif mungkin, ada >=1 move, papan tak terkunci.
##
## CATATAN: generator = DRAFTING TOOL (dok 05 §4.0/§7). Output = kandidat; kualitas
## final diputuskan ensemble solver + spot-check (T5.3-T5.7).

const GENERATOR_VERSION := 1

## Archetype (niat desain, dok 05 §4.0).
enum Archetype {
	COMBO_PLAYGROUND,    # papan terbuka, ruang bikin/meledakkan special
	BLOCKER_CLEARING,    # rintangan mengarahkan; objektif = bersihkan
	BOTTLENECK,          # jalur sempit (mask) memaksa penempatan
	OBJECTIVE_RACE,      # kejar target spesifik, langkah terbatas
	SPECIAL_TUTORIAL,    # special tertentu = cara termudah menang
	HARD_NEAR_MISS,      # sengaja ketat (late game)
}

const ARCHETYPE_NAMES := {
	Archetype.COMBO_PLAYGROUND: "combo_playground",
	Archetype.BLOCKER_CLEARING: "blocker_clearing",
	Archetype.BOTTLENECK: "bottleneck",
	Archetype.OBJECTIVE_RACE: "objective_race",
	Archetype.SPECIAL_TUTORIAL: "special_tutorial",
	Archetype.HARD_NEAR_MISS: "hard_near_miss",
}

var model: DifficultyModel


func _init(p_model: DifficultyModel = null) -> void:
	model = p_model if p_model != null else DifficultyModel.new()


## Pilih archetype yang masuk akal untuk band (berseed). Dok 05 §4.0/§4.1 langkah 1.
func pick_archetype(n: int, seed_value: int) -> int:
	var band := model.band_for_level(n)
	var pool: Array = []
	match band:
		DifficultyModel.Band.FTUE:
			pool = [Archetype.OBJECTIVE_RACE, Archetype.SPECIAL_TUTORIAL, Archetype.COMBO_PLAYGROUND]
		DifficultyModel.Band.LEARNING:
			pool = [Archetype.OBJECTIVE_RACE, Archetype.BLOCKER_CLEARING, Archetype.COMBO_PLAYGROUND, Archetype.SPECIAL_TUTORIAL]
		DifficultyModel.Band.PRACTICE:
			pool = [Archetype.BLOCKER_CLEARING, Archetype.COMBO_PLAYGROUND, Archetype.BOTTLENECK, Archetype.OBJECTIVE_RACE]
		DifficultyModel.Band.CHALLENGE:
			pool = [Archetype.BOTTLENECK, Archetype.BLOCKER_CLEARING, Archetype.HARD_NEAR_MISS, Archetype.COMBO_PLAYGROUND]
		_:
			pool = [Archetype.HARD_NEAR_MISS, Archetype.BOTTLENECK, Archetype.BLOCKER_CLEARING]
	var rng := GameRNG.new(seed_value * 31 + n)
	return pool[rng.next_int(pool.size())]


## Generate satu LevelDefinition kandidat (dok 05 §4.1).
func generate(n: int, seed_value: int = 0, forced_archetype: int = -1) -> LevelDefinition:
	var params := model.params_for_level(n, seed_value)
	var archetype: int = forced_archetype if forced_archetype >= 0 else pick_archetype(n, seed_value)
	var rng := GameRNG.new(seed_value + n * 7919)

	var lv := LevelDefinition.new()
	lv.id = "lvl_%03d" % n
	lv.title = "%s %d" % [ARCHETYPE_NAMES.get(archetype, "level"), n]
	lv.hand_crafted = false
	lv.ruleset_version = 2
	lv.rng_algorithm_version = GameRNG.RNG_ALGORITHM_VERSION
	lv.seed = seed_value + n

	# 2. Tata letak / ukuran papan khas archetype.
	lv.board_width = params["board_width"]
	lv.board_height = params["board_height"]
	lv.playable_mask = _mask_for_archetype(archetype, lv.board_width, lv.board_height, rng)

	# 3. Subset warna aktif.
	lv.color_subset = _pick_color_subset(params["num_colors"], rng)

	# 4. Rintangan sesuai niat archetype.
	lv.obstacles = _obstacles_for_archetype(archetype, lv, params, rng)

	# 5. Objektif konsisten dgn archetype & rintangan.
	lv.objectives = _objectives_for_archetype(archetype, lv, params, rng)

	# 6. move_limit awal (kasar; dikalibrasi solver di T5.5/T5.6).
	lv.move_limit = _initial_move_limit(lv, params)

	# Metadata archetype/band disimpan di title untuk kini; field metadata penuh
	# (estimated_winrate dst) diisi forge (T5.6) setelah solve.
	lv.set_meta("archetype", ARCHETYPE_NAMES.get(archetype, ""))
	lv.set_meta("band_name", params["band_name"])
	lv.set_meta("generator_version", GENERATOR_VERSION)
	lv.set_meta("target_winrate", params["target_winrate"])
	return lv


# ---------------------------------------------------------------------------
# Tata letak (playable_mask) per archetype
# ---------------------------------------------------------------------------

func _mask_for_archetype(archetype: int, w: int, h: int, rng: GameRNG) -> PackedInt32Array:
	var mask := PackedInt32Array()
	mask.resize(w * h)
	for i in range(w * h):
		mask[i] = 1
	if archetype == Archetype.BOTTLENECK:
		# Jalur sempit: blok beberapa cell di baris tengah membentuk "leher botol".
		var mid := int(h / 2)
		var gap_x := 1 + rng.next_int(maxi(w - 2, 1))   # 1 lubang yang boleh dilewati
		for x in range(w):
			if x != gap_x and x != clampi(gap_x + 1, 0, w - 1):
				mask[mid * w + x] = 0
	return mask


# ---------------------------------------------------------------------------
# Warna
# ---------------------------------------------------------------------------

## Pilih subset warna aktif dari pool 1..6 (berseed, tanpa duplikat).
func _pick_color_subset(num_colors: int, rng: GameRNG) -> Array[int]:
	var pool: Array = [1, 2, 3, 4, 5, 6]
	rng.shuffle(pool)
	var k := clampi(num_colors, 3, 6)
	var out: Array[int] = []
	for i in range(k):
		out.append(int(pool[i]))
	out.sort()
	return out


# ---------------------------------------------------------------------------
# Rintangan per archetype
# ---------------------------------------------------------------------------

func _obstacles_for_archetype(archetype: int, lv: LevelDefinition, params: Dictionary, rng: GameRNG) -> Array[ObstacleEntry]:
	var out: Array[ObstacleEntry] = []
	var density: float = params["obstacle_density"]
	if density <= 0.0 and archetype != Archetype.BLOCKER_CLEARING:
		return out

	match archetype:
		Archetype.BLOCKER_CLEARING:
			# Gugus es di tengah (objektif = bersihkan).
			var positions := _cluster_positions(lv, maxi(4, int(lv.board_width)), rng)
			if not positions.is_empty():
				out.append(ObstacleEntry.new(TileCodes.ObstacleType.ICE, 1, positions, 2))
		Archetype.HARD_NEAR_MISS, Archetype.BOTTLENECK:
			# Campur ice + box, kepadatan mengikuti difficulty.
			var n_ob := int(round(density * lv.board_width * lv.board_height))
			n_ob = clampi(n_ob, 2, 12)
			var ice_pos := _scatter_positions(lv, int(n_ob * 0.6), rng)
			var box_pos := _scatter_positions(lv, n_ob - ice_pos.size(), rng, ice_pos)
			if not ice_pos.is_empty():
				out.append(ObstacleEntry.new(TileCodes.ObstacleType.ICE, 1, ice_pos, 2))
			if not box_pos.is_empty():
				out.append(ObstacleEntry.new(TileCodes.ObstacleType.CRATE, 1, box_pos, 1))
		_:
			# Archetype lain: sedikit/none (combo_playground sengaja terbuka).
			pass
	return out


## Gugus rapat (cluster) di sekitar tengah papan, n cell, hindari baris non-playable.
func _cluster_positions(lv: LevelDefinition, n: int, rng: GameRNG) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cx := int(lv.board_width / 2)
	var cy := int(lv.board_height / 2)
	var candidates: Array[Vector2i] = []
	for dy in range(-2, 2):
		for dx in range(-2, 2):
			var p := Vector2i(cx + dx, cy + dy)
			if _cell_valid_for_obstacle(lv, p):
				candidates.append(p)
	rng.shuffle(candidates)
	for i in range(mini(n, candidates.size())):
		out.append(candidates[i])
	return out


## Sebar acak n cell di papan (hindari baris terbawah & cell sudah dipakai/non-playable).
func _scatter_positions(lv: LevelDefinition, n: int, rng: GameRNG, exclude: Array[Vector2i] = []) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if n <= 0:
		return out
	var candidates: Array[Vector2i] = []
	for y in range(0, lv.board_height - 1):   # jangan di baris paling bawah (spawn/bring-down)
		for x in range(lv.board_width):
			var p := Vector2i(x, y)
			if _cell_valid_for_obstacle(lv, p) and not exclude.has(p):
				candidates.append(p)
	rng.shuffle(candidates)
	for i in range(mini(n, candidates.size())):
		out.append(candidates[i])
	return out


func _cell_valid_for_obstacle(lv: LevelDefinition, p: Vector2i) -> bool:
	if p.x < 0 or p.x >= lv.board_width or p.y < 0 or p.y >= lv.board_height:
		return false
	if lv.playable_mask.size() == lv.board_width * lv.board_height:
		if lv.playable_mask[p.y * lv.board_width + p.x] == 0:
			return false
	return true


# ---------------------------------------------------------------------------
# Objektif per archetype
# ---------------------------------------------------------------------------

func _objectives_for_archetype(archetype: int, lv: LevelDefinition, params: Dictionary, rng: GameRNG) -> Array[ObjectiveEntry]:
	var out: Array[ObjectiveEntry] = []
	var d: float = params["difficulty"]
	var color: int = lv.color_subset[rng.next_int(lv.color_subset.size())]

	match archetype:
		Archetype.BLOCKER_CLEARING:
			# Objektif = bersihkan obstacle (ice) yang ditempatkan.
			var ice_count := _count_obstacle(lv, TileCodes.ObstacleType.ICE)
			out.append(ObjectiveEntry.new("clear_obstacle", maxi(ice_count, 1), 0, TileCodes.ObstacleType.ICE))
		Archetype.OBJECTIVE_RACE:
			var target := int(round(lerpf(15.0, 35.0, d)))
			out.append(ObjectiveEntry.new("collect", target, color, 0))
		Archetype.SPECIAL_TUTORIAL:
			# Skor (dorong bikin special) + collect ringan.
			out.append(ObjectiveEntry.new("collect", int(round(lerpf(12.0, 20.0, d))), color, 0))
		Archetype.COMBO_PLAYGROUND:
			out.append(ObjectiveEntry.new("score", int(round(lerpf(1500.0, 4000.0, d))), 0, 0))
		Archetype.BOTTLENECK:
			out.append(ObjectiveEntry.new("collect", int(round(lerpf(18.0, 30.0, d))), color, 0))
		Archetype.HARD_NEAR_MISS:
			# Majemuk: collect + clear obstacle (kalau ada).
			out.append(ObjectiveEntry.new("collect", int(round(lerpf(20.0, 32.0, d))), color, 0))
			var ice_count := _count_obstacle(lv, TileCodes.ObstacleType.ICE)
			if ice_count > 0:
				out.append(ObjectiveEntry.new("clear_obstacle", ice_count, 0, TileCodes.ObstacleType.ICE))
	if out.is_empty():
		out.append(ObjectiveEntry.new("collect", 20, color, 0))
	return out


func _count_obstacle(lv: LevelDefinition, otype: int) -> int:
	var c := 0
	for o in lv.obstacles:
		if o.obstacle_type == otype:
			c += o.positions.size()
	return c


# ---------------------------------------------------------------------------
# Move limit awal (kasar)
# ---------------------------------------------------------------------------

## Estimasi kasar move_limit dari total kebutuhan objektif × rasio band (dok 05 §3.1).
## Dikalibrasi presisi oleh solver (T5.5/T5.6).
func _initial_move_limit(lv: LevelDefinition, params: Dictionary) -> int:
	var total_need := 0
	for o in lv.objectives:
		match o.objective_type:
			"collect", "clear_obstacle":
				total_need += o.target
			"bring_down":
				total_need += o.target * 6   # turun butuh banyak langkah
			"score":
				total_need += int(o.target / 100.0)   # 100 skor ≈ 1 unit kebutuhan
	var cpm: float = params["clears_per_move_est"]
	var ratio: float = params["move_ratio"]
	var ml := int(ceil(float(total_need) / maxf(cpm, 1.0) * ratio))
	return clampi(ml, 12, 40)


# ---------------------------------------------------------------------------
# Validitas dasar (dok 05 §4.2) — dipakai sebelum solver.
# ---------------------------------------------------------------------------

## Bangun Board dari level & cek: no initial match, ada >=1 move, objektif tidak
## mustahil secara prinsip (warna objektif ada di subset / obstacle ada di papan).
## Mengembalikan {"valid":bool, "reason":String, "board":Board}.
func validate(lv: LevelDefinition) -> Dictionary:
	var board := Board.new()
	board.setup(lv.board_width, lv.board_height, lv.colors_packed(),
		GameRNG.new(lv.seed), lv.playable_mask, lv.obstacles_for_setup())

	if MatchDetector.has_any_match(board):
		return {"valid": false, "reason": "initial_match", "board": board}
	if board.find_possible_moves().is_empty():
		return {"valid": false, "reason": "no_moves", "board": board}

	for o in lv.objectives:
		match o.objective_type:
			"collect":
				if not lv.color_subset.has(o.tile_color):
					return {"valid": false, "reason": "collect_color_absent", "board": board}
			"clear_obstacle":
				if _count_obstacle(lv, o.obstacle_type) < o.target:
					return {"valid": false, "reason": "clear_target_gt_present", "board": board}
	return {"valid": true, "reason": "ok", "board": board}
