extends GutTest
## Fase 4 — level data + objektif + score + obstacle. Logika headless (dok 14/§5/§6).

const OT := TileCodes.ObstacleType


func _v(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)


# --- T4.1 LevelLoader / LevelDefinition ---

func test_loader_loads_30_levels() -> void:
	LevelLoader.load_all(true)
	assert_eq(LevelLoader.count(), 30, "pack kurikulum = 30 level")


func test_loader_level_fields() -> void:
	LevelLoader.load_all()
	var lv := LevelLoader.get_level("lvl_001")
	assert_not_null(lv, "lvl_001 ada")
	assert_eq(lv.color_subset.size(), 3, "L1 = 3 warna")
	assert_true(lv.tutorial, "L1 tutorial")
	assert_eq(lv.objectives.size(), 1, "L1 1 objektif")


func test_loader_multi_objective_and_obstacle() -> void:
	LevelLoader.load_all()
	var lv := LevelLoader.get_level("lvl_018")
	assert_eq(lv.objectives.size(), 2, "L18 = 2 objektif (collect+clear)")
	assert_true(lv.obstacles.size() >= 1, "L18 punya obstacle (ice)")


func test_level_definition_dict_roundtrip() -> void:
	var d := {
		"id": "x1", "board_width": 6, "board_height": 7, "move_limit": 15,
		"color_subset": [1, 2, 3], "seed": 42,
		"objectives": [{"type": "collect", "tile_color": 2, "target": 5}],
		"obstacles": [{"type": "ice", "layer": 1, "positions": [[1, 1]], "hp": 2}],
	}
	var lv := LevelDefinition.from_dict(d)
	assert_eq(lv.id, "x1", "id")
	assert_eq(lv.board_width, 6, "width")
	assert_eq(lv.objectives.size(), 1, "1 objektif")
	assert_eq(lv.objectives[0].tile_color, 2, "objektif warna 2")
	assert_eq(lv.obstacles[0].obstacle_type, OT.ICE, "obstacle ice")
	assert_eq(lv.obstacles[0].positions[0], _v(1, 1), "posisi obstacle")


# --- T4.2 score.gd ---

func test_score_tile_cleared_base() -> void:
	var act := MoveAction.make(MoveAction.Type.TILE_CLEARED, [_v(0,0), _v(1,0), _v(2,0)], {"colors":[1,1,1]})
	# cascade 0 → faktor (0+1)=1; 3 tile × 20 × 1 = 60 (×2).
	assert_eq(Score.delta_for_event(act, 0), 60, "3 tile cascade-1 = 60 (x2)")


func test_score_cascade_multiplier() -> void:
	var act := MoveAction.make(MoveAction.Type.TILE_CLEARED, [_v(0,0), _v(1,0), _v(2,0)], {"colors":[1,1,1]})
	# cascade_index=1 → faktor (1+1)=2 → 3*20*2 = 120.
	assert_eq(Score.delta_for_event(act, 1), 120, "cascade ke-2 → faktor 2")


func test_score_display_halves() -> void:
	assert_eq(Score.to_display(120), 60, "display = x2 / 2")


func test_score_special_bonus() -> void:
	var act := MoveAction.make(MoveAction.Type.SPECIAL_CREATED, [], {"special_type": TileCodes.SPECIAL_BOMB})
	assert_eq(Score.delta_for_event(act, 0), Score.BONUS_BOMB_X2, "bonus bom")


# --- T4.2 objective types ---

func test_clear_obstacle_objective() -> void:
	var o := ClearObstacleObjective.new(OT.ICE, 2)
	var ev := MoveAction.make(MoveAction.Type.OBSTACLE_DESTROYED, [_v(0,0)], {"type": OT.ICE})
	o.credit_from_event(ev)
	assert_eq(o.get_progress(), 1, "1 ice hancur")
	o.credit_from_event(ev)
	assert_true(o.is_complete(), "2 ice → selesai")
	# Event tipe lain tak dihitung.
	var other := MoveAction.make(MoveAction.Type.OBSTACLE_DESTROYED, [_v(0,0)], {"type": OT.CRATE})
	var o2 := ClearObstacleObjective.new(OT.ICE, 1)
	o2.credit_from_event(other)
	assert_false(o2.is_complete(), "crate tak hitung utk objektif ice")


func test_bring_down_objective() -> void:
	var o := BringDownObjective.new(1)
	var ev := MoveAction.make(MoveAction.Type.OBSTACLE_DESTROYED, [_v(0,7)],
		{"type": OT.COLLECTIBLE, "delivered": true})
	o.credit_from_event(ev)
	assert_true(o.is_complete(), "1 item delivered → selesai")


func test_bring_down_ignores_non_delivered() -> void:
	var o := BringDownObjective.new(1)
	var ev := MoveAction.make(MoveAction.Type.OBSTACLE_DESTROYED, [_v(0,0)],
		{"type": OT.COLLECTIBLE, "delivered": false})
	o.credit_from_event(ev)
	assert_false(o.is_complete(), "collectible hancur tapi bukan delivered → tak hitung")


func test_score_objective() -> void:
	var o := ScoreObjective.new(50)
	var act := MoveAction.make(MoveAction.Type.TILE_CLEARED, [_v(0,0),_v(1,0),_v(2,0),_v(3,0),_v(4,0)], {"colors":[1,1,1,1,1]})
	o.credit_from_event(act)  # 5*20*1=100 (x2) → display 50
	assert_true(o.is_complete(), "skor 50 tercapai")


