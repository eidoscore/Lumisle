extends GutTest
## Unit tests Fase 7 — Koleksi Lumi + FTUE + Daily Reward + DDA.
## T7.1: LumiCatalog + LumiCollection (stars per area, unlock, persist)
## T7.4: DailyReward (streak, claim, comeback, timebox)
## T7.5: DDA (loss streak tracking, bonus moves)
## T7.2, T7.3: visual / manual QA.


# ---------------------------------------------------------------------------
# T7.1 — LumiCatalog
# ---------------------------------------------------------------------------

func test_t71_catalog_has_18_lumi() -> void:
	assert_eq(LumiCatalog.ALL.size(), 18, "catalog harus punya 18 Lumi")


func test_t71_catalog_areas_correct() -> void:
	for entry in LumiCatalog.ALL:
		assert_between(int(entry["area"]), 1, 3, "area harus 1-3")


func test_t71_catalog_slots_1_to_6() -> void:
	for entry in LumiCatalog.ALL:
		assert_between(int(entry["slot"]), 1, 6, "slot harus 1-6")


func test_t71_catalog_rarity_valid() -> void:
	var valid := ["common", "rare", "epic"]
	for entry in LumiCatalog.ALL:
		assert_true(valid.has(str(entry["rarity"])), "rarity harus common/rare/epic")


func test_t71_catalog_for_area_returns_6() -> void:
	for area in [1, 2, 3]:
		var lumi := LumiCatalog.for_area(area)
		assert_eq(lumi.size(), 6, "tiap area punya 6 Lumi")


func test_t71_catalog_get_lumi_by_id() -> void:
	var e: Variant = LumiCatalog.get_lumi("lumi_1_1")
	assert_not_null(e, "harus ada lumi_1_1")
	assert_eq(str(e["name"]), "Ora", "nama harus Ora")


func test_t71_catalog_get_lumi_unknown_returns_null() -> void:
	var e: Variant = LumiCatalog.get_lumi("tidak_ada")
	assert_null(e, "harus null kalau tidak ada")


func test_t71_catalog_star_thresholds_ascending() -> void:
	var prev := 0
	for i in range(LumiCatalog.STAR_THRESHOLDS.size()):
		var t := LumiCatalog.STAR_THRESHOLDS[i]
		assert_gt(t, prev, "threshold harus naik")
		prev = t


func test_t71_catalog_epic_is_slot_6() -> void:
	for area in [1, 2, 3]:
		var lumi := LumiCatalog.for_area(area)
		var epic_count := 0
		for e in lumi:
			if str(e["rarity"]) == "epic":
				epic_count += 1
				assert_eq(int(e["slot"]), 6, "epic harus di slot 6")
	pass


# ---------------------------------------------------------------------------
# T7.1 — LumiCollection
# ---------------------------------------------------------------------------

func before_each() -> void:
	# Reset collection + GameState stars
	LumiCollection.freed_ids.clear()
	GameState.level_stars = {}


func test_t71_no_unlocks_without_stars() -> void:
	GameState.level_stars = {}
	var newly := LumiCollection.check_new_unlocks()
	assert_eq(newly.size(), 0, "tidak ada unlock tanpa bintang")


func test_t71_first_lumi_unlocks_at_3_stars() -> void:
	# lvl_001 memberikan 1 bintang, butuh 3 bintang total → 3 level
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1, "lvl_003": 1}
	var newly := LumiCollection.check_new_unlocks()
	assert_true(newly.has("lumi_1_1"), "lumi_1_1 harus unlock di 3 bintang")


func test_t71_second_lumi_unlocks_at_8_stars() -> void:
	# 8 bintang di area 1
	GameState.level_stars = {
		"lvl_001": 1, "lvl_002": 1, "lvl_003": 1, "lvl_004": 1,
		"lvl_005": 1, "lvl_006": 1, "lvl_007": 1, "lvl_008": 1,
	}
	var newly := LumiCollection.check_new_unlocks()
	assert_true(newly.has("lumi_1_1"), "lumi_1_1 harus unlock")
	assert_true(newly.has("lumi_1_2"), "lumi_1_2 harus unlock di 8 bintang")


func test_t71_is_freed_after_check() -> void:
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1, "lvl_003": 1}
	LumiCollection.check_new_unlocks()
	assert_true(LumiCollection.is_freed("lumi_1_1"), "lumi_1_1 harus freed setelah check")


