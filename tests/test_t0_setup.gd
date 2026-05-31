extends GutTest
## T0 verifikasi setup: autoload terdaftar, scene placeholder load, kontrak & encoding ada.
## Memastikan GATE FASE 0 terpenuhi secara otomatis (bukan cuma manual).


func test_autoloads_registered() -> void:
	# Autoload harus terdaftar & bisa diakses (project.godot [autoload]).
	assert_not_null(GameState, "GameState autoload harus ada")
	assert_not_null(SceneManager, "SceneManager autoload harus ada")
	assert_not_null(SaveManager, "SaveManager autoload harus ada")
	assert_not_null(AudioManager, "AudioManager autoload harus ada")
	assert_not_null(Settings, "Settings autoload harus ada")


func test_game_state_spec_fields() -> void:
	# Spec §5.1 — field & helper score_display.
	GameState.score_x2 = 10
	assert_eq(GameState.score_display(), 5, "score_display = score_x2 / 2")
	GameState.reset_level_state()
	assert_eq(GameState.score_x2, 0, "reset mengosongkan skor")
	assert_false(GameState.is_game_active, "reset menonaktifkan game")


func test_scene_manager_screen_map() -> void:
	# Semua screen_id punya path & file scene-nya ada (T0.8).
	for screen_id in ["main_menu", "level_map", "game", "meta", "settings"]:
		assert_true(SceneManager.SCREENS.has(screen_id), "screen map punya %s" % screen_id)
		var path: String = SceneManager.SCREENS[screen_id]
		assert_true(ResourceLoader.exists(path), "scene ada: %s" % path)


func test_screens_instantiable() -> void:
	# Tiap scene placeholder bisa di-load & instantiate tanpa error.
	for screen_id in SceneManager.SCREENS.keys():
		var path: String = SceneManager.SCREENS[screen_id]
		var packed: PackedScene = load(path)
		assert_not_null(packed, "load PackedScene: %s" % path)
		var inst: Node = packed.instantiate()
		assert_not_null(inst, "instantiate: %s" % path)
		inst.free()


func test_tile_codes_encode_decode() -> void:
	# Sanity encoding (uji penuh di T1.2).
	var v := TileCodes.encode(TileCodes.COLOR_3, TileCodes.SPECIAL_BOMB)
	assert_eq(TileCodes.decode_color(v), TileCodes.COLOR_3, "decode warna benar")
	assert_eq(TileCodes.decode_special(v), TileCodes.SPECIAL_BOMB, "decode special benar")
	assert_true(TileCodes.obstacle_blocks_movement(TileCodes.ObstacleType.CRATE), "crate menahan gravity")
	assert_false(TileCodes.obstacle_blocks_movement(TileCodes.ObstacleType.ICE), "ice tidak menahan")


func test_abstract_contracts_exist() -> void:
	# Kontrak abstract bisa di-instantiate (push_error saat method dipanggil — itu disengaja).
	var ob := ObstacleBase.new()
	assert_not_null(ob, "ObstacleBase ada")
	var obj := ObjectiveBase.new()
	assert_not_null(obj, "ObjectiveBase ada")
