class_name ObjectiveFactory extends RefCounted
## T4.2 — Bangun ObjectiveBase konkret dari ObjectiveEntry (data level).
## Satu titik pemetaan type-string → kelas objektif (cegah if-else berserak di view).

static func create(entry: ObjectiveEntry) -> ObjectiveBase:
	match entry.objective_type:
		"collect":
			return CollectObjective.new(entry.tile_color, entry.target)
		"clear_obstacle":
			return ClearObstacleObjective.new(entry.obstacle_type, entry.target)
		"bring_down":
			return BringDownObjective.new(entry.target)
		"score":
			return ScoreObjective.new(entry.target)
		_:
			push_error("ObjectiveFactory: tipe objektif tak dikenal: %s" % entry.objective_type)
			return CollectObjective.new(1, entry.target)


## Label HUD ringkas untuk objektif (ikon teks + progress).
static func label_for(entry: ObjectiveEntry, obj: ObjectiveBase) -> String:
	var prog := "%d/%d" % [obj.get_progress(), obj.get_target()]
	match entry.objective_type:
		"collect":
			return "%s %s" % [_color_name(entry.tile_color), prog]
		"clear_obstacle":
			return "%s %s" % [_obstacle_name(entry.obstacle_type), prog]
		"bring_down":
			return "Antar item %s" % prog
		"score":
			return "Skor %s" % prog
		_:
			return prog


static func _color_name(c: int) -> String:
	match c:
		1: return "Merah"
		2: return "Biru"
		3: return "Hijau"
		4: return "Kuning"
		5: return "Ungu"
		6: return "Oranye"
		_: return "Warna"


static func _obstacle_name(t: int) -> String:
	match t:
		TileCodes.ObstacleType.ICE: return "Pecah Es"
		TileCodes.ObstacleType.CRATE: return "Pecah Box"
		TileCodes.ObstacleType.COLLECTIBLE: return "Antar"
		_: return "Rintangan"
