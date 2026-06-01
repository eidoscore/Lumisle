extends SceneTree
## T5.7 — Validasi pack generated: tiap level loadable (from_dict), board bisa di-setup,
## tanpa match awal, ada move valid. Spot-check kurasi (dok 05 §5.6, §7).
## Pakai: godot --headless --path . -s tools/validate_pack.gd -- --pack=res://data/levels/generated/pack_101_104.json

func _init() -> void:
	var pack_path := "res://data/levels/generated/pack_101_104.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pack="):
			pack_path = a.substr(7)
	if not FileAccess.file_exists(pack_path):
		print("ERR pack tidak ada: ", pack_path); quit(1); return
	var txt := FileAccess.open(pack_path, FileAccess.READ).get_as_text()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("ERR JSON invalid"); quit(1); return

	var levels: Array = parsed.get("levels", [])
	var ok := 0
	var fail := 0
	for lvd in levels:
		var lv := LevelDefinition.from_dict(lvd)
		var board := Board.new()
		board.setup(lv.board_width, lv.board_height, lv.colors_packed(),
			GameRNG.new(lv.seed), lv.playable_mask, lv.obstacles_for_setup())
		var problems: Array = []
		if MatchDetector.has_any_match(board):
			problems.append("initial_match")
		if board.find_possible_moves().is_empty():
			problems.append("no_moves")
		if lv.move_limit < 8 or lv.move_limit > 60:
			problems.append("move_limit_oob(%d)" % lv.move_limit)
		if lv.objectives.is_empty():
			problems.append("no_objective")
		if problems.is_empty():
			ok += 1
			print("OK   %s  arch=%s ml=%d wr=%s" % [lv.id, lvd.get("archetype",""), lv.move_limit, str(lvd.get("estimated_winrate",""))])
		else:
			fail += 1
			print("FAIL %s  %s" % [lv.id, ", ".join(problems)])
	print("\n=== %d OK / %d FAIL dari %d level ===" % [ok, fail, levels.size()])
	quit(0 if fail == 0 else 1)
