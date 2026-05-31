extends Node
## SceneManager (autoload) — navigasi/transisi antar screen + app lifecycle.
## Spec: docs/04-tdd-arsitektur.md §5.2 & §14. T0.8 mengisi transisi & screen map.
## Lifecycle (T6.7) mengisi auto-save + recompute nyawa offline.

# Peta screen_id -> path scene. Diisi di T0.8 saat scene placeholder dibuat.
const SCREENS := {
	"main_menu": "res://ui/main_menu.tscn",
	"level_map": "res://ui/level_map.tscn",
	"game": "res://view/game_screen.tscn",
	"meta": "res://meta/meta_scene.tscn",
	"settings": "res://ui/settings.tscn",
}

var _current_screen_id: String = ""
var _active_popups: Array[Node] = []


func _ready() -> void:
	# SceneManager butuh menerima notifikasi lifecycle, tapi tidak butuh _process per-frame.
	set_process(false)


## Ganti screen utama (menu/map/game/meta/settings). Transisi fade diisi di T0.8.
func change_screen(screen_id: String, params: Dictionary = {}) -> void:
	if not SCREENS.has(screen_id):
		push_error("SceneManager: screen_id tidak dikenal: %s" % screen_id)
		return
	var path: String = SCREENS[screen_id]
	if not ResourceLoader.exists(path):
		push_error("SceneManager: scene belum ada: %s (dibuat di T0.8)" % path)
		return
	_current_screen_id = screen_id
	# T0.8: fade out -> change_scene_to_file(path) -> fade in. params diteruskan via GameState.
	get_tree().change_scene_to_file(path)


## Overlay popup di atas screen aktif (CanvasLayer). Diisi di T0.8/Fase 6.
func push_popup(popup_scene: PackedScene, _params: Dictionary = {}) -> void:
	if popup_scene == null:
		push_error("SceneManager: popup_scene null")
		return
	var inst := popup_scene.instantiate()
	get_tree().root.add_child(inst)
	_active_popups.append(inst)


## Back button Android / tombol kembali.
func go_back() -> void:
	# Prioritas: tutup popup aktif dulu; kalau in-game konfirmasi; di menu keluar app.
	if not _active_popups.is_empty():
		var p: Node = _active_popups.pop_back()
		if is_instance_valid(p):
			p.queue_free()
		return
	if GameState.is_game_active:
		# T6.x: tampilkan konfirmasi keluar level. Skeleton: kembali ke level_map.
		change_screen("level_map")
		return
	if _current_screen_id == "main_menu" or _current_screen_id == "":
		get_tree().quit()
	else:
		change_screen("main_menu")


func _notification(what: int) -> void:
	# Lifecycle mobile (skeleton T0.8, isi penuh T6.7 — dok 04 §14.4).
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_GO_BACK_REQUEST:
			# T6.7: auto-save + pause audio. Nyawa/daily via timestamp, bukan timer.
			pass
		NOTIFICATION_APPLICATION_RESUMED:
			# T6.7: recompute nyawa offline (selisih waktu) + resume audio.
			pass
