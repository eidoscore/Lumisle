class_name Score extends RefCounted
## T4.2 — Skoring deterministik, INT MURNI (dok 14 §6). Fungsi murni static.
## Basis ×2 untuk hindari float: base 20 (=10×2) per tile clear. Cascade multiplier int:
## cascade ke-n → faktor (n+1). Bonus special (basis ×2). Bagi 2 HANYA saat display.
## TERPISAH dari objective (objective tipe "score" memakainya).

const BASE_PER_TILE_X2 := 20
const BONUS_ROCKET_X2 := 100
const BONUS_BOMB_X2 := 160
const BONUS_COLORBOMB_X2 := 240
const BONUS_PROPELLER_X2 := 120


## Delta skor (×2) dari satu MoveAction event + cascade index (0-based).
## cascade_index 0 = gelombang pertama → faktor (0+1)=1 ... dok 14 §6.
static func delta_for_event(action, cascade_index: int) -> int:
	match action.type:
		MoveAction.Type.TILE_CLEARED:
			var n: int = action.positions.size()
			return n * BASE_PER_TILE_X2 * (cascade_index + 1)
		MoveAction.Type.SPECIAL_CREATED:
			return _special_bonus_x2(int(action.data.get("special_type", 0)))
		_:
			return 0


## Total skor (×2) dari seluruh TurnReport.
static func delta_for_report(report) -> int:
	var total := 0
	var cascade := 0
	for step in report.steps:
		if step.type == MoveAction.Type.TILE_CLEARED:
			total += step.positions.size() * BASE_PER_TILE_X2 * (cascade + 1)
			cascade += 1
		elif step.type == MoveAction.Type.SPECIAL_CREATED:
			total += _special_bonus_x2(int(step.data.get("special_type", 0)))
	return total


static func _special_bonus_x2(special_type: int) -> int:
	match special_type:
		TileCodes.SPECIAL_ROCKET_H, TileCodes.SPECIAL_ROCKET_V:
			return BONUS_ROCKET_X2
		TileCodes.SPECIAL_BOMB:
			return BONUS_BOMB_X2
		TileCodes.SPECIAL_COLORBOMB:
			return BONUS_COLORBOMB_X2
		TileCodes.SPECIAL_PROPELLER:
			return BONUS_PROPELLER_X2
		_:
			return 0


## Nilai display (basis ×2 → asli). Dipakai HUD.
static func to_display(score_x2: int) -> int:
	return score_x2 / 2