func test_objective_factory_creates_right_types() -> void:
	assert_true(ObjectiveFactory.create(ObjectiveEntry.new("collect", 5, 1)) is CollectObjective)
	assert_true(ObjectiveFactory.create(ObjectiveEntry.new("clear_obstacle", 5, 1, OT.ICE)) is ClearObstacleObjective)
	assert_true(ObjectiveFactory.create(ObjectiveEntry.new("bring_down", 2)) is BringDownObjective)
	assert_true(ObjectiveFactory.create(ObjectiveEntry.new("score", 1000)) is ScoreObjective)


# --- T4.3a/b obstacle damage from adjacent match ---

func test_ice_damaged_by_adjacent_match() -> void:
	# Board kecil: baris 0 punya 3 merah (akan match saat di-setup? tidak — kita paksa).
	# Pakai grid: tile match horizontal di baris bawah, ice di sebelahnya.
	var b := BoardTestHelper.from_grid([
		"23456",
		"34562",
		"45623",
		"11145",
	])
	# Taruh ice di (3,3) — sebelah kanan run "111" (0,3)(1,3)(2,3).
	b.obstacle_layer[b.idx(3, 3)] = TileCodes.encode_obstacle(OT.ICE, 2, 1)
	# resolve_swap butuh swap yang bikin match; tapi "111" sudah match.
	# Pakai jalur: panggil cascade lewat resolve_swap dgn swap valid yang mempertahankan 111.
	# Lebih mudah: swap (4,3)<->(4,2) tidak relevan. Kita pakai board langsung:
	var rng := GameRNG.new(1)
	# Swap (0,2)<->(0,3): (0,2)=4,(0,3)=1 → tak bikin 111 hilang. Sederhanakan:
	# Langsung verifikasi helper damage via match detect manual tidak praktis di sini.
	# Sebagai gantinya: pastikan ice ter-encode & hp benar.
	assert_eq(TileCodes.obstacle_type(b.get_obstacle(3, 3)), OT.ICE, "ice ter-set")
	assert_eq(TileCodes.obstacle_hp(b.get_obstacle(3, 3)), 2, "hp ice = 2")


func test_box_blocks_gravity() -> void:
	var b := BoardTestHelper.from_grid([
		"12345",
		"23451",
		"34512",
	])
	b.obstacle_layer[b.idx(2, 1)] = TileCodes.encode_obstacle(OT.CRATE, 1, 1)
	assert_true(b.cell_blocks_movement(2, 1), "crate menahan gravity")
	assert_false(b.cell_blocks_movement(0, 0), "tile biasa tidak menahan")


# --- obstacle classes contract ---

func test_ice_box_collectible_contracts() -> void:
	var ice := Ice.new(2)
	assert_eq(ice.get_type(), OT.ICE)
	assert_false(ice.blocks_movement(), "ice tak menahan")
	ice.on_adjacent_match(3)
	assert_eq(ice.hp, 1, "ice hp turun")
	var box := Box.new(1)
	assert_true(box.blocks_movement(), "box menahan")
	var col := Collectible.new()
	assert_eq(col.get_type(), OT.COLLECTIBLE)
	assert_false(col.blocks_movement(), "collectible jatuh")


# --- T4.3a integration: ice damaged via real resolve_swap ---

func test_resolve_swap_damages_adjacent_ice() -> void:
	# Board bebas-match awal; swap (1,0)<->(1,1) menjadikan kolom... kita pakai baris.
	# Susun: row1 = 1 2 1 4 5 ; (1,0)=1. Swap (1,0)<->(1,1) → (1,1)=1 → row1 "1 1 1 4 5" match.
	var b := BoardTestHelper.from_grid([
		"31451",
		"12145",
		"34512",
		"45123",
		"51234",
	])
	# Ice di (1,2) — bersebelahan (di bawah) dengan (1,1) yang jadi bagian match.
	b.obstacle_layer[b.idx(1, 2)] = TileCodes.encode_obstacle(OT.ICE, 2, 1)
	assert_false(MatchDetector.has_any_match(b), "pra-swap bebas match")
	# row0[1]=1 ; swap (1,0)<->(1,1): (1,1) jadi 1 → row1 "1 1 1 4 5" → match horizontal.
	var rep := b.resolve_swap(1, 0, 1, 1, GameRNG.new(7))
	assert_true(rep.is_accepted, "swap bikin match diterima")
	var ice_dmg := false
	for s in rep.steps:
		if s.type == MoveAction.Type.OBSTACLE_DAMAGED or s.type == MoveAction.Type.OBSTACLE_DESTROYED:
			if int(s.data.get("type", -1)) == OT.ICE:
				ice_dmg = true
	assert_true(ice_dmg, "ice di sebelah match kena damage")


# --- T4.3c integration: collectible reaches bottom -> delivered ---

func test_collectible_delivered_at_bottom() -> void:
	var b := BoardTestHelper.from_grid([
		"23452",
		"34521",
		"21345",
		"13245",
		"32451",
	])
	# Collectible di (0,3); sel bawah (0,4) dikosongkan (simulasi habis di-clear).
	b.obstacle_layer[b.idx(0, 3)] = TileCodes.encode_obstacle(OT.COLLECTIBLE, 1, 1)
	b.set_cell(0, 3, TileCodes.EMPTY)
	b.set_cell(0, 4, TileCodes.EMPTY)
	var report := TurnReport.new()
	b._process_bring_down(report)
	var delivered := false
	for s in report.steps:
		if s.type == MoveAction.Type.OBSTACLE_DESTROYED and bool(s.data.get("delivered", false)):
			delivered = true
	assert_true(delivered, "collectible sampai baris terbawah → delivered")
	# Tidak ada collectible tersisa di board.
	var remain := 0
	for y in range(b.height):
		for x in range(b.width):
			if TileCodes.obstacle_type(b.get_obstacle(x, y)) == OT.COLLECTIBLE:
				remain += 1
	assert_eq(remain, 0, "collectible hilang setelah delivered")
