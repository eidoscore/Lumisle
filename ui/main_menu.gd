extends Control
## MainMenu (skin Fase 4.5) — latar prosedural Lumi + judul berdenyut + tombol bertema.
## Navigasi dasar tetap sama (Play/Meta/Settings).

@onready var _title: Label = $TitlePanel/Title


func _ready() -> void:
	if _title:
		_title.pivot_offset = _title.size * 0.5
		var t := create_tween().set_loops()
		t.tween_property(_title, "scale", Vector2(1.04, 1.04), 1.6).set_trans(Tween.TRANS_SINE)
		t.tween_property(_title, "scale", Vector2(1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	AudioManager.play_sfx("tap")
	SceneManager.change_screen("level_map")


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("tap")
	SceneManager.change_screen("settings")


func _on_meta_pressed() -> void:
	AudioManager.play_sfx("tap")
	SceneManager.change_screen("meta")
