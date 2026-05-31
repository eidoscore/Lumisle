extends GutTest
## T0.4 — Smoke test. Membuktikan GUT terpasang & runner (editor + headless CLI) jalan.
## Acuan: docs/13-implementation-plan.md T0.4.


func test_gut_is_working() -> void:
	# Assert paling sederhana — kalau ini lulus, pipeline test sehat.
	assert_eq(1 + 1, 2, "Aritmatika dasar harus benar")


func test_string_basics() -> void:
	assert_eq("lumi" + "sle", "lumisle", "Concat string harus benar")


func test_true_is_true() -> void:
	assert_true(true, "true harus true")
