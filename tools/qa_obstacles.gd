extends SceneTree
## QA headless: pastikan level obstacle (ice/collectible) dari JSON benar-benar
## punya obstacle di board & damage/bring-down jalan via resolve_swap nyata.

func _init() -> void:
	LevelLoader.load_all(true)
	_qa_ice("lvl_018")
	_qa_collectible("lvl_027")
	quit()


func _count_obstacle(b: Board, otype: int) -> int:
	var n := 0
	for y in range(b.height):
		for x in range(b.width):
			if TileCodes.obstacle_type(b.get_obstacle(x, y)) == otype:
				n += 1
	return n


func _qa_ice(id: String) -> void:
	var lv := LevelLoader.get_level(id)
	var b := Board.new()
	b.setup(lv.board_width, lv.board_height, lv.colors_packed(), GameRNG.new(lv.seed),
		lv.playable_mask, lv.obstacles_for_setup())
	var ice0 := _count_obstacle(b, TileCodes.ObstacleType.ICE)
	print("%s ice_at_start=%d (expect>0)" % [id, ice0])
	# Main beberapa move valid; cek apakah ada OBSTACLE_DAMAGED/DESTROYED muncul.
	var dmg_events := 0
	var rng := GameRNG.new(lv.seed + 1)
	for i in range(30):
		var moves := b.find_possible_moves()
		if moves.is_empty():
			break
		var mv = moves[0]
		var rep := b.resolve_swap(mv["a"].x, mv["a"].y, mv["b"].x, mv["b"].y, rng)
		for s in rep.steps:
			if s.type == MoveAction.Type.OBSTACLE_DAMAGED or s.type == MoveAction.Type.OBSTACLE_DESTROYED:
				dmg_events += 1
		if dmg_events > 0:
			break
	print("%s obstacle_damage_events_seen=%d (expect>0 jika ice kena match)" % [id, dmg_events])


func _qa_collectible(id: String) -> void:
	var lv := LevelLoader.get_level(id)
	var b := Board.new()
	b.setup(lv.board_width, lv.board_height, lv.colors_packed(), GameRNG.new(lv.seed),
		lv.playable_mask, lv.obstacles_for_setup())
	var col0 := _count_obstacle(b, TileCodes.ObstacleType.COLLECTIBLE)
	print("%s collectible_at_start=%d (expect>0)" % [id, col0])
	# Main sampai ada event delivered ATAU 30 langkah.
	var delivered := 0
	var rng := GameRNG.new(lv.seed + 1)
	for i in range(30):
		var moves := b.find_possible_moves()
		if moves.is_empty():
			break
		var mv = moves[0]
		var rep := b.resolve_swap(mv["a"].x, mv["a"].y, mv["b"].x, mv["b"].y, rng)
		for s in rep.steps:
			if s.type == MoveAction.Type.OBSTACLE_DESTROYED and bool(s.data.get("delivered", false)):
				delivered += 1
	print("%s collectible_delivered_in_30_moves=%d" % [id, delivered])
