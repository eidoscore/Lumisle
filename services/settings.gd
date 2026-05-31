extends Node
## Settings (autoload) — STUB di T0.7. Implementasi penuh di T8.6.
## Preferensi: suara, musik, haptic, bahasa (EN default + ID). Spec: dok 09 §8.

var sfx_enabled: bool = true
var music_enabled: bool = true
var haptic_enabled: bool = true
var language: String = "en"   # "en" (default) | "id"


func _ready() -> void:
	set_process(false)


## STUB — persist preferensi via SaveManager, diisi di T8.6.
func apply() -> void:
	pass
