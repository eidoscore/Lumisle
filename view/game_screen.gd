extends Control
## Placeholder GameScreen (T0.8). Struktur sesuai dok 04 §14.2:
## GameScreen > BoardView (TileLayer/SpecialLayer/ObstacleLayer/EffectsLayer) + HUD + PopupLayer.
## Logika board nyata diisi di T1.11. Di T0.8 hanya skeleton + navigasi.

func _ready() -> void:
	GameState.is_game_active = true


func _on_back_pressed() -> void:
	GameState.is_game_active = false
	SceneManager.change_screen("level_map")


func _on_win_pressed() -> void:
	# Placeholder: simulasi menang → ke Meta (alur dok 04 §14.1).
	GameState.is_game_active = false
	SceneManager.change_screen("meta")
