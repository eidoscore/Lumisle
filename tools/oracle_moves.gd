extends SceneTree
## Oracle: baca grid dari argumen (string 8 baris dipisah '/'), pakai ENGINE ASLI
## (Board + MatchDetector) untuk daftar move valid. Dipanggil harness Python.
## Argumen: --grid=<row0/row1/.../row7> dengan char R/B/G/Y/P/O/. (atau angka 1-6,0).

func _init() -> void:
	var grid_arg := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--grid="):
			grid_arg = a.substr(7)
	if grid_arg == "":
		print("ERR no grid"); quit(); return
	var rows := grid_arg.split("/")
	var name2num := {"R":1,"B":2,"G":3,"Y":4,"P":5,"O":6,".":0}
	var gridrows: Array = []
	for r in rows:
		var s := ""
		for ch in r:
			s += str(name2num.get(ch, 0))
		gridrows.append(s)
	var b := BoardTestHelper.from_grid(gridrows)
	var sym := {1:"R",2:"B",3:"G",4:"Y",5:"P",6:"O",0:"."}
	print("HAS_MATCH=", MatchDetector.has_any_match(b))
	for mv in b.find_possible_moves():
		var a: Vector2i = mv["a"]
		var bb: Vector2i = mv["b"]
		print("MOVE %d,%d %d,%d" % [a.x, a.y, bb.x, bb.y])
	quit()
