extends Node
## SaveManager (autoload) — STUB di T0.7. Implementasi penuh di T6.1.
## Spec: docs/04-tdd-arsitektur.md §7 (atomic write + backup + checksum + schema_version).

const SAVE_PATH := "user://save_v1.json"
const BACKUP_PATH := "user://save_v1.bak"
const SCHEMA_VERSION := 1


func _ready() -> void:
	set_process(false)


## STUB — diisi penuh di T6.1 (atomic write .tmp -> rename, backup, checksum).
func save_game(_data: Dictionary) -> bool:
	push_warning("SaveManager.save_game belum diimplementasi (T6.1)")
	return false


## STUB — diisi penuh di T6.1 (load + fallback backup + migrasi).
func load_game() -> Dictionary:
	return {}
