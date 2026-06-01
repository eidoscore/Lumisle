class_name IslandArt extends Control
## Pulau Lumisle prosedural (dok 07 §6 + §2.0). Menggantikan ColorRect polos:
## siluet pulau melayang (tanah + rumput + pohon cahaya + air bawah) yang
## "redup → bercahaya" sesuai `brightness`/`stage`. Murah (_draw saja).

var brightness: float = 0.25 : set = _set_brightness   # 0..1
var stage: int = 0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_brightness(v: float) -> void:
	brightness = clampf(v, 0.0, 1.0)
	queue_redraw()


func set_state(p_brightness: float, p_stage: int) -> void:
	stage = p_stage
	brightness = clampf(p_brightness, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()   # untuk denyut Lumi + bob pulau


func _draw() -> void:
	var w := size.x
	var h := size.y
	var b := brightness
	var cx := w * 0.5
	# Pulau "mengapung" naik-turun halus.
	var bob := sin(_t * 1.1) * h * 0.012

	# Halo cahaya di belakang pulau (makin terang per tahap).
	for k in range(8):
		var rr := w * (0.22 + 0.055 * k)
		draw_circle(Vector2(cx, h * 0.42 + bob), rr, Color(1.0, 0.92, 0.6, (0.02 + 0.05 * b)))

	# --- Badan tanah pulau (bentuk membulat + dasar meruncing) ---
	var top_y := h * 0.34 + bob
	var grass_col := Color(0.30, 0.62, 0.34).lerp(Color(0.45, 0.85, 0.45), b)
	var soil_col := Color(0.36, 0.24, 0.16).lerp(Color(0.52, 0.36, 0.22), b)

	# Dasar tanah (segitiga membulat ke bawah).
	var soil := PackedVector2Array([
		Vector2(cx - w * 0.34, top_y + h * 0.06),
		Vector2(cx + w * 0.34, top_y + h * 0.06),
		Vector2(cx + w * 0.16, top_y + h * 0.30),
		Vector2(cx, top_y + h * 0.42),
		Vector2(cx - w * 0.16, top_y + h * 0.30),
	])
	draw_colored_polygon(soil, soil_col)

	# Permukaan rumput (elips di atas tanah).
	_draw_ellipse(Vector2(cx, top_y), w * 0.36, h * 0.10, grass_col)
	_draw_ellipse(Vector2(cx, top_y - h * 0.012), w * 0.30, h * 0.075, grass_col.lightened(0.12))

	# --- Pohon cahaya (batang + kanopi bercahaya) ---
	_draw_tree(Vector2(cx - w * 0.10, top_y - h * 0.02), w * 0.12, b)
	_draw_tree(Vector2(cx + w * 0.14, top_y + h * 0.00), w * 0.09, b * 0.9)

	# --- Lumi melayang di atas pulau (jumlah naik per tahap) ---
	var lumi_n := 2 + stage * 2
	for i in range(lumi_n):
		var ang := _t * 0.6 + float(i) * (TAU / float(maxi(lumi_n, 1)))
		var lp := Vector2(cx + cos(ang) * w * 0.26, top_y - h * 0.06 + sin(ang * 1.3) * h * 0.05)
		var pulse := 0.6 + 0.4 * sin(_t * 2.0 + i)
		draw_circle(lp, w * 0.03, Color(1, 0.95, 0.7, 0.18 * pulse))
		draw_circle(lp, w * 0.014, Color(1, 1, 1, (0.5 + 0.5 * b) * pulse))


func _draw_tree(base: Vector2, scale_w: float, b: float) -> void:
	var trunk_col := Color(0.34, 0.22, 0.14).lerp(Color(0.5, 0.34, 0.2), b)
	var leaf_col := Color(0.25, 0.5, 0.3).lerp(Color(0.5, 0.95, 0.55), b)
	# Batang.
	draw_rect(Rect2(base.x - scale_w * 0.10, base.y - scale_w * 0.9, scale_w * 0.20, scale_w * 0.9), trunk_col)
	# Kanopi (3 gumpalan).
	draw_circle(base + Vector2(0, -scale_w * 1.1), scale_w * 0.55, leaf_col)
	draw_circle(base + Vector2(-scale_w * 0.4, -scale_w * 0.85), scale_w * 0.42, leaf_col)
	draw_circle(base + Vector2(scale_w * 0.4, -scale_w * 0.85), scale_w * 0.42, leaf_col)
	# Sentuhan cahaya di kanopi saat terang.
	draw_circle(base + Vector2(0, -scale_w * 1.2), scale_w * 0.22, Color(1, 1, 0.8, 0.25 * b))


func _draw_ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var seg := 28
	for i in range(seg):
		var a := TAU * float(i) / float(seg)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
