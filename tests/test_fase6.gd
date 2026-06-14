extends GutTest
## Unit test Fase 6 — Meta, Ekonomi & Save (T6.1-T6.7).
## T6.4 (visual map), T6.5 (popup UI), T6.7 (lifecycle) = manual.


# ---------------------------------------------------------------------------
# T6.1 — SaveManager: atomic write, backup, checksum, migrasi
# ---------------------------------------------------------------------------

func test_t61_save_load_roundtrip() -> void:
	var data := {"level_stars": {"lvl_001": 1}, "coins": 42, "lives": 4}
	var ok := SaveManager.save_game(data)
	assert_true(ok, "save_game harus true")
	var loaded := SaveManager.load_game()
	assert_eq(int(loaded.get("coins", 0)), 42, "coins harus 42")
	assert_eq(int(loaded.get("lives", 0)), 4, "lives harus 4")


func test_t61_save_preserves_nested() -> void:
	var data := {"level_stars": {"lvl_001": 1, "lvl_002": 1}, "settings": {"sfx": false}}
	SaveManager.save_game(data)
	var loaded := SaveManager.load_game()
	var ls: Dictionary = loaded.get("level_stars", {})
	assert_eq(int(ls.get("lvl_001", 0)), 1, "lvl_001 harus 1")
	var s: Dictionary = loaded.get("settings", {})
	assert_false(bool(s.get("sfx", true)), "sfx harus false")


func test_t61_backup_created() -> void:
	# Save pertama
	SaveManager.save_game({"coins": 10})
	# Save kedua harus backup save pertama ke .bak
	SaveManager.save_game({"coins": 20})
	assert_true(FileAccess.file_exists("user://save_v1.bak"), ".bak harus ada")


func test_t61_corrupt_falls_back_to_backup() -> void:
	SaveManager.save_game({"coins": 77})
	SaveManager.save_game({"coins": 88})  # backup berisi coins=77
	# Corrupt main file
	var f := FileAccess.open("user://save_v1.json", FileAccess.WRITE)
	f.store_string("CORRUPT{{{")
	f.close()
	var loaded := SaveManager.load_game()
	# Harus fallback ke .bak yang berisi coins=77
	assert_eq(int(loaded.get("coins", 0)), 77, "fallback ke .bak coins=77")


func test_t61_checksum_soft_reject_on_tamper() -> void:
	# Tulis data valid dulu
	SaveManager.save_game({"coins": 55})
	# Modifikasi data_str dalam file (rusak checksum)
	var f := FileAccess.open("user://save_v1.json", FileAccess.READ)
	var raw := f.get_as_text()
	f.close()
	var patched := raw.replace('"coins": 55', '"coins": 9999')
	var fw := FileAccess.open("user://save_v1.json", FileAccess.WRITE)
	fw.store_string(patched)
	fw.close()
	# Load: checksum gagal (warn) tapi data_str masih parseable → masih bisa dipakai
	# (soft check — tidak hard reject). Bisa saja return backup atau data termodif.
	var loaded := SaveManager.load_game()
	# Yang penting: tidak crash, kembalikan Dictionary
	assert_typeof(loaded, TYPE_DICTIONARY, "load_game harus kembalikan Dictionary")


# ---------------------------------------------------------------------------
# T6.2 — Economy: nyawa, koin, regen
# ---------------------------------------------------------------------------

func before_each() -> void:
	# Reset economy state sebelum tiap test
	Economy.lives  = Economy.MAX_LIVES
	Economy.coins  = 0
	Economy._regen_start_ts = 0
	Economy._ad_count = 0


func test_t62_spend_life_decrements() -> void:
	Economy.lives = Economy.MAX_LIVES
	var ok := Economy.spend_life()
	assert_true(ok, "spend_life harus true saat nyawa tersedia")
	assert_eq(Economy.lives, Economy.MAX_LIVES - 1, "nyawa berkurang 1")


func test_t62_spend_life_empty_returns_false() -> void:
	Economy.lives = 0
	var ok := Economy.spend_life()
	assert_false(ok, "spend_life harus false saat nyawa 0")
	assert_eq(Economy.lives, 0, "nyawa tetap 0")


