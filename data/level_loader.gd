class_name LevelLoader extends RefCounted
## T4.1 — Loader level dari JSON chunked (dok 05 §2, §7.1). Pakai FileAccess
## (BUKAN ResourceLoader yang di-cache). Cache {id -> LevelDefinition} + urutan id.
## Static + singleton-ringan: panggil LevelLoader.load_all() sekali, lalu get(id).

const PACK_DIR := "res://data/levels/handcrafted/"

static var _by_id: Dictionary = {}        # id(String) -> LevelDefinition
static var _order: Array[String] = []     # urutan id (sesuai urutan di pack)
static var _loaded := false


## Muat semua pack JSON di PACK_DIR (sekali). Idempoten.
static func load_all(force: bool = false) -> void:
	if _loaded and not force:
		return
	_by_id.clear()
	_order.clear()
	var dir := DirAccess.open(PACK_DIR)
	if dir == null:
		push_warning("LevelLoader: dir tidak ada: %s" % PACK_DIR)
		_loaded = true
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()   # pack_001_030.json sebelum pack_031_060.json
	for f in files:
		_load_pack(PACK_DIR + f)
	_loaded = true


static func _load_pack(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_warning("LevelLoader: gagal buka %s" % path)
		return
	var txt := fa.get_as_text()
	fa.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("LevelLoader: JSON invalid di %s" % path)
		return
	for lvd in parsed.get("levels", []):
		if typeof(lvd) != TYPE_DICTIONARY:
			continue
		var lv := LevelDefinition.from_dict(lvd)
		if lv.id == "":
			continue
		if not _by_id.has(lv.id):
			_order.append(lv.id)
		_by_id[lv.id] = lv


static func get_level(id: String) -> LevelDefinition:
	load_all()
	return _by_id.get(id, null)


static func count() -> int:
	load_all()
	return _order.size()


## Ambil id berdasarkan index urutan (0-based). "" kalau di luar.
static func id_at(index: int) -> String:
	load_all()
	if index < 0 or index >= _order.size():
		return ""
	return _order[index]


static func get_by_index(index: int) -> LevelDefinition:
	var id := id_at(index)
	return get_level(id) if id != "" else null


static func all_ids() -> Array[String]:
	load_all()
	return _order.duplicate()


static func index_of(id: String) -> int:
	load_all()
	return _order.find(id)
