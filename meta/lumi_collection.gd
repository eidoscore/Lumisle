extends Node
## LumiCollection (autoload, T7.1) — koleksi Lumi: track mana yang sudah dibebaskan,
## hitung bintang per area, check unlock baru setelah menang level.
## Save key: "freed_lumi" (Array of String id).
## Spec: GDD §6.1.

var freed_ids: Array[String] = []
signal lumi_freed(lumi_id: String)


func _ready() -> void:
	set_process(false)
	_load()


## Hitung total bintang yang diperoleh dalam area tertentu (1-indexed).
## Menjumlah level_stars untuk semua level yang level_number-nya masuk range area.
func stars_for_area(area_idx: int) -> int:
	var total := 0
	var range_data: Variant = null
	for r in LumiCatalog.AREA_LEVEL_RANGES:
		if r["area"] == area_idx:
			range_data = r
			break
	if range_data == null:
		return 0
	for lid in GameState.level_stars:
		var num := _level_number(str(lid))
		if num >= range_data["level_min"] and num <= range_data["level_max"]:
			total += int(GameState.level_stars[lid])
	return total


## Check apakah ada Lumi baru yang ter-unlock berdasarkan bintang sekarang.
## Kembalikan array id Lumi yang BARU dibebaskan saat pemanggilan ini.
func check_new_unlocks() -> Array[String]:
	var newly: Array[String] = []
	for area_idx in [1, 2, 3]:
		var area_stars := stars_for_area(area_idx)
		var area_lumi := LumiCatalog.for_area(area_idx)
		for entry in area_lumi:
			var lid: String = entry["id"]
			if freed_ids.has(lid):
				continue
			var threshold := LumiCatalog.threshold_for_slot(int(entry["slot"]))
			if area_stars >= threshold:
				freed_ids.append(lid)
				newly.append(lid)
				lumi_freed.emit(lid)
	if not newly.is_empty():
		_save()
	return newly


## Apakah Lumi dengan id ini sudah dibebaskan.
func is_freed(id: String) -> bool:
	return freed_ids.has(id)


## Berapa bintang area yang dibutuhkan untuk Lumi berikutnya di area tertentu.
## Kembalikan -1 kalau semua sudah dibebaskan.
func stars_needed_for_next(area_idx: int) -> int:
	var area_stars := stars_for_area(area_idx)
	var area_lumi := LumiCatalog.for_area(area_idx)
	for entry in area_lumi:
		if not freed_ids.has(entry["id"]):
			var threshold := LumiCatalog.threshold_for_slot(int(entry["slot"]))
			return maxi(0, threshold - area_stars)
	return -1  # semua Lumi area sudah bebas


## Jumlah Lumi yang sudah dibebaskan di area tertentu.
func freed_count_in_area(area_idx: int) -> int:
	var count := 0
	for entry in LumiCatalog.for_area(area_idx):
		if freed_ids.has(entry["id"]):
			count += 1
	return count


## Total Lumi dibebaskan (semua area).
func total_freed() -> int:
	return freed_ids.size()


## Apakah area selesai (semua 6 Lumi bebas).
func is_area_complete(area_idx: int) -> bool:
	return freed_count_in_area(area_idx) >= LumiCatalog.for_area(area_idx).size()


func _save() -> void:
	var data := SaveManager.load_game()
	data["freed_lumi"] = freed_ids.duplicate()
	SaveManager.save_game(data)


func _load() -> void:
	var data := SaveManager.load_game()
	var raw: Variant = data.get("freed_lumi", [])
	freed_ids.clear()
	if typeof(raw) == TYPE_ARRAY:
		for item in raw:
			freed_ids.append(str(item))


## Konversi "lvl_001" → 1, "lvl_031" → 31, dll.
func _level_number(level_id: String) -> int:
	var stripped := level_id.replace("lvl_", "")
	if stripped.is_valid_int():
		return int(stripped)
	return 0
