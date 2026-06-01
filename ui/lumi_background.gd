class_name LumiBackground extends Control
## Latar prosedural (dok 07 §2.0 — prosedural = AKSEN, bukan fondasi). Gradien
## langit senja pulau + Lumi (roh cahaya) melayang. Dipakai di menu/meta/peta agar
## tidak lagi "polos bawaan Godot". Murah: hanya _draw + sedikit tween.

@export var top_color: Color = Color(0.16, 0.13, 0.30)      # ungu langit atas
@export var bottom_color: Color = Color(0.36, 0.22, 0.40)   # magenta-senja bawah
@export var lumi_count: int = 14

var _lumis: Array = []   # {pos:Vector2, r:float, phase:float, speed:float, hue:Color}
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_spawn_lumis()
	resized.connect(_spawn_lumis)


func _spawn_lumis() -> void:
	_lumis.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var w := maxf(size.x, 1080.0)
	var h := maxf(size.y, 1920.0)
	var hues := [
		Color(1.0, 0.85, 0.55), Color(0.6, 0.85, 1.0), Color(0.8, 1.0, 0.7),
		Color(1.0, 0.7, 0.85), Color(0.85, 0.7, 1.0),
	]
	for i in range(lumi_count):
		_lumis.append({
			"pos": Vector2(rng.randf() * w, rng.randf() * h),
			"r": rng.randf_range(4.0, 14.0),
			"phase": rng.randf() * TAU,
			"speed": rng.randf_range(0.3, 0.9),
			"drift": rng.randf_range(8.0, 26.0),
			"hue": hues[i % hues.size()],
		})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Gradien vertikal (band tipis → murah & mulus).
	var bands := 24
	for i in range(bands):
		var f := float(i) / float(bands - 1)
		var col := top_color.lerp(bottom_color, f)
		draw_rect(Rect2(0, h * float(i) / bands, w, h / bands + 1.0), col)
	# Halo besar di tengah-bawah (cahaya pulau).
	var glow_c := Vector2(w * 0.5, h * 0.72)
	for k in range(6):
		var rr := w * (0.18 + 0.07 * k)
		draw_circle(glow_c, rr, Color(1.0, 0.9, 0.6, 0.04))
	# Lumi melayang berdenyut.
	for lm in _lumis:
		var pos: Vector2 = lm["pos"]
		var drift: float = lm["drift"]
		var off := Vector2(sin(_t * lm["speed"] + lm["phase"]) * drift,
			cos(_t * lm["speed"] * 0.7 + lm["phase"]) * drift)
		var p := pos + off
		var pulse := 0.6 + 0.4 * sin(_t * 1.6 + lm["phase"])
		var hue: Color = lm["hue"]
		var r: float = lm["r"]
		# Halo lembut + inti terang.
		draw_circle(p, r * 2.6, Color(hue.r, hue.g, hue.b, 0.10 * pulse))
		draw_circle(p, r * 1.5, Color(hue.r, hue.g, hue.b, 0.18 * pulse))
		draw_circle(p, r, Color(1, 1, 1, 0.85 * pulse))
