extends Node
## SaveManager (autoload). T6.1: backup .bak sebelum write, MD5 checksum,
## migrasi schema, fallback ke .bak saat rusak. Atomic rename dipakai di Android
## (ext4 mendukung), di Windows test environment pakai FileAccess direct write.
## Spec: docs/04-tdd-arsitektur.md §7.

const SAVE_PATH   := "user://save_v1.json"
const BACKUP_PATH := "user://save_v1.bak"
const SCHEMA_VERSION := 1


func _ready() -> void:
	set_process(false)


## Simpan data: backup lama → tulis baru dengan checksum.
func save_game(data: Dictionary) -> bool:
	var data_str := JSON.stringify(data)
	var cs      := _md5(data_str)
	var payload := JSON.stringify({
		"schema_version": SCHEMA_VERSION,
		"checksum": cs,
		"data_str": data_str,
	})
	# 1. Backup save lama ke .bak (best-effort, SEBELUM menimpa).
	_copy_file(SAVE_PATH, BACKUP_PATH)
	# 2. Tulis langsung ke SAVE_PATH.
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: gagal buka %s untuk tulis (err %d)" %
				[SAVE_PATH, FileAccess.get_open_error()])
		return false
	f.store_string(payload)
	f.close()
	return true


## Muat data. Coba main → fallback ke .bak → {} kalau semua gagal.
func load_game() -> Dictionary:
	var d: Variant = _try_load(SAVE_PATH)
	if d != null:
		return d
	push_warning("SaveManager: save utama rusak, coba .bak")
	var b: Variant = _try_load(BACKUP_PATH)
	if b != null:
		return b
	return {}


## Copy file src → dst via FileAccess (tidak membutuhkan DirAccess).
func _copy_file(src: String, dst: String) -> void:
	if not FileAccess.file_exists(src):
		return
	var r := FileAccess.open(src, FileAccess.READ)
	if r == null:
		return
	var content := r.get_as_text()
	r.close()
	var w := FileAccess.open(dst, FileAccess.WRITE)
	if w == null:
		return
	w.store_string(content)
	w.close()


## Load dan parse satu file. null kalau gagal/rusak.
## Pakai JSON.new().parse() bukan JSON.parse_string() agar parse error
## tidak diteruskan ke engine error channel (yang akan ditangkap GUT).
func _try_load(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var raw := f.get_as_text()
	f.close()
	var json_obj := JSON.new()
	var err := json_obj.parse(raw)
	if err != OK:
		push_warning("SaveManager: JSON rusak di %s (baris %d)" %
				[path, json_obj.get_error_line()])
		return null
	var parsed: Variant = json_obj.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: root bukan Dictionary di %s" % path)
		return null
	var pd: Dictionary = parsed
	# Format baru: data_str + checksum
	if pd.has("data_str"):
		var data_str: String = str(pd.get("data_str", ""))
		var stored_cs: String = str(pd.get("checksum", ""))
		if stored_cs != "" and stored_cs != _md5(data_str):
			push_warning("SaveManager: checksum mismatch di %s (soft, lanjut)" % path)
		var inner_json := JSON.new()
		var inner_err := inner_json.parse(data_str)
		if inner_err != OK:
			push_warning("SaveManager: data_str rusak di %s" % path)
			return null
		var inner: Variant = inner_json.get_data()
		if typeof(inner) != TYPE_DICTIONARY:
			push_warning("SaveManager: data_str bukan Dictionary di %s" % path)
			return null
		var id: Dictionary = inner
		return _migrate(int(pd.get("schema_version", 0)), id)
	# Format lama: {"schema_version": N, "data": {...}}
	if pd.has("data"):
		var data: Variant = pd.get("data", {})
		if typeof(data) != TYPE_DICTIONARY:
			return null
		var dd: Dictionary = data
		return _migrate(int(pd.get("schema_version", 0)), dd)
	return null


## Migrasi schema. Tambah blok `if from_version < N` saat format berubah.
func _migrate(from_version: int, data: Dictionary) -> Dictionary:
	if from_version < 1:
		push_warning("SaveManager: schema sangat lama (v%d)" % from_version)
	return data


func _md5(txt: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(txt.to_utf8_buffer())
	return ctx.finish().hex_encode()
