extends Control
## LevelMap (Fase 3) — daftar 5 level vertical slice + bintang yang diperoleh.
## Pilih level → set GameState.current_level_id → GameScreen.

@onready var _list: VBoxContainer = $VBox


func _ready() -> void:
	_build_list()


func _build_list() -> void:
	# Bersihkan tombol lama (kalau scene di-reuse).
	for c in _list.get_children():
		c.queue_free()
	for i in range(LevelSet.count()):
		var lv := LevelSet.get_by_index(i)
		var lid: String = lv.get("id", str(i + 1))
		var stars: int = int(GameState.level_stars.get(lid, 0))
		var locked := _is_locked(i)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(600, 110)
		var star_txt := ("★".repeat(stars) + "☆".repeat(3 - stars)) if stars > 0 else "☆☆☆"
		if locked:
			btn.text = "🔒 Level %s" % lid
			btn.disabled = true
		else:
			btn.text = "Level %s — %s   %s" % [lid, lv.get("title", ""), star_txt]
			btn.pressed.connect(_on_level_pressed.bind(lid))
		_list.add_child(btn)
	# Tombol kembali.
	var back := Button.new()
	back.custom_minimum_size = Vector2(600, 90)
	back.text = "Kembali"
	back.pressed.connect(_on_back_pressed)
	_list.add_child(back)


## Level 0 selalu terbuka; selanjutnya terbuka kalau level sebelumnya >=1 bintang.
func _is_locked(index: int) -> bool:
	if index == 0:
		return false
	var prev := LevelSet.get_by_index(index - 1)
	return int(GameState.level_stars.get(prev.get("id", ""), 0)) == 0


func _on_level_pressed(level_id: String) -> void:
	GameState.current_level_id = level_id
	SceneManager.change_screen("game")


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
