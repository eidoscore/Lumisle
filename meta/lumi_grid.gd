class_name LumiGrid extends Control
## Grid Lumi 6×3 = 18 slot (Area 1: row 0, Area 2: row 1, Area 3: row 2).
## Slot terbuka = warna Lumi dengan glow pulsing. Terkunci = silhouette abu + border.
## T7.1: setup_collection() mengambil state dari LumiCollection.
## Dipakai di MetaScene sebagai $LumiGrid.

const COLS := 6
const ROWS := 3

var _t := 0.0


## Refresh state dari LumiCollection dan redraw.
func setup_collection() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cell_w := w / COLS
	var cell_h := h / ROWS
	var r_max := minf(cell_w, cell_h) * 0.36

	for area_idx in [1, 2, 3]:
		var row: int = int(area_idx) - 1
		var area_lumi := LumiCatalog.for_area(int(area_idx))
		area_lumi.sort_custom(func(a, b): return int(a["slot"]) < int(b["slot"]))

		for slot_0 in range(COLS):
			var col := slot_0
			var center := Vector2(cell_w * (col + 0.5), cell_h * (row + 0.5))
			var entry: Variant = area_lumi[slot_0] if slot_0 < area_lumi.size() else null
			if entry == null:
				continue
			var lumi_id: String = str(entry["id"])
			var is_freed := LumiCollection.is_freed(lumi_id)
			var rarity: String = str(entry.get("rarity", "common"))
			var base_color: Color = entry.get("color", Color.WHITE) as Color

			if is_freed:
				var pulse := 0.75 + 0.25 * sin(_t * 1.8 + slot_0 * 0.7 + row * 1.1)
				var glow_r := r_max * (1.6 if rarity == "epic" else 1.35 if rarity == "rare" else 1.15)
				draw_circle(center, glow_r, Color(base_color.r, base_color.g, base_color.b, 0.15 * pulse))
				draw_circle(center, r_max, Color(base_color.r, base_color.g, base_color.b, 0.90 * pulse))
				draw_circle(center, r_max * 0.35, Color(1, 1, 1, 0.90 * pulse))
				if rarity == "rare":
					draw_arc(center, r_max + 4, 0.0, TAU, 32,
						Color(1.0, 0.85, 0.3, 0.7 * pulse), 2.5)
				elif rarity == "epic":
					draw_arc(center, r_max + 5, 0.0, TAU, 48,
						Color(0.85, 0.55, 1.0, 0.8 * pulse), 3.5)
					draw_arc(center, r_max + 9, 0.0, TAU, 48,
						Color(1.0, 0.90, 0.5, 0.5 * pulse), 1.5)
			else:
				draw_circle(center, r_max, Color(0.28, 0.23, 0.38, 0.32))
				draw_arc(center, r_max, 0.0, TAU, 24, Color(0.48, 0.43, 0.60, 0.42), 1.8)
				draw_circle(center, r_max * 0.18, Color(0.48, 0.43, 0.60, 0.28))