func test_t71_stars_for_area_sums_correctly() -> void:
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1, "lvl_031": 1}
	var area1 := LumiCollection.stars_for_area(1)
	var area2 := LumiCollection.stars_for_area(2)
	assert_eq(area1, 2, "area 1 = lvl_001 + lvl_002 = 2 bintang")
	assert_eq(area2, 1, "area 2 = lvl_031 = 1 bintang")


func test_t71_stars_needed_for_next() -> void:
	GameState.level_stars = {"lvl_001": 1}  # 1 star, need 3 for first Lumi
	var needed := LumiCollection.stars_needed_for_next(1)
	assert_eq(needed, 2, "butuh 2 bintang lagi untuk Lumi pertama")


func test_t71_stars_needed_minus1_when_all_freed() -> void:
	# Bebas semua Lumi area 1
	for e in LumiCatalog.for_area(1):
		LumiCollection.freed_ids.append(str(e["id"]))
	var needed := LumiCollection.stars_needed_for_next(1)
	assert_eq(needed, -1, "-1 saat semua Lumi area sudah bebas")


func test_t71_freed_count_in_area() -> void:
	LumiCollection.freed_ids = ["lumi_1_1", "lumi_1_2"]
	assert_eq(LumiCollection.freed_count_in_area(1), 2, "freed_count = 2")
	assert_eq(LumiCollection.freed_count_in_area(2), 0, "area 2 = 0")


func test_t71_total_freed() -> void:
	LumiCollection.freed_ids = ["lumi_1_1", "lumi_2_1"]
	assert_eq(LumiCollection.total_freed(), 2, "total freed = 2")


func test_t71_is_area_complete() -> void:
	for e in LumiCatalog.for_area(1):
		LumiCollection.freed_ids.append(str(e["id"]))
	assert_true(LumiCollection.is_area_complete(1), "area 1 selesai kalau 6 Lumi bebas")
	assert_false(LumiCollection.is_area_complete(2), "area 2 belum selesai")


func test_t71_check_new_unlocks_idempotent() -> void:
	GameState.level_stars = {"lvl_001": 1, "lvl_002": 1, "lvl_003": 1}
	var first := LumiCollection.check_new_unlocks()
	var second := LumiCollection.check_new_unlocks()
	assert_eq(first.size(), 1, "pertama kali unlock 1 Lumi")
	assert_eq(second.size(), 0, "kedua kali tidak ada unlock baru")


# ---------------------------------------------------------------------------
# T7.4 — DailyReward
# ---------------------------------------------------------------------------

func before_each_daily() -> void:
	DailyReward.streak_day = 0
	DailyReward._last_claim_date = ""
	DailyReward._last_session_date = ""
	DailyReward._timebox_ts = 0
	DailyReward._timebox_pending = 0
	DailyReward._comeback_ts = 0


func test_t74_streak_rewards_has_7_days() -> void:
	assert_eq(DailyReward.STREAK_REWARDS.size(), 7, "harus ada 7 hari reward")


func test_t74_first_claim_sets_streak_to_2() -> void:
	before_each_daily()
	DailyReward.streak_day = 1
	# Simulate not claimed today
	DailyReward._last_claim_date = "2000-01-01"  # masa lalu
	var reward := DailyReward.claim_daily()
	assert_false(reward.is_empty(), "claim harus sukses")
	assert_eq(DailyReward.streak_day, 2, "streak naik ke 2")


func test_t74_claim_same_day_fails() -> void:
	before_each_daily()
	var today := Time.get_date_dict_from_system()
	var today_str := "%04d-%02d-%02d" % [int(today.year), int(today.month), int(today.day)]
	DailyReward.streak_day = 1
	DailyReward._last_claim_date = today_str
	var reward := DailyReward.claim_daily()
	assert_true(reward.is_empty(), "tidak bisa claim dua kali sehari")


func test_t74_is_daily_claimable_true_when_not_claimed() -> void:
	before_each_daily()
	DailyReward.streak_day = 1
	DailyReward._last_claim_date = "2020-01-01"
	assert_true(DailyReward.is_daily_claimable(), "harus bisa claim kalau belum hari ini")


