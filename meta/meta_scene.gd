extends Control
## MetaScene — layar Pulau Lumisle.
## T6.x: island progress, koleksi Lumi, win flow.
## T7.1: real Lumi album (freed/locked per slot, star progress bar).
## T7.2: mascot dialog saat area selesai.
## T7.4: daily reward + comeback popup saat buka.

const STAGE_THRESHOLDS := [0, 5, 12]   # total bintang untuk tahap 0/1/2

# T7.2 — Mascot dialogs per area completion.
const MASCOT_DIALOGS: Array = [
	"\"Cahaya kembali ke pesisir! Aku bisa melihat bintang-bintang laut lagi.\" — Lumis",
	"\"Hutan bernyala kembali. Terima kasih sudah membawa para roh pulang.\" — Lumis",
	"\"Puncak Bintang bersinar! Pulau Lumisle hidup kembali berkat kamu!\" — Lumis",
]

@onready var _island: Node = $Island
@onready var _stars_label: Label = $StarsLabel
@onready var _stage_label: Label = $StageLabel
@onready var _result_label: Label = $ResultLabel
@onready var _play_button: Button = $PlayButton
@onready var _lumi_grid: Node = $LumiGrid
@onready var _star_bar_label: Label = $StarBarLabel
@onready var _mascot_label: Label = $MascotLabel


func _ready() -> void:
	# T7.4 — hook daily/comeback signals sebelum check_on_open
	DailyReward.daily_ready.connect(_on_daily_ready)
	DailyReward.comeback_ready.connect(_on_comeback_ready)
	DailyReward.check_on_open()
	_render()
	_setup_play_button()
	_show_last_result()
	# T7.1 — reveal Lumi baru yang dibebaskan setelah level
	_handle_lumi_reveals()
	# T7.2 — mascot dialog kalau area baru selesai
	_check_area_complete_dialog()


func _render() -> void:
	var total := GameState.total_stars()
	var cleared := GameState.levels_cleared()
	var stage := _stage_for(total)
	var brightness := 0.20 + 0.40 * float(stage)
	if _island and _island.has_method("set_state"):
		_island.set_state(brightness, stage)
	if _stars_label:
		var freed := LumiCollection.total_freed()
		_stars_label.text = "Lumi terkumpul: %d / 18  (level selesai: %d)" % [freed, cleared]
	if _stage_label:
		var names := ["Pulau Redup", "Pulau Bersinar", "Pulau Bercahaya"]
		_stage_label.text = "%s  (tahap %d/3)" % [names[stage], stage + 1]
	if _lumi_grid and _lumi_grid.has_method("setup_collection"):
		_lumi_grid.setup_collection()
	_update_star_bar()


func _update_star_bar() -> void:
	if not _star_bar_label:
		return
	var area_idx := 1
	var current_stars := LumiCollection.stars_for_area(area_idx)
	var needed := LumiCollection.stars_needed_for_next(area_idx)
	if needed < 0:
		_star_bar_label.text = "✨ Area 1 lengkap! Semua Lumi terkumpul."
	else:
		_star_bar_label.text = "⭐ %d bintang Area 1  (Lumi berikutnya: perlu %d lagi)" % [current_stars, needed]


func _setup_play_button() -> void:
	if not _play_button:
		return
	if GameState.next_level_id != "":
		var lv := LevelLoader.get_level(GameState.next_level_id)
		var title := lv.title if lv else GameState.next_level_id
		_play_button.text = "Lanjut: %s →" % title
	else:
		_play_button.text = "Pilih Level"


func _stage_for(total: int) -> int:
	var stage := 0
	for i in range(STAGE_THRESHOLDS.size()):
		if total >= STAGE_THRESHOLDS[i]:
			stage = i
	return stage


func _show_last_result() -> void:
	var r := GameState.last_result
	if r.is_empty() or not r.get("won", false):
		if _result_label:
			_result_label.visible = false
		return
	if _result_label:
		_result_label.visible = true
		var lid: String = r.get("level_id", "?")
		_result_label.text = "★  Level %s selesai!" % lid.replace("lvl_", "L")
	if _island and _island.has_method("set_state"):
		var t := create_tween()
		if "brightness" in _island:
			t.tween_property(_island, "brightness", minf(_island.brightness + 0.3, 1.0), 0.4)
			t.tween_property(_island, "brightness", _island.brightness, 0.6)
	GameState.last_result = {}


# ---------------------------------------------------------------------------
# T7.1 — Lumi reveal toasts
# ---------------------------------------------------------------------------

