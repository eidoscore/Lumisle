extends GutTest
## T1.13 — CollectObjective: credit dari event (dok 14 §5).


func test_collect_counts_matching_color() -> void:
	var obj := CollectObjective.new(1, 5)
	var ev := MoveAction.make(MoveAction.Type.TILE_CLEARED, [], {"colors": [1, 1, 2, 1, 3]})
	obj.credit_from_event(ev)
	assert_eq(obj.get_progress(), 3, "3 tile warna 1 dihitung")
	assert_false(obj.is_complete(), "belum lengkap (3<5)")


func test_collect_completes() -> void:
	var obj := CollectObjective.new(2, 3)
	obj.credit_from_event(MoveAction.make(MoveAction.Type.TILE_CLEARED, [], {"colors": [2, 2]}))
	obj.credit_from_event(MoveAction.make(MoveAction.Type.TILE_CLEARED, [], {"colors": [2, 1]}))
	assert_true(obj.is_complete(), "3 tile warna 2 → lengkap")
	assert_eq(obj.get_progress(), 3, "progress di-cap ke target")


func test_collect_ignores_other_events() -> void:
	var obj := CollectObjective.new(1, 5)
	obj.credit_from_event(MoveAction.make(MoveAction.Type.TILE_FELL, [], {"from": Vector2i(0,0), "to": Vector2i(0,1)}))
	obj.credit_from_event(MoveAction.make(MoveAction.Type.TILE_SPAWNED, [], {"pos": Vector2i(0,0), "color": 1}))
	assert_eq(obj.get_progress(), 0, "event non-clear tidak dihitung")
