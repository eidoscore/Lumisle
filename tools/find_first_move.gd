extends SceneTree
## Headless helper: rebuild GameScreen's level board with the same seed and print a
## valid first swap (grid coords) + the top rows, so on-device tap testing can target
## both a real match and a same-color (invalid) pair.

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
		print("MOVE ", i, ": ", moves[i])
	# Cetak 3 baris atas untuk cari pasangan warna sama bersebelahan (swap invalid).
	for y in range(min(3, h)):
		var row := ""
		for x in range(w):
			row += str(b.get_color(x, y)) + " "
		print("ROW ", y, ": ", row)
	quit()
