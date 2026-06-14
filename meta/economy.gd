extends Node
## Economy (autoload T6.2) — koin, nyawa (max 5, regen 1/25 mnt), bonus iklan harian.
## Semua mutation di-persist via SaveManager merge pattern.
## Spec: docs/06-ekonomi.md (GDD D4).

const MAX_LIVES        := 5
const REGEN_SECONDS    := 25 * 60    # 1 nyawa tiap 25 menit
const MAX_AD_BONUS_DAY := 5          # max +nyawa dari iklan per hari

var lives: int = MAX_LIVES
var coins: int = 0
var _regen_start_ts: int  = 0   # unix epoch (detik) saat nyawa mulai kurang dari max
var _ad_date: String      = ""  # "YYYY-MM-DD" — untuk reset harian
var _ad_count: int        = 0   # bonus iklan hari ini


func _ready() -> void:
	set_process(false)
	_load()
	recompute_offline_regen()


## Debit 1 nyawa. Kembalikan false kalau nyawa sudah 0.
func spend_life() -> bool:
	if lives <= 0:
		return false
	if lives == MAX_LIVES:
		_regen_start_ts = _now()
	lives -= 1
	_save()
	return true


## Refund nyawa (batal masuk level). Tidak melewati MAX_LIVES.
func refund_life() -> void:
	lives = mini(lives + 1, MAX_LIVES)
	if lives >= MAX_LIVES:
		_regen_start_ts = 0
	_save()


## Tambah koin.
func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	_save()


## Belanja koin. Kembalikan false kalau tidak cukup (tidak ada perubahan).
func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	_save()
	return true


## Klaim +1 nyawa dari iklan rewarded. False kalau sudah cap atau nyawa sudah penuh.
func claim_ad_life() -> bool:
	_check_day_reset()
	if _ad_count >= MAX_AD_BONUS_DAY:
		return false
	if lives >= MAX_LIVES:
		return false
	_ad_count += 1
	lives = mini(lives + 1, MAX_LIVES)
	if lives >= MAX_LIVES:
		_regen_start_ts = 0
	_save()
	return true


## Detik sampai nyawa berikutnya regen. 0 kalau sudah max atau regen tidak berjalan.
func secs_to_next_life() -> int:
	if lives >= MAX_LIVES or _regen_start_ts <= 0:
		return 0
	var elapsed := _now() - _regen_start_ts
	var remaining := REGEN_SECONDS - (elapsed % REGEN_SECONDS)
	return int(remaining)


## Isi nyawa yang regen selagi offline. Panggil saat _ready dan saat app resume (T6.7).
func recompute_offline_regen() -> void:
	if lives >= MAX_LIVES or _regen_start_ts <= 0:
		return
	var elapsed := _now() - _regen_start_ts
	var gained  := elapsed / REGEN_SECONDS
	if gained <= 0:
		return
	lives = mini(lives + gained, MAX_LIVES)
	_regen_start_ts += gained * REGEN_SECONDS
	if lives >= MAX_LIVES:
		_regen_start_ts = 0
	_save()


func _check_day_reset() -> void:
	var today := _today_str()
	if _ad_date != today:
		_ad_date = today
		_ad_count = 0


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _today_str() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


func _save() -> void:
	var data := SaveManager.load_game()
	data["economy"] = {
		"lives": lives,
		"coins": coins,
		"regen_start_ts": _regen_start_ts,
		"ad_date": _ad_date,
		"ad_count": _ad_count,
	}
	SaveManager.save_game(data)


func _load() -> void:
	var data := SaveManager.load_game()
	var e: Dictionary = data.get("economy", {}) if typeof(data.get("economy")) == TYPE_DICTIONARY else {}
	lives           = clampi(int(e.get("lives", MAX_LIVES)), 0, MAX_LIVES)
	coins           = maxi(0, int(e.get("coins", 0)))
	_regen_start_ts = int(e.get("regen_start_ts", 0))
	_ad_date        = str(e.get("ad_date", ""))
	_ad_count       = int(e.get("ad_count", 0))
	_check_day_reset()
