class_name TileGfx extends Control
## Visual SATU tile. Menggantikan ColorRect polos (dok 07 §2.3: tiap warna WAJIB
## punya BENTUK unik, bukan cuma beda warna → aksesibilitas buta-warna + keterbacaan
## <1 detik). Digambar prosedural (aksen, dok 07 §2.0) = "permata cahaya": bentuk
## berisi gradien + kilau + outline, glyph ikon untuk special.
##
## API kompatibel dgn cara BoardView memanipulasi tile (position/scale/modulate/
## visible/pivot_offset/size) karena ini Control biasa.

# Bentuk per kode warna 1..6 (urutan = TileCodes.COLOR_1..6).
enum Shape { CIRCLE, SQUARE, TRIANGLE, DIAMOND, PENTAGON, HEXAGON }

const _SHAPE_FOR_COLOR := [
	Shape.CIRCLE,    # 0 (tak dipakai; empty)
	Shape.CIRCLE,    # 1 merah
	Shape.SQUARE,    # 2 biru
	Shape.TRIANGLE,  # 3 hijau
	Shape.DIAMOND,   # 4 kuning
	Shape.PENTAGON,  # 5 ungu
	Shape.HEXAGON,   # 6 oranye
]

var color_code: int = 0          # 0 = empty, 1..6
var special_type: int = 0        # TileCodes.SPECIAL_*
var base_color: Color = Color(0, 0, 0, 0)
var is_blocker: bool = false     # box/crate menahan gerak
var is_empty_slot: bool = false  # sel playable tapi sedang kosong (lubang halus)


func set_tile(p_color: int, p_special: int, p_base: Color, p_blocker: bool, p_empty: bool) -> void:
	color_code = p_color
	special_type = p_special
	base_color = p_base
	is_blocker = p_blocker
	is_empty_slot = p_empty
	queue_redraw()


func _draw() -> void:
	var s := size.x
	var center := size * 0.5

	if is_blocker:
		_draw_blocker(s)
		return
	if is_empty_slot:
		# slot kosong: bayangan lembut supaya grid tetap terbaca.
		_draw_round_rect(Rect2(s * 0.12, s * 0.12, s * 0.76, s * 0.76), s * 0.14, Color(0, 0, 0, 0.10))
		return
	if color_code <= 0:
		return

	var pad := s * 0.10
	var r := (s * 0.5) - pad
	var shape: int = _SHAPE_FOR_COLOR[color_code] if color_code < _SHAPE_FOR_COLOR.size() else Shape.CIRCLE

	var fill := base_color
	var edge := base_color.darkened(0.42)
	var inner := base_color.lightened(0.12)

	# Bayangan halus di bawah (kedalaman).
	_draw_shape(shape, center + Vector2(0, s * 0.045), r, Color(0, 0, 0, 0.18))
	# Badan permata: outline gelap → isi → inti terang.
	_draw_shape(shape, center, r, edge)
	_draw_shape(shape, center, r * 0.92, fill)
	_draw_shape(shape, center - Vector2(0, r * 0.10), r * 0.55, inner)
	# Kilau (gloss) kiri-atas → kesan permata mengilap.
	draw_circle(center - Vector2(r * 0.30, r * 0.42), r * 0.22, Color(1, 1, 1, 0.42))

	# Special: lingkaran cahaya + glyph digambar oleh marker Label (BoardView).
	if special_type != 0:
		draw_arc(center, r * 1.02, 0, TAU, 32, Color(1, 1, 1, 0.85), s * 0.05, true)


func _draw_shape(shape: int, c: Vector2, r: float, col: Color) -> void:
	match shape:
		Shape.CIRCLE:
			draw_circle(c, r, col)
		Shape.SQUARE:
			_draw_round_rect(Rect2(c.x - r * 0.88, c.y - r * 0.88, r * 1.76, r * 1.76), r * 0.28, col)
		_:
			draw_colored_polygon(_polygon_for(shape, c, r), col)


## Polygon teratur untuk segitiga/diamond/pentagon/hexagon (puncak di atas).
func _polygon_for(shape: int, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var sides := 3
	match shape:
		Shape.TRIANGLE: sides = 3
		Shape.DIAMOND:  sides = 4
		Shape.PENTAGON: sides = 5
		Shape.HEXAGON:  sides = 6
		_:              sides = 4
	# Diamond = persegi diputar 45°; lainnya puncak di atas (-PI/2).
	var start := -PI / 2.0
	var bump := 1.12 if shape == Shape.TRIANGLE else 1.0   # segitiga sedikit lebih besar agar terisi
	for i in range(sides):
		var a := start + TAU * float(i) / float(sides)
		pts.append(c + Vector2(cos(a), sin(a)) * r * bump)
	return pts


func _draw_round_rect(rect: Rect2, radius: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	draw_style_box(sb, rect)


func _draw_blocker(s: float) -> void:
	# Box/crate: kayu coklat dengan papan & paku.
	var rect := Rect2(s * 0.06, s * 0.06, s * 0.88, s * 0.88)
	_draw_round_rect(rect, s * 0.10, Color(0.45, 0.32, 0.20))
	_draw_round_rect(Rect2(s * 0.12, s * 0.12, s * 0.76, s * 0.76), s * 0.07, Color(0.58, 0.42, 0.26))
	# Garis papan diagonal.
	draw_line(Vector2(s * 0.14, s * 0.86), Vector2(s * 0.86, s * 0.14), Color(0.40, 0.28, 0.17), s * 0.05)
