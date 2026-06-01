class_name ObstacleEntry extends Resource
## T4.0 — Rintangan level (type-safe, editable di inspector). Format A (dok 05 §2,
## dok 14 §0.2): type + layer + positions[] + hp. Dipakai LevelDefinition.obstacles.

@export var obstacle_type: int = 0                       # TileCodes.ObstacleType (1=ice,2=crate,3=collectible)
@export var layer: int = 1
@export var positions: Array[Vector2i] = []
@export var hp: int = 1


func _init(p_type: int = 0, p_layer: int = 1, p_positions: Array[Vector2i] = [], p_hp: int = 1) -> void:
	obstacle_type = p_type
	layer = p_layer
	positions = p_positions
	hp = p_hp


## Konversi dari dict JSON (dok 05 §2). positions = [[x,y],...]; params.hp atau hp.
static func from_dict(d: Dictionary) -> ObstacleEntry:
	var e := ObstacleEntry.new()
	e.obstacle_type = _type_to_int(d.get("type", 0))
	e.layer = int(d.get("layer", 1))
	var hp_val := 1
	if d.has("hp"):
		hp_val = int(d["hp"])
	elif d.has("params") and typeof(d["params"]) == TYPE_DICTIONARY:
		hp_val = int(d["params"].get("hp", 1))
	e.hp = hp_val
	var pos: Array[Vector2i] = []
	for p in d.get("positions", []):
		if typeof(p) == TYPE_ARRAY and p.size() >= 2:
			pos.append(Vector2i(int(p[0]), int(p[1])))
	e.positions = pos
	return e


## Map nama tipe string ("ice"/"crate"/"collectible") atau int → TileCodes.ObstacleType.
static func _type_to_int(t) -> int:
	if typeof(t) == TYPE_STRING:
		match t:
			"ice": return TileCodes.ObstacleType.ICE
			"crate", "box": return TileCodes.ObstacleType.CRATE
			"collectible": return TileCodes.ObstacleType.COLLECTIBLE
			_: return TileCodes.ObstacleType.NONE
	return int(t)


## Untuk Board.setup() yang menerima Array of {type,layer,positions,hp}.
func to_setup_dict() -> Dictionary:
	return {
		"type": obstacle_type,
		"layer": layer,
		"positions": positions,
		"hp": hp,
	}
