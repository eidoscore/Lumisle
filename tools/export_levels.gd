extends SceneTree
## T4.1b — Exporter `.tres` LevelDefinition → JSON pack (dok 05 §2). Authoring di
## editor (.tres) → runtime baca JSON (satu format runtime, no drift).
## Pakai: godot --headless --path . -s tools/export_levels.gd -- --src=res://data/levels/src --out=res://data/levels/handcrafted/pack.json
## Kalau --src kosong: scan res://data/levels/src/*.tres.

func _init() -> void:
	var src := "res://data/levels/src"
	var out := "res://data/levels/handcrafted/pack_from_tres.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--src="): src = a.substr(6)
		elif a.begins_with("--out="): out = a.substr(6)

	var levels: Array = []
	var dir := DirAccess.open(src)
	if dir == null:
		print("export_levels: src dir tidak ada: ", src, " (tidak ada .tres untuk diekspor — normal kalau authoring langsung JSON)")
		quit()
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	var names: Array[String] = []
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			names.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	names.sort()
	for name in names:
		var res = ResourceLoader.load(src + "/" + name)
		if res is LevelDefinition:
			levels.append(res.to_dict())
		else:
			print("  lewati (bukan LevelDefinition): ", name)
	var pack := {"schema_version": 1, "levels": levels}
	var fa := FileAccess.open(out, FileAccess.WRITE)
	fa.store_string(JSON.stringify(pack, "  "))
	fa.close()
	print("export_levels: WROTE ", out, " levels=", levels.size())
	quit()
