class_name LevelDefinition extends Resource
## T4.1 — Skema data level (dok 05 §2). Authoring `.tres` (editor) → export JSON (T4.1b);
## runtime baca JSON via LevelLoader. Field gameplay = int/Array (determinisme dok 04 §3.8).
## CATATAN: subset field dok 05 yang DIPAKAI Fase 4. Field solver-metadata (difficulty_score,
## estimated_winrate, dst) ditambah saat Fase 5 (generator) — belum perlu sekarang.

@export var id: String = ""
@export var board_width: int = 7
@export var board_height: int = 8
@export var playable_mask: PackedInt32Array = PackedInt32Array()  # kosong = semua playable
@export var color_subset: Array[int] = [1, 2, 3, 4, 5]
@export var move_limit: int = 20
@export var objectives: Array[ObjectiveEntry] = []
@export var obstacles: Array[ObstacleEntry] = []
@export var seed: int = 0
@export var title: String = ""
@export var tutorial: bool = false
@export var hand_crafted: bool = true
@export var ruleset_version: int = 2
@export var rng_algorithm_version: int = 1


## num_colors = ukuran subset aktif.
func num_colors() -> int:
	return color_subset.size()


func colors_packed() -> PackedInt32Array:
	var arr := PackedInt32Array()
	for c in color_subset:
		arr.append(int(c))
	return arr


## Daftar obstacle dalam format yang diterima Board.setup().
func obstacles_for_setup() -> Array:
	var out: Array = []
	for o in obstacles:
		out.append(o.to_setup_dict())
	return out


# ---------------------------------------------------------------------------
# Konversi dari/ke JSON (dok 05 §2). snake_case PERSIS.
# ---------------------------------------------------------------------------

static func from_dict(d: Dictionary) -> LevelDefinition:
	var lv := LevelDefinition.new()
	lv.id = str(d.get("id", ""))
	lv.board_width = int(d.get("board_width", 7))
	lv.board_height = int(d.get("board_height", 8))
	lv.move_limit = int(d.get("move_limit", 20))
	lv.seed = int(d.get("seed", 0))
	lv.title = str(d.get("title", ""))
	lv.tutorial = bool(d.get("tutorial", false))
	lv.hand_crafted = bool(d.get("hand_crafted", true))
	lv.ruleset_version = int(d.get("ruleset_version", 2))
	lv.rng_algorithm_version = int(d.get("rng_algorithm_version", 1))

	var cs: Array[int] = []
	for c in d.get("color_subset", [1, 2, 3, 4, 5]):
		cs.append(int(c))
	lv.color_subset = cs

	var pm := PackedInt32Array()
	for v in d.get("playable_mask", []):
		pm.append(int(v))
	lv.playable_mask = pm

	var objs: Array[ObjectiveEntry] = []
	for od in d.get("objectives", []):
		objs.append(ObjectiveEntry.from_dict(od))
	lv.objectives = objs

	var obs: Array[ObstacleEntry] = []
	for obd in d.get("obstacles", []):
		obs.append(ObstacleEntry.from_dict(obd))
	lv.obstacles = obs
	return lv


func to_dict() -> Dictionary:
	var objs: Array = []
	for o in objectives:
		objs.append(o.to_dict())
	var obs: Array = []
	for o in obstacles:
		var positions: Array = []
		for p in o.positions:
			positions.append([p.x, p.y])
		obs.append({"type": o.obstacle_type, "layer": o.layer, "positions": positions, "hp": o.hp})
	var pm: Array = []
	for v in playable_mask:
		pm.append(v)
	return {
		"id": id,
		"board_width": board_width,
		"board_height": board_height,
		"playable_mask": pm,
		"color_subset": color_subset,
		"num_colors": num_colors(),
		"move_limit": move_limit,
		"objectives": objs,
		"obstacles": obs,
		"seed": seed,
		"title": title,
		"tutorial": tutorial,
		"hand_crafted": hand_crafted,
		"ruleset_version": ruleset_version,
		"rng_algorithm_version": rng_algorithm_version,
	}
