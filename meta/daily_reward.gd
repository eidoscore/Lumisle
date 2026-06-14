extends Node
## DailyReward (autoload, T7.4) — login streak harian, kotak hadiah waktu, comeback reward.
## Dipanggil dari MetaScene / MainMenu saat buka game.
## Save keys: daily_streak_day, daily_last_claim_date, daily_last_session_date,
##            timebox_ts, timebox_pending, comeback_claimed_ts.
## GDD §6.3.

## 7-day streak table. keys: coins, lives, boosters (Array[String]).
const STREAK_REWARDS: Array = [
	{"coins": 30},
	{"lives": 1},
	{"coins": 60, "boosters": ["hammer"]},
	{"lives": 2},
	{"coins": 100},
	{"boosters": ["rocket"]},
	{"coins": 180, "boosters": ["rocket", "hammer"]},
]

const TIMEBOX_INTERVAL_SECS := 4 * 60 * 60   # 4 jam
const TIMEBOX_MAX_PENDING   := 2
const COMEBACK_DAYS         := 7              # 7+ hari tidak main = comeback

var streak_day: int     = 0         # 1-7. 0 = belum pernah claim
var _last_claim_date: String = ""   # "YYYY-MM-DD"
var _last_session_date: String = "" # "YYYY-MM-DD"
var _timebox_ts: int    = 0         # unix epoch saat terakhir claim timebox
var _timebox_pending: int = 0       # 0/1/2 kotak menunggu
var _comeback_ts: int   = 0         # epoch saat terakhir comeback diberikan

signal daily_ready(day: int, reward: Dictionary)
signal timebox_ready(count: int)
signal comeback_ready(reward: Dictionary)


func _ready() -> void:
	set_process(false)
	_load()


## Dipanggil saat game dibuka (dari MetaScene / MainMenu _ready).
## Emit signal jika ada reward yang siap diklaim.
func check_on_open() -> void:
	_update_session_date()
	_check_timebox_accumulate()
	var today := _today()
	if _check_streak_claimable(today):
		var reward: Variant = STREAK_REWARDS[(streak_day - 1) % STREAK_REWARDS.size()]
		daily_ready.emit(streak_day, reward)
	elif _timebox_pending > 0:
		timebox_ready.emit(_timebox_pending)
	# Comeback: 7+ hari tidak membuka
	if _check_comeback():
		var cb_reward := {"coins": 150, "lives": Economy.MAX_LIVES, "boosters": ["rocket", "hammer"]}
		comeback_ready.emit(cb_reward)


## Claim daily streak reward hari ini. Kembalikan reward dict, {} kalau tidak valid.
func claim_daily() -> Dictionary:
	var today := _today()
	if not _check_streak_claimable(today):
		return {}
	var day_idx := streak_day - 1
	var reward_raw: Variant = STREAK_REWARDS[day_idx % STREAK_REWARDS.size()]
	var reward: Dictionary = reward_raw as Dictionary
	_apply_reward(reward)
	_last_claim_date = today
	# Naikkan streak untuk hari berikutnya
	streak_day = (streak_day % STREAK_REWARDS.size()) + 1
	_save()
	return reward


## Claim satu kotak waktu. Kembalikan reward dict, {} kalau tidak ada.
func claim_timebox() -> Dictionary:
	if _timebox_pending <= 0:
		return {}
	_timebox_pending -= 1
	var rewards: Array = [
		{"coins": 20}, {"coins": 35}, {"coins": 50},
		{"lives": 1}, {"boosters": ["hammer"]},
	]
	# Random seeded (deterministik berdasarkan timestamp)
	var idx := (_timebox_ts + _timebox_pending) % rewards.size()
	var tb_raw: Variant = rewards[idx]
	var reward: Dictionary = tb_raw as Dictionary
	_apply_reward(reward)
	_save()
	return reward


## Claim comeback reward. Kembalikan reward dict, {} kalau tidak eligible.
func claim_comeback() -> Dictionary:
	if not _check_comeback():
		return {}
	var reward := {"coins": 150, "lives": Economy.MAX_LIVES, "boosters": ["rocket", "hammer"]}
	_apply_reward(reward)
	_comeback_ts = _now()
	_save()
	return reward


## True kalau daily reward belum diklaim hari ini.
func is_daily_claimable() -> bool:
	return _check_streak_claimable(_today())


