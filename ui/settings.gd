extends Control
## Placeholder SettingsScreen (T0.8). Isi penuh T8.6 (suara/musik/haptic/bahasa).

func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
