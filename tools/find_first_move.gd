extends SceneTree
## Headless helper: print valid swaps split by orientation so device testing can
## target a HORIZONTAL match (to verify left/right flick) and a VERTICAL one.

func _init() -> void:
	var w := 7
	var h := 8
	var colors := PackedInt32Array([1, 2, 3, 4, 5])
	var seed := 20260531
	var b := Board.new()
	b.setup(w, h, colors, GameRNG.new(seed))
	var moves := b.find_possible_moves()
	print("MOVES_FOUND=", moves.size())
	for mv in moves:
		var a: Vector2i = mv["a"]
		var bb: Vector2i = mv["b"]
		var orient := "H" if a.y == bb.y else "V"
		print("MOVE ", orient, " ", a, "->", bb)
	quit()