## Detik sampai timebox berikutnya siap. 0 kalau sudah siap / max pending.
func secs_to_next_timebox() -> int:
	if _timebox_pending >= TIMEBOX_MAX_PENDING:
		return 0
	if _timebox_ts <= 0:
		return 0
	var elapsed := _now() - _timebox_ts
	var remaining := TIMEBOX_INTERVAL_SECS - elapsed
	return maxi(0, remaining)


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _check_streak_claimable(today: String) -> bool:
	if _last_claim_date == today:
		return false  # sudah diklaim hari ini
	# Hitung apakah streak berlanjut atau reset
	if streak_day == 0:
		streak_day = 1
	else:
		var yesterday := _days_ago(1)
		if _last_claim_date != yesterday:
			# Lewat lebih dari 1 hari → reset streak
			streak_day = 1
	return true


func _check_comeback() -> bool:
	if _last_session_date == "":
		return false
	var elapsed_days := _days_since(_last_session_date)
	if elapsed_days < COMEBACK_DAYS:
		return false
	# Pastikan comeback tidak diberikan dalam 7 hari terakhir
	if _comeback_ts > 0:
		var secs_since_comeback := _now() - _comeback_ts
		if secs_since_comeback < COMEBACK_DAYS * 86400:
			return false
	return true


func _update_session_date() -> void:
	var today := _today()
	if _last_session_date != today:
		_last_session_date = today
		_save()


func _check_timebox_accumulate() -> void:
	if _timebox_ts <= 0:
		_timebox_ts = _now()
		_timebox_pending = 0
		_save()
		return
	var elapsed := _now() - _timebox_ts
	var boxes_earned := int(elapsed / TIMEBOX_INTERVAL_SECS)
	if boxes_earned > 0:
		_timebox_pending = mini(_timebox_pending + boxes_earned, TIMEBOX_MAX_PENDING)
		_timebox_ts += boxes_earned * TIMEBOX_INTERVAL_SECS
		_save()


func _apply_reward(reward: Dictionary) -> void:
	if reward.has("coins"):
		Economy.add_coins(int(reward["coins"]))
	if reward.has("lives"):
		var extra := int(reward["lives"])
		Economy.lives = mini(Economy.lives + extra, Economy.MAX_LIVES)
		Economy._regen_start_ts = 0 if Economy.lives >= Economy.MAX_LIVES else Economy._regen_start_ts
		Economy._save()
	if reward.has("boosters"):
		# Boosters reward: simpan di save sebagai pending boosters
		var data := SaveManager.load_game()
		var pending: Array = []
		var raw: Variant = data.get("pending_boosters", [])
		if typeof(raw) == TYPE_ARRAY:
			for item in raw:
				pending.append(str(item))
		for b in reward["boosters"]:
			pending.append(str(b))
		data["pending_boosters"] = pending
		SaveManager.save_game(data)


func _save() -> void:
	var data := SaveManager.load_game()
	data["daily_streak_day"]     = streak_day
	data["daily_last_claim"]     = _last_claim_date
	data["daily_last_session"]   = _last_session_date
	data["timebox_ts"]           = _timebox_ts
	data["timebox_pending"]      = _timebox_pending
	data["comeback_ts"]          = _comeback_ts
	SaveManager.save_game(data)


func _load() -> void:
	var data := SaveManager.load_game()
	streak_day          = int(data.get("daily_streak_day", 0))
	_last_claim_date    = str(data.get("daily_last_claim", ""))
	_last_session_date  = str(data.get("daily_last_session", ""))
	_timebox_ts         = int(data.get("timebox_ts", 0))
	_timebox_pending    = int(data.get("timebox_pending", 0))
	_comeback_ts        = int(data.get("comeback_ts", 0))


func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


func _days_ago(n: int) -> String:
	var ts := _now() - n * 86400
	var d := Time.get_date_dict_from_unix_time(ts)
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


func _days_since(date_str: String) -> int:
	if date_str == "":
		return 0
	var today_ts := _now()
	# Parse date_str "YYYY-MM-DD"
	var parts := date_str.split("-")
	if parts.size() < 3:
		return 0
	var d := {
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0,
	}
	var past_ts := int(Time.get_unix_time_from_datetime_dict(d))
	return int((today_ts - past_ts) / 86400)


func _now() -> int:
	return int(Time.get_unix_time_from_system())
