extends Node
## Settings (autoload) — STUB di T0.7. Implementasi penuh di T8.6.
## Preferensi: suara, musik, haptic, bahasa (EN default + ID). Spec: dok 09 §8.

var sfx_enabled: bool = true
var music_enabled: bool = true
var haptic_enabled: bool = true
var language: String = "en"   # "en" (default) | "id"


func _ready() -> void:
	set_process(false)
	_load()


func _load() -> void:
	var data := SaveManager.load_game()
	var prefs: Dictionary = data.get("settings", {})
	sfx_enabled = prefs.get("sfx", true)
	music_enabled = prefs.get("music", true)
	haptic_enabled = prefs.get("haptic", true)


func apply() -> void:
	AudioManager.set_enabled(sfx_enabled)
	AudioManager.set_music_enabled(music_enabled)