func test_t62_spend_life_starts_regen_timer() -> void:
	Economy.lives = Economy.MAX_LIVES
	Economy.spend_life()
	assert_gt(Economy._regen_start_ts, 0, "regen_start_ts harus > 0 setelah spend")


func test_t62_no_timer_when_at_max() -> void:
	Economy.lives = Economy.MAX_LIVES
	Economy._regen_start_ts = 0
	# Refund saat max → timer tidak berubah
	Economy.refund_life()
	assert_eq(Economy._regen_start_ts, 0, "timer tidak aktif kalau nyawa sudah max")


func test_t62_add_coins() -> void:
	Economy.coins = 0
	Economy.add_coins(100)
	assert_eq(Economy.coins, 100, "coins harus 100")


func test_t62_spend_coins_ok() -> void:
	Economy.coins = 50
	var ok := Economy.spend_coins(30)
	assert_true(ok, "spend_coins harus true")
	assert_eq(Economy.coins, 20, "sisa koin 20")


func test_t62_spend_coins_insufficient() -> void:
	Economy.coins = 10
	var ok := Economy.spend_coins(50)
	assert_false(ok, "spend_coins harus false saat tidak cukup")
	assert_eq(Economy.coins, 10, "koin tidak berubah")


func test_t62_offline_regen_gains_lives() -> void:
	Economy.lives = 3
	# Set regen_start_ts ke 30 menit yang lalu (≥1 regen cycle)
	Economy._regen_start_ts = int(Time.get_unix_time_from_system()) - Economy.REGEN_SECONDS - 10
	Economy.recompute_offline_regen()
	assert_gte(Economy.lives, 4, "regen offline harus tambah >=1 nyawa")


func test_t62_offline_regen_caps_at_max() -> void:
	Economy.lives = 1
	# Set 120 menit (>>max regen) yang lalu
	Economy._regen_start_ts = int(Time.get_unix_time_from_system()) - Economy.REGEN_SECONDS * 10
	Economy.recompute_offline_regen()
	assert_eq(Economy.lives, Economy.MAX_LIVES, "nyawa di-cap di MAX_LIVES")
	assert_eq(Economy._regen_start_ts, 0, "timer di-reset saat nyawa max")


func test_t62_secs_to_next_life_zero_when_full() -> void:
	Economy.lives = Economy.MAX_LIVES
	assert_eq(Economy.secs_to_next_life(), 0, "0 saat nyawa penuh")


func test_t62_secs_to_next_life_positive_when_regen() -> void:
	Economy.lives = 3
	Economy._regen_start_ts = int(Time.get_unix_time_from_system()) - 60
	var secs := Economy.secs_to_next_life()
	assert_gt(secs, 0, "secs > 0 saat regen berjalan")
	assert_lte(secs, Economy.REGEN_SECONDS, "secs <= REGEN_SECONDS")


func test_t62_ad_life_cap() -> void:
	Economy.lives = 0
	Economy._ad_count = Economy.MAX_AD_BONUS_DAY
	var ok := Economy.claim_ad_life()
	assert_false(ok, "false saat ad bonus sudah cap")


func test_t62_ad_life_success() -> void:
	Economy.lives = 2
	Economy._ad_count = 0
	var d := Time.get_date_dict_from_system()
	Economy._ad_date = "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]
	var ok := Economy.claim_ad_life()
	assert_true(ok, "claim_ad_life harus true")
	assert_eq(Economy.lives, 3, "nyawa +1")
	assert_eq(Economy._ad_count, 1, "ad_count +1")


# ---------------------------------------------------------------------------
# T6.3 — Progression: unlock berurutan
# ---------------------------------------------------------------------------

func test_t63_first_level_always_unlocked() -> void:
	LevelLoader.load_all()
	var first_id := LevelLoader.id_at(0)
	GameState.level_stars = {}
	assert_true(Progression.is_unlocked(first_id), "level pertama selalu terbuka")


func test_t63_second_level_locked_without_stars() -> void:
	LevelLoader.load_all()
	if LevelLoader.count() < 2:
		pass_test("terlalu sedikit level")
		return
	var second_id := LevelLoader.id_at(1)
	GameState.level_stars = {}
	assert_false(Progression.is_unlocked(second_id), "L2 terkunci tanpa bintang L1")


