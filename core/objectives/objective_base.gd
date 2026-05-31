class_name ObjectiveBase extends RefCounted
## Kontrak abstract objektif. T0.7b — interface ada di Fase 1 supaya win/lose minimal (T1.13)
## pakai kontrak yang SAMA dengan versi final → Fase 4 tinggal nambah impl, bukan rewrite.
## Acuan: docs/04-tdd-arsitektur.md §3.5, dok 14 §5 (credit dari EVENT, bukan board scan).
## Impl konkret: collect (T1.13), clear_obstacle/bring_down/score (T4.2).


## Update progress dari satu event semantik (MoveAction). Lihat dok 14 §5.
## Tidak men-scan board — murni dari event yang terjadi selama resolusi.
func credit_from_event(_action) -> void:
	push_error("ObjectiveBase.credit_from_event() abstract — override di subclass")


## Apakah objektif sudah tercapai?
func is_complete() -> bool:
	push_error("ObjectiveBase.is_complete() abstract — override di subclass")
	return false


## Progress saat ini (untuk HUD).
func get_progress() -> int:
	push_error("ObjectiveBase.get_progress() abstract — override di subclass")
	return 0


## Target yang harus dicapai (untuk HUD).
func get_target() -> int:
	push_error("ObjectiveBase.get_target() abstract — override di subclass")
	return 0
