extends Control
## MetaScene (Fase 3, T3.3) — layar Pulau Lumisle. Placeholder visual: pulau
## "redup → bercahaya" dalam 3 tahap berdasarkan total bintang terkumpul.
## Memberi "alasan main": tiap menang level → bintang → pulau makin hidup.
## Art final = Fase 7; di sini bentuk/▲ + warna saja.

const STAGE_THRESHOLDS := [0, 3, 7]   # total bintang untuk tahap 0/1/2 (maks 3 tahap)

@onready var _island: ColorRect = $Island
@onready var _glow: ColorRect = $Island/Glow
@onready var _stars_label: Label = $StarsLabel
@onready var _stage_label: Label = $StageLabel
@onready var _result_label: Label = $ResultLabel


func _ready() -> void:
	_render()
	_show_last_result()


func _render() -> void:
	var total := GameState.total_stars()
	var stage := _stage_for(total)
	# Pulau makin terang per tahap (redup=gelap → bercahaya).
	var brightness := 0.25 + 0.30 * float(stage)   # 0.25, 0.55, 0.85
	_island.color = Color(0.30 * brightness + 0.05, 0.55 * brightness + 0.05, 0.35 * brightness + 0.05, 1.0)
	_glow.color = Color(1.0, 0.95, 0.6, 0.10 + 0.18 * float(stage))
	if _stars_label:
		_stars_label.text = "Lumi (bintang): %d" % total
	if _stage_label:
		var names := ["Pulau Redup", "Pulau Bersinar", "Pulau Bercahaya"]
		_stage_label.text = "%s  (tahap %d/3)" % [names[stage], stage + 1]


func _stage_for(total: int) -> int:
	var stage := 0
	for i in range(STAGE_THRESHOLDS.size()):
		if total >= STAGE_THRESHOLDS[i]:
			stage = i
	return stage


## Kalau baru saja menang level, tampilkan ringkasan + animasi pulau "naik".
func _show_last_result() -> void:
	var r := GameState.last_result
	if r.is_empty() or not r.get("won", false):
		if _result_label:
			_result_label.visible = false
		return
	if _result_label:
		_result_label.visible = true
		_result_label.text = "Level %s selesai! +%d Lumi" % [r.get("level_id", "?"), r.get("stars", 0)]
	# Animasi glow berdenyut sekali (rasa "progress").
	if _glow:
		var t := create_tween()
		t.tween_property(_glow, "modulate:a", 1.6, 0.4)
		t.tween_property(_glow, "modulate:a", 1.0, 0.5)
	# Konsumsi hasil agar tidak diputar lagi saat balik ke meta.
	GameState.last_result = {}


func _on_play_pressed() -> void:
	SceneManager.change_screen("level_map")


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
