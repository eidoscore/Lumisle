extends Node
## Analytics (autoload) — T3.4. Logger LOKAL untuk playtest vertical slice.
## Catat event ke user://analytics.jsonl (JSON-lines) untuk ditinjau setelah sesi.
## Struktur event acuan: dok 09 §7. Belum kirim ke server (itu T8.5).
##
## Event yang dicatat (Fase 3): level_start, level_complete, level_fail,
## move (moves_left), session_start. Tiap baris = 1 JSON object + timestamp.

const LOG_PATH := "user://analytics.jsonl"

var _session_id: int = 0
var _enabled := true


func _ready() -> void:
	set_process(false)
	_session_id = int(Time.get_unix_time_from_system())
	log_event("session_start", {})


## Catat satu event. data = dict properti tambahan.
func log_event(event: String, data: Dictionary) -> void:
	if not _enabled:
		return
	var row := {
		"t": Time.get_unix_time_from_system(),
		"session": _session_id,
		"event": event,
	}
	for k in data:
		row[k] = data[k]
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()


## Baca semua event (untuk debug HUD / review). Kembalikan Array of Dictionary.
func read_all() -> Array:
	var out: Array = []
	if not FileAccess.file_exists(LOG_PATH):
		return out
	var f := FileAccess.open(LOG_PATH, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line()
		if line.strip_edges() == "":
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) == TYPE_DICTIONARY:
			out.append(parsed)
	f.close()
	return out


## Kosongkan log (mis. mulai sesi playtest bersih).
func clear_log() -> void:
	if FileAccess.file_exists(LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LOG_PATH))
