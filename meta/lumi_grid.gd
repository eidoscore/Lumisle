class_name LumiGrid extends Control
## Grid Lumi 3×6 = 18 slot. Lit = level cleared (sequential, 1 per level won).
## Silhouette = belum dikumpulkan. Dipakai di MetaScene (dok GDD §6.1.1).

var _collected := 0
var _t := 0.0


func setup(collected: int) -> void:
	_collected = clampi(collected, 0, 18)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	const COLS := 6
	const ROWS := 3
	var w := size.x
	var h := size.y
	var cell_w := w / COLS
	var cell_h := h / ROWS
	var r := minf(cell_w, cell_h) * 0.34
	for i in range(ROWS * COLS):
		var col := i % COLS
		var row := i / COLS
		var center := Vector2(cell_w * (col + 0.5), cell_h * (row + 0.5))
		if i < _collected:
			var pulse := 0.75 + 0.25 * sin(_t * 1.8 + i * 0.7)
			draw_circle(center, r * 1.5, Color(1.0, 0.95, 0.55, 0.12 * pulse))
			draw_circle(center, r, Color(1.0, 0.95, 0.60, 0.9 * pulse))
			draw_circle(center, r * 0.38, Color(1, 1, 1, 0.95 * pulse))
		else:
			draw_circle(center, r, Color(0.38, 0.32, 0.50, 0.28))
			draw_arc(center, r, 0.0, TAU, 24, Color(0.55, 0.50, 0.68, 0.45), 1.8)
			# tanda tanya di tengah (simbol Lumi belum ketemu)
			draw_circle(center, r * 0.18, Color(0.55, 0.50, 0.68, 0.30))