func test_t74_timebox_accumulates() -> void:
	before_each_daily()
	# Set timebox_ts 5 jam yang lalu (lebih dari 1 interval 4 jam)
	DailyReward._timebox_ts = int(Time.get_unix_time_from_system()) - 5 * 3600
	DailyReward._timebox_pending = 0
	DailyReward._check_timebox_accumulate()
	assert_gte(DailyReward._timebox_pending, 1, "harus ada >=1 kotak setelah 5 jam")


func test_t74_timebox_capped_at_max() -> void:
	before_each_daily()
	# 24 jam = banyak interval → tapi cap di MAX_PENDING=2
	DailyReward._timebox_ts = int(Time.get_unix_time_from_system()) - 24 * 3600
	DailyReward._timebox_pending = 0
	DailyReward._check_timebox_accumulate()
	assert_lte(DailyReward._timebox_pending, DailyReward.TIMEBOX_MAX_PENDING,
		"timebox tidak boleh melebihi max pending")


func test_t74_comeback_not_trigger_under_7_days() -> void:
	before_each_daily()
	DailyReward._last_session_date = DailyReward._days_ago(3)
	assert_false(DailyReward._check_comeback(), "comeback hanya setelah 7+ hari")


func test_t74_comeback_trigger_after_7_days() -> void:
	before_each_daily()
	DailyReward._last_session_date = DailyReward._days_ago(8)
	assert_true(DailyReward._check_comeback(), "comeback harus trigger setelah 8 hari")


func test_t74_comeback_not_twice_in_7_days() -> void:
	before_each_daily()
	DailyReward._last_session_date = DailyReward._days_ago(10)
	# Baru saja klaim comeback 1 hari lalu
	DailyReward._comeback_ts = int(Time.get_unix_time_from_system()) - 86400
	assert_false(DailyReward._check_comeback(), "comeback tidak bisa dua kali dalam 7 hari")


func test_t74_reward_has_day1_coins() -> void:
	var day1 := DailyReward.STREAK_REWARDS[0]
	assert_true(day1.has("coins"), "hari 1 harus ada coins")
	assert_gte(int(day1["coins"]), 1, "coins hari 1 harus > 0")


func test_t74_reward_day7_is_biggest() -> void:
	var day7 := DailyReward.STREAK_REWARDS[6]
	assert_true(day7.has("coins"), "hari 7 harus ada coins")
	assert_gte(int(day7["coins"]), 100, "hari 7 harus coins banyak")


# ---------------------------------------------------------------------------
# T7.5 — DDA
# ---------------------------------------------------------------------------

func before_each_dda() -> void:
	DDA._loss_streaks.clear()


func test_t75_no_bonus_without_losses() -> void:
	before_each_dda()
	assert_eq(DDA.get_bonus_moves("lvl_001"), 0, "tidak ada bonus tanpa kekalahan")


func test_t75_no_bonus_at_2_losses() -> void:
	before_each_dda()
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	assert_eq(DDA.get_bonus_moves("lvl_001"), 0, "tidak ada bonus di 2 kekalahan")


func test_t75_bonus_1_at_3_losses() -> void:
	before_each_dda()
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	assert_eq(DDA.get_bonus_moves("lvl_001"), 1, "+1 bonus di 3 kekalahan")


func test_t75_bonus_2_at_5_losses() -> void:
	before_each_dda()
	for _i in range(5):
		DDA.record_loss("lvl_001")
	assert_eq(DDA.get_bonus_moves("lvl_001"), 2, "+2 bonus di 5 kekalahan")


func test_t75_win_resets_streak() -> void:
	before_each_dda()
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	DDA.record_win("lvl_001")
	assert_eq(DDA.get_bonus_moves("lvl_001"), 0, "menang reset streak → tidak ada bonus")


func test_t75_streaks_independent_per_level() -> void:
	before_each_dda()
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	DDA.record_loss("lvl_001")
	assert_eq(DDA.get_bonus_moves("lvl_002"), 0, "streak lvl_001 tidak pengaruhi lvl_002")


func test_t75_get_streak_returns_count() -> void:
	before_each_dda()
	DDA.record_loss("lvl_005")
	DDA.record_loss("lvl_005")
	assert_eq(DDA.get_streak("lvl_005"), 2, "streak harus 2")
