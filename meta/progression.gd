extends Node
## Progression (autoload T6.3) — API unlock level berurutan + bintang.
## Delegasi storage ke GameState (level_stars) yang persist via SaveManager.
## Tujuan: centralkan logic unlock agar LevelMap & scene lain tidak hardcode aturan.


func _ready() -> void:
	set_process(false)


## True kalau level_id boleh dimainkan (index 0 = selalu terbuka; selanjutnya butuh prev >=1★).
func is_unlocked(level_id: String) -> bool:
	LevelLoader.load_all()
	var i := LevelLoader.index_of(level_id)
	if i <= 0:
		return true
	var prev_id := LevelLoader.id_at(i - 1)
	return int(GameState.level_stars.get(prev_id, 0)) >= 1


## Bintang untuk level_id (0 kalau belum selesai).
func get_stars(level_id: String) -> int:
	return int(GameState.level_stars.get(level_id, 0))


## Jumlah level yang sudah diselesaikan (>=1★).
func levels_cleared() -> int:
	return GameState.level_stars.size()


## Total bintang terkumpul semua level.
func total_stars() -> int:
	return GameState.total_stars()


## Indeks level terakhir yang di-clear (untuk membangun "Lanjut" button).
func last_cleared_index() -> int:
	var best := -1
	LevelLoader.load_all()
	for i in range(LevelLoader.count()):
		var lid := LevelLoader.id_at(i)
		if int(GameState.level_stars.get(lid, 0)) >= 1:
			best = i
	return best
