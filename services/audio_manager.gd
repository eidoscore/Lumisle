extends Node
## AudioManager (autoload) — STUB di T0.7. Implementasi penuh di T2.6.
## Spec: docs/04-tdd-arsitektur.md §13 (pool 8-16 AudioStreamPlayer, preload SFX).

func _ready() -> void:
	set_process(false)


## STUB — diisi di T2.6 (pool player, SFX match/special/combo).
func play_sfx(_sfx_id: String) -> void:
	pass


## STUB — musik latar, diisi di T2.6/T8.7.
func play_music(_music_id: String) -> void:
	pass
