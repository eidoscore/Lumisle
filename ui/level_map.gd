extends Control
## Placeholder LevelMap (T0.8). Pilih level → GameScreen.

func _on_play_level_pressed() -> void:
	# Fase 4+: set GameState.current_level_id. Placeholder: langsung ke game.
	SceneManager.change_screen("game")


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
