extends GutTest
## T1.1 — GameRNG: determinisme & helper.


func test_same_seed_same_sequence() -> void:
	var a := GameRNG.new(12345)
	var b := GameRNG.new(12345)
	for i in range(50):
		assert_eq(a.next_int(1000), b.next_int(1000), "seed sama → urutan sama (i=%d)" % i)


func test_different_seed_differs() -> void:
	var a := GameRNG.new(1)
	var b := GameRNG.new(2)
	var same := 0
	for i in range(50):
		if a.next_int(1000) == b.next_int(1000):
			same += 1
	# Sangat kecil kemungkinan semua 50 sama.
	assert_lt(same, 50, "seed beda → urutan (umumnya) beda")


func test_next_int_in_range() -> void:
	var r := GameRNG.new(7)
	for i in range(200):
		var v := r.next_int(6)
		assert_between(v, 0, 5, "next_int(6) ∈ [0,5]")


func test_next_int_zero_safe() -> void:
	var r := GameRNG.new(7)
	assert_eq(r.next_int(0), 0, "next_int(0) aman → 0")
	assert_eq(r.next_int(-5), 0, "next_int negatif aman → 0")


func test_shuffle_deterministic_and_preserves_elements() -> void:
	var arr1 := [1, 2, 3, 4, 5, 6, 7, 8]
	var arr2 := [1, 2, 3, 4, 5, 6, 7, 8]
	GameRNG.new(99).shuffle(arr1)
	GameRNG.new(99).shuffle(arr2)
	assert_eq(arr1, arr2, "shuffle seed sama → hasil sama")
	arr1.sort()
	assert_eq(arr1, [1, 2, 3, 4, 5, 6, 7, 8], "shuffle mempertahankan semua elemen")


func test_pick_packed() -> void:
	var subset := PackedInt32Array([1, 3, 5])
	var r := GameRNG.new(3)
	for i in range(50):
		var v := r.pick_packed(subset)
		assert_true(v in [1, 3, 5], "pick_packed dari subset")
