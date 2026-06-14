extends Control
## SettingsScreen — toggle SFX/musik/haptic dengan persist via SaveManager.

@onready var _sfx_btn: Button = $ToggleList/SfxRow/SfxButton
@onready var _music_btn: Button = $ToggleList/MusicRow/MusicButton
@onready var _haptic_btn: Button = $ToggleList/HapticRow/HapticButton


func _ready() -> void:
	_load_prefs()
	_refresh_buttons()


func _load_prefs() -> void:
	var data := SaveManager.load_game()
	var prefs: Dictionary = data.get("settings", {})
	Settings.sfx_enabled = prefs.get("sfx", true)
	Settings.music_enabled = prefs.get("music", true)
	Settings.haptic_enabled = prefs.get("haptic", true)
	AudioManager.set_enabled(Settings.sfx_enabled)
	AudioManager.set_music_enabled(Settings.music_enabled)


func _save_prefs() -> void:
	var data := SaveManager.load_game()
	data["settings"] = {
		"sfx": Settings.sfx_enabled,
		"music": Settings.music_enabled,
		"haptic": Settings.haptic_enabled,
	}
	SaveManager.save_game(data)


func _refresh_buttons() -> void:
	_sfx_btn.text = "ON" if Settings.sfx_enabled else "OFF"
	_music_btn.text = "ON" if Settings.music_enabled else "OFF"
	_haptic_btn.text = "ON" if Settings.haptic_enabled else "OFF"


func _on_sfx_toggled() -> void:
	Settings.sfx_enabled = not Settings.sfx_enabled
	_save_prefs()
	_refresh_buttons()


func _on_music_toggled() -> void:
	Settings.music_enabled = not Settings.music_enabled
	AudioManager.set_music_enabled(Settings.music_enabled)
	_save_prefs()
	_refresh_buttons()


func _on_haptic_toggled() -> void:
	Settings.haptic_enabled = not Settings.haptic_enabled
	_save_prefs()
	_refresh_buttons()


func _on_back_pressed() -> void:
	SceneManager.change_screen("main_menu")
