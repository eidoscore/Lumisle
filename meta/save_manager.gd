extends Node
## SaveManager (autoload). Implementasi MINIMAL fungsional untuk vertical slice (T3.3):
## simpan/baca progress (bintang) ke user://save_v1.json.
## CATATAN SCOPE: versi PENUH (atomic write .tmp→rename, backup .bak, checksum,
## migrasi schema) = Fase 6 (T6.1). Di sini cukup write JSON langsung + load aman.
## Spec final: docs/04-tdd-arsitektur.md §7.

const SAVE_PATH := "user://save_v1.json"
const BACKUP_PATH := "user://save_v1.bak"
const SCHEMA_VERSION := 1


func _ready() -> void:
	set_process(false)


## Simpan data progress. T6.1 akan menambah atomic+backup+checksum.
func save_game(data: Dictionary) -> bool:
	var payload := {"schema_version": SCHEMA_VERSION, "data": data}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: gagal buka %s untuk tulis" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	return true


## Muat data progress. Kembalikan isi `data` (Dictionary kosong kalau belum ada/rusak).
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save rusak/format salah — abaikan")
		return {}
	var data = parsed.get("data", {})
	return data if typeof(data) == TYPE_DICTIONARY else {}
