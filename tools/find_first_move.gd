extends SceneTree
## Headless helper: rebuild GameScreen's level board with the same seed and print a
## valid first swap (grid coords) so on-device tap testing can trigger a real match.

func _init() -> void:
	var w := 7
	var h := 8
	var colors := PackedInt32Array([1, 2, 3, 4, 5])
	var seed := 20260531
	var b := Board.new()
	b.setup(w, h, colors, GameRNG.new(seed))
	var moves := b.find_possible_moves()
	print("MOVES_FOUND=", moves.size())
	for i in range(min(3, moves.size())):
		var m = moves[i]
		print("MOVE ", i, ": ", m)
	quit()
