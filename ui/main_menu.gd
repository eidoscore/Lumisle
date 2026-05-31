extends Control
## Placeholder MainMenu (T0.8). Navigasi dasar; UI final menyusul.

func _on_play_pressed() -> void:
	SceneManager.change_screen("level_map")


func _on_settings_pressed() -> void:
	SceneManager.change_screen("settings")


func _on_meta_pressed() -> void:
	SceneManager.change_screen("meta")
