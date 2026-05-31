class_name TurnReport extends RefCounted
## Hasil satu giliran (replay log). View memutar ulang, tidak menghitung ulang.
## Field final: dok 14 §0.1. Acuan: docs/04-tdd-arsitektur.md §3.7.

var is_valid_swap: bool = false      # swap fisik valid (bersebelahan, playable)
var is_accepted: bool = false        # STEP C: swap menghasilkan match/aktivasi
var move_cost: int = 0               # 0 = rejected, 1 = diterima
var steps: Array[MoveAction] = []
var initial_board_hash: int = 0
var final_board_hash: int = 0
var score_delta_x2: int = 0          # skor basis x2 (dok 14 §6)
var objective_complete: bool = false
var error: String = ""               # non-empty => rollback terjadi


## Swap ditolak (tidak valid fisik / tidak menghasilkan apa-apa). Tidak makan langkah.
static func rejected() -> TurnReport:
	var r := TurnReport.new()
	r.is_valid_swap = false
	r.is_accepted = false
	r.move_cost = 0
	return r


## Turn gagal aman (board corrupt → rollback). Lihat dok 14 § error handling.
static func invalid(reason: String) -> TurnReport:
	var r := TurnReport.new()
	r.error = reason
	r.is_accepted = false
	r.move_cost = 0
	return r


func add_step(action: MoveAction) -> void:
	steps.append(action)
