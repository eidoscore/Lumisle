extends GutTest
## Fase 3 — vertical slice: LevelSet, bintang, SaveManager round-trip, GameState progress.


# --- LevelSet (T3.1) ---

func test_level_set_has_5_levels() -> void:
	assert_eq(LevelSet.count(), 5, "vertical slice = 5 level")


func test_level_lookup_by_id() -> void:
	var lv := LevelSet.get_level("1")
	assert_false(lv.is_empty(), "level 1 ada")
	assert_eq(lv["id"], "1", "id benar")
	assert_true(lv.get("tutorial", false), "level 1 = tutorial")


func test_level_unknown_id_empty() -> void:
	assert_true(LevelSet.get_level("99").is_empty(), "id tak dikenal → kosong")


func test_colors_packed() -> void:
	var lv := LevelSet.get_level("1")
	var c := LevelSet.colors_packed(lv)
	assert_eq(c.size(), 3, "level 1 pakai 3 warna")
	assert_true(c.has(1), "warna 1 ada")


func test_difficulty_curve_moves_nonincreasing() -> void:
	# Move limit tidak boleh naik seiring level (kurva makin ketat / sama).
	var prev := 999
	for i in range(LevelSet.count()):
		var ml: int = LevelSet.get_by_index(i)["move_limit"]
		assert_true(ml <= prev, "move_limit level %d (%d) <= sebelumnya (%d)" % [i, ml, prev])
		prev = ml


func test_difficulty_curve_targets_increase() -> void:
	var prev := 0
	for i in range(LevelSet.count()):
		var tgt: int = LevelSet.get_by_index(i)["objective"]["target"]
		assert_true(tgt >= prev, "target level %d (%d) >= sebelumnya (%d)" % [i, tgt, prev])
		prev = tgt


# --- Bintang (T3.1/T3.3) ---

func test_stars_three_when_many_moves_left() -> void:
	assert_eq(LevelSet.stars_for(10, 20), 3, "sisa 50% → 3 bintang")


func test_stars_two_mid() -> void:
	assert_eq(LevelSet.stars_for(4, 20), 2, "sisa 20% → 2 bintang")


func test_stars_one_low() -> void:
	assert_eq(LevelSet.stars_for(1, 20), 1, "sisa 5% → 1 bintang")


func test_stars_safe_on_zero_limit() -> void:
	assert_eq(LevelSet.stars_for(0, 0), 1, "limit 0 tidak crash, min 1")


# --- SaveManager round-trip (T3.3, minimal) ---

func test_save_load_roundtrip() -> void:
	var ok := SaveManager.save_game({"level_stars": {"1": 3, "2": 2}})
	assert_true(ok, "save berhasil")
	var data := SaveManager.load_game()
	assert_true(data.has("level_stars"), "data termuat")
	assert_eq(int(data["level_stars"]["1"]), 3, "bintang level 1 = 3")


func test_load_missing_returns_empty_safe() -> void:
	# Hapus dulu lalu load → tidak crash, kembalikan dict.
	var d := SaveManager.load_game()
	assert_eq(typeof(d), TYPE_DICTIONARY, "load selalu Dictionary")


# --- GameState progress (T3.1/T3.3) ---

func test_record_level_win_keeps_best_star() -> void:
	GameState.level_stars = {}
	GameState.record_level_win("3", 2, 5)
	GameState.record_level_win("3", 1, 2)   # lebih jelek → tidak menurunkan
	assert_eq(int(GameState.level_stars["3"]), 2, "simpan bintang TERBAIK")
	GameState.record_level_win("3", 3, 10)  # lebih bagus → naik
	assert_eq(int(GameState.level_stars["3"]), 3, "update kalau lebih baik")


func test_total_stars_sums() -> void:
	GameState.level_stars = {"1": 3, "2": 2, "3": 1}
	assert_eq(GameState.total_stars(), 6, "total bintang dijumlah")
	assert_eq(GameState.levels_cleared(), 3, "3 level cleared")