func _handle_lumi_reveals() -> void:
	if GameState.newly_freed_lumi.is_empty():
		return
	var freed_copy := GameState.newly_freed_lumi.duplicate()
	GameState.newly_freed_lumi = []
	if _lumi_grid and _lumi_grid.has_method("setup_collection"):
		_lumi_grid.setup_collection()
	for lumi_id in freed_copy:
		var entry: Variant = LumiCatalog.get_lumi(lumi_id)
		if entry == null:
			continue
		await _show_lumi_toast(entry)
		await get_tree().create_timer(0.4).timeout


func _show_lumi_toast(entry: Dictionary) -> void:
	if not _result_label:
		return
	var badges := {"common": "✦", "rare": "★ LANGKA", "epic": "★★ EPIK"}
	var badge: String = badges.get(str(entry.get("rarity", "")), "")
	_result_label.text = "✨ Lumi baru: %s %s" % [str(entry.get("name", "")), badge]
	_result_label.visible = true
	_result_label.modulate = Color(1.0, 0.95, 0.5, 1.0)
	var t := create_tween()
	t.tween_interval(1.8)
	t.tween_property(_result_label, "modulate:a", 0.0, 0.7)
	await t.finished
	if is_instance_valid(_result_label):
		_result_label.visible = false
		_result_label.modulate = Color.WHITE


# ---------------------------------------------------------------------------
# T7.2 — Mascot / area completion dialog
# ---------------------------------------------------------------------------

func _check_area_complete_dialog() -> void:
	if not _mascot_label:
		return
	for area_idx in [1, 2, 3]:
		if not _was_area_dialog_shown(area_idx) and LumiCollection.is_area_complete(area_idx):
			_mark_area_dialog_shown(area_idx)
			var idx := clampi(area_idx - 1, 0, MASCOT_DIALOGS.size() - 1)
			_mascot_label.text = MASCOT_DIALOGS[idx]
			_mascot_label.modulate = Color(1, 1, 1, 0)
			_mascot_label.visible = true
			var t := create_tween()
			t.tween_property(_mascot_label, "modulate:a", 1.0, 0.8)
			break


func _was_area_dialog_shown(area_idx: int) -> bool:
	var data := SaveManager.load_game()
	var raw: Variant = data.get("mascot_shown_areas", [])
	if typeof(raw) == TYPE_ARRAY:
		return raw.has(area_idx)
	return false


func _mark_area_dialog_shown(area_idx: int) -> void:
	var data := SaveManager.load_game()
	var raw: Variant = data.get("mascot_shown_areas", [])
	var arr: Array = []
	if typeof(raw) == TYPE_ARRAY:
		arr = raw.duplicate()
	if not arr.has(area_idx):
		arr.append(area_idx)
	data["mascot_shown_areas"] = arr
	SaveManager.save_game(data)


# ---------------------------------------------------------------------------
# T7.4 — Daily reward / comeback
# ---------------------------------------------------------------------------

func _on_daily_ready(day: int, reward: Dictionary) -> void:
	if not _result_label:
		return
	_result_label.text = "🎁 Hadiah Hari %d: %s" % [day, _reward_summary(reward)]
	_result_label.visible = true
	_result_label.modulate = Color(1.0, 0.9, 0.4, 1.0)
	await get_tree().create_timer(3.0).timeout
	DailyReward.claim_daily()
	if is_instance_valid(_result_label):
		var t := create_tween()
		t.tween_property(_result_label, "modulate:a", 0.0, 0.6)
		await t.finished
		_result_label.visible = false
		_result_label.modulate = Color.WHITE
	_render()


func _on_comeback_ready(reward: Dictionary) -> void:
	if not _result_label:
		return
	_result_label.text = "💛 Selamat datang kembali!\nPara Lumi merindukanmu! %s" % _reward_summary(reward)
	_result_label.visible = true
	_result_label.modulate = Color(1.0, 0.85, 0.55, 1.0)
	await get_tree().create_timer(4.0).timeout
	DailyReward.claim_comeback()
	if is_instance_valid(_result_label):
		var t := create_tween()
		t.tween_property(_result_label, "modulate:a", 0.0, 0.6)
		await t.finished
		_result_label.visible = false
		_result_label.modulate = Color.WHITE
	_render()


func _reward_summary(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if reward.has("coins"):
		parts.append("%d koin" % int(reward["coins"]))
	if reward.has("lives"):
		parts.append("+%d nyawa" % int(reward["lives"]))
	if reward.has("boosters"):
		for b in reward["boosters"]:
			parts.append("booster %s" % str(b))
	return ", ".join(parts)


func _on_play_pressed() -> void:
	if GameState.next_level_id != "":
		GameState.current_level_id = GameState.next_level_id
		GameState.next_level_id = ""
		SceneManager.change_screen("game")
	else:
		SceneManager.change_screen("level_map")


func _on_back_pressed() -> void:
	GameState.next_level_id = ""
	SceneManager.change_screen("main_menu")
