extends Control
## LevelMap (T6.4) — daftar level dari LevelLoader + bintang + unlock via Progression.
## Tap level → PreLevelPopup (T6.5) → konfirmasi masuk + pilih booster → game.

const PRELEVEL_SCENE := preload("res://ui/popups/prelevel_popup.tscn")

@onready var _list: VBoxContainer = $Scroll/VBox
@onready var _popup_layer: CanvasLayer = $PopupLayer
@onready var _lives_label: Label = $LivesLabel

var _active_popup: Control = null


func _ready() -> void:
	LevelLoader.load_all()
	_build_list()
	_refresh_lives()


func _refresh_lives() -> void:
	if _lives_label:
		_lives_label.text = "❤ %d / %d" % [Economy.lives, Economy.MAX_LIVES]


func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	var n := LevelLoader.count()
	for i in range(n):
		var lid := LevelLoader.id_at(i)
		var lv  := LevelLoader.get_level(lid)
		var stars  := Progression.get_stars(lid)
		var locked := not Progression.is_unlocked(lid)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(640, 96)
		btn.focus_mode = Control.FOCUS_NONE
		if locked:
			btn.text = "🔒 %s" % lv.title
			btn.disabled = true
		else:
			var star_txt := "★" if stars >= 1 else "☆"
			btn.text = "%s — %s   %s" % [lid.replace("lvl_", "L"), lv.title, star_txt]
			btn.pressed.connect(_on_level_pressed.bind(lid))
		_list.add_child(btn)
	var back := Button.new()
	back.custom_minimum_size = Vector2(640, 90)
	back.focus_mode = Control.FOCUS_NONE
	back.text = "Kembali"
	back.pressed.connect(_on_back_pressed)
	_list.add_child(back)


func _on_level_pressed(level_id: String) -> void:
	AudioManager.play_sfx("tap")
	_show_prelevel_popup(level_id)


func _show_prelevel_popup(level_id: String) -> void:
	if _active_popup != null and is_instance_valid(_active_popup):
		_active_popup.queue_free()
		_active_popup = null
	var popup: Control = PRELEVEL_SCENE.instantiate()
	_popup_layer.add_child(popup)
	_active_popup = popup
	popup.setup(level_id)
	popup.start_pressed.connect(_on_popup_start)
	popup.cancelled.connect(_on_popup_cancelled)


func _on_popup_start(level_id: String) -> void:
	_close_popup()
	GameState.current_level_id = level_id
	SceneManager.change_screen("game")


func _on_popup_cancelled() -> void:
	_close_popup()


func _close_popup() -> void:
	if _active_popup and is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = null


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
