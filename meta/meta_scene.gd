extends Control
## MetaScene — layar Pulau Lumisle. Menampilkan progress pulau + koleksi Lumi.
## Setelah menang level: island denyut + "Lanjut" ke level berikutnya.
## Jika masuk dari main menu: "Pilih Level" → level_map.

const STAGE_THRESHOLDS := [0, 5, 12]   # total bintang untuk tahap 0/1/2

@onready var _island: IslandArt = $Island
@onready var _stars_label: Label = $StarsLabel
@onready var _stage_label: Label = $StageLabel
@onready var _result_label: Label = $ResultLabel
@onready var _play_button: Button = $PlayButton
@onready var _lumi_grid: LumiGrid = $LumiGrid


func _ready() -> void:
	_render()
	_setup_play_button()
	_show_last_result()


func _render() -> void:
	var total := GameState.total_stars()
	var cleared := GameState.levels_cleared()
	var stage := _stage_for(total)
	var brightness := 0.20 + 0.40 * float(stage)
	if _island:
		_island.set_state(brightness, stage)
	if _stars_label:
		_stars_label.text = "Lumi terkumpul: %d / 30" % cleared
	if _stage_label:
		var names := ["Pulau Redup", "Pulau Bersinar", "Pulau Bercahaya"]
		_stage_label.text = "%s  (tahap %d/3)" % [names[stage], stage + 1]
	if _lumi_grid:
		_lumi_grid.setup(cleared)


func _setup_play_button() -> void:
	if not _play_button:
		return
	if GameState.next_level_id != "":
		var lv := LevelLoader.get_level(GameState.next_level_id)
		var title := lv.title if lv else GameState.next_level_id
		_play_button.text = "Lanjut: %s →" % title
	else:
		_play_button.text = "Pilih Level"


func _stage_for(total: int) -> int:
	var stage := 0
	for i in range(STAGE_THRESHOLDS.size()):
		if total >= STAGE_THRESHOLDS[i]:
			stage = i
	return stage


func _show_last_result() -> void:
	var r := GameState.last_result
	if r.is_empty() or not r.get("won", false):
		if _result_label:
			_result_label.visible = false
		return
	if _result_label:
		_result_label.visible = true
		var lid: String = r.get("level_id", "?")
		_result_label.text = "★  Level %s selesai!" % lid.replace("lvl_", "L")
	if _island:
		var t := create_tween()
		t.tween_property(_island, "brightness", minf(_island.brightness + 0.3, 1.0), 0.4)
		t.tween_property(_island, "brightness", _island.brightness, 0.6)
	GameState.last_result = {}


func _on_play_pressed() -> void:
	if GameState.next_level_id != "":
		GameState.current_level_id = GameState.next_level_id
		GameState.next_level_id = ""
		SceneManager.change_screen("game")
	else:
		SceneManager.change_screen("level_map")


func _on_back_pressed() -> void:
	GameState.next_level_id = ""
	SceneManager.change_screen("main_menu")
