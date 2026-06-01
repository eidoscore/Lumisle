extends Control
## LevelMap (Fase 4) — daftar level dari LevelLoader (JSON, 30 level kurikulum) +
## bintang + unlock bertahap. Scrollable. Pilih → set current_level_id → GameScreen.

@onready var _list: VBoxContainer = $Scroll/VBox


func _ready() -> void:
	LevelLoader.load_all()
	_build_list()


func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var n := LevelLoader.count()
	for i in range(n):
		var lid := LevelLoader.id_at(i)
		var lv := LevelLoader.get_level(lid)
		var stars: int = int(GameState.level_stars.get(lid, 0))
		var locked := _is_locked(i)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(640, 96)
		btn.focus_mode = Control.FOCUS_NONE
		var star_txt := ("★".repeat(stars) + "☆".repeat(3 - stars)) if stars > 0 else "☆☆☆"
		if locked:
			btn.text = "🔒 %s" % lv.title
			btn.disabled = true
		else:
			btn.text = "%s — %s   %s" % [lid.replace("lvl_", "L"), lv.title, star_txt]
			btn.pressed.connect(_on_level_pressed.bind(lid))
		_list.add_child(btn)
	var back := Button.new()
	back.custom_minimum_size = Vector2(640, 90)
	back.focus_mode = Control.FOCUS_NONE
	back.text = "Kembali"
	back.pressed.connect(_on_back_pressed)
	_list.add_child(back)


## Level 0 selalu terbuka; selanjutnya terbuka kalau level sebelumnya >=1 bintang.
func _is_locked(index: int) -> bool:
	if index == 0:
		return false
	var prev_id := LevelLoader.id_at(index - 1)
	return int(GameState.level_stars.get(prev_id, 0)) == 0


func _on_level_pressed(level_id: String) -> void:
	GameState.current_level_id = level_id
	SceneManager.change_screen("game")


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