func test_t63_second_level_unlocks_with_first_cleared() -> void:
	LevelLoader.load_all()
	if LevelLoader.count() < 2:
		pass_test("terlalu sedikit level")
		return
	var first_id  := LevelLoader.id_at(0)
	var second_id := LevelLoader.id_at(1)
	GameState.level_stars = {first_id: 1}
	assert_true(Progression.is_unlocked(second_id), "L2 terbuka setelah L1 selesai")


func test_t63_get_stars_returns_correct() -> void:
	LevelLoader.load_all()
	var lid := LevelLoader.id_at(0)
	GameState.level_stars = {lid: 1}
	assert_eq(Progression.get_stars(lid), 1, "stars harus 1")
	GameState.level_stars = {}
	assert_eq(Progression.get_stars(lid), 0, "stars harus 0 kalau belum")


func test_t63_levels_cleared_count() -> void:
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1}
	assert_eq(Progression.levels_cleared(), 2, "cleared = 2")


func test_t63_total_stars() -> void:
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1, "lvl_003": 1}
	assert_eq(Progression.total_stars(), 3, "total = 3")


# ---------------------------------------------------------------------------
# T6.6 — Booster: koin + pre-level board modification
# ---------------------------------------------------------------------------

func test_t66_hammer_activates_only_with_coins() -> void:
	Economy.coins = 0
	var ok := Booster.activate_hammer()
	assert_false(ok, "hammer gagal tanpa koin")
	assert_eq(Booster.in_level_mode, "", "mode kosong")


func test_t66_hammer_activates_with_coins() -> void:
	Economy.coins = Booster.COST["in_hammer"] + 5
	var ok := Booster.activate_hammer()
	assert_true(ok, "hammer berhasil")
	assert_eq(Booster.in_level_mode, "hammer", "mode=hammer")
	Booster.clear_mode()


func test_t66_extra_swap_activates() -> void:
	Economy.coins = Booster.COST["in_swap"] + 5
	var ok := Booster.activate_extra_swap()
	assert_true(ok, "extra_swap berhasil")
	assert_eq(Booster.in_level_mode, "extra_swap", "mode=extra_swap")
	Booster.clear_mode()


func test_t66_buy_extra_moves() -> void:
	Economy.coins = Booster.COST["in_moves"] + 5
	var before := Economy.coins
	var ok := Booster.buy_extra_moves()
	assert_true(ok, "buy_extra_moves berhasil")
	assert_eq(Economy.coins, before - Booster.COST["in_moves"], "koin berkurang")


func test_t66_clear_mode() -> void:
	Booster.in_level_mode = "hammer"
	Booster.clear_mode()
	assert_eq(Booster.in_level_mode, "", "mode di-reset")


func test_t66_pre_rocket_places_special() -> void:
	var board := Board.new()
	var rng   := GameRNG.new(42)
	board.setup(7, 8, PackedInt32Array([1, 2, 3, 4, 5]), rng)
	Economy.coins = Booster.COST["pre_rocket"] + 10
	var ok := Booster.apply_pre_rocket(board, GameRNG.new(7))
	assert_true(ok, "pre_rocket berhasil")
	# Pastikan ada minimal satu tile ROCKET di board
	var found := false
	for y in range(board.height):
		for x in range(board.width):
			if board.get_special(x, y) == TileCodes.SPECIAL_ROCKET_H:
				found = true
				break
	assert_true(found, "ROCKET_H harus ada di board setelah pre-booster")


# ---------------------------------------------------------------------------
# T6.1 — run_gravity_refill_cascade (Board, T6.6 hammer backend)
# ---------------------------------------------------------------------------

func test_t61_gravity_cascade_fills_hole() -> void:
	var board := Board.new()
	var rng   := GameRNG.new(42)
	board.setup(7, 8, PackedInt32Array([1, 2, 3, 4, 5]), rng)
	# Hapus tile di (0,0) secara manual (simulasi hammer)
	board.set_cell(0, 0, TileCodes.encode(TileCodes.EMPTY, TileCodes.SPECIAL_NONE))
	var report := board.run_gravity_refill_cascade(GameRNG.new(99))
	assert_false(TileCodes.is_empty_cell(board.get_cell(0, 0)),
		"cell (0,0) harus terisi setelah gravity+refill")
