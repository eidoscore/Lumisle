class_name MoveAction extends RefCounted
## Tipe event resolusi board — STRUKTUR OTORITATIF (dok 14 §0.1).
## Core menulis, view & test membaca tipe yang SAMA (cegah dict ad-hoc berbeda).

enum Type {
	SWAP,                 # data: {from:Vector2i, to:Vector2i, valid:bool}
	MATCH_DETECTED,       # informational; positions = sel match
	SPECIAL_CREATED,      # data: {special_type:int, pos:Vector2i}
	SPECIAL_TRIGGERED,    # data: {special_type:int, pos:Vector2i, affected:Array[Vector2i]}
	COMBO_TRIGGERED,      # data: {combo_id:int, pos:Vector2i, affected:Array[Vector2i]}
	TILE_CLEARED,         # positions = sel dihapus (union, sekali); data: {colors:Array[int]}
	OBSTACLE_DAMAGED,     # data: {pos:Vector2i, type:int, hp_left:int}
	OBSTACLE_DESTROYED,   # data: {pos:Vector2i, type:int}
	TILE_FELL,            # data: {from:Vector2i, to:Vector2i}
	TILE_SPAWNED,         # data: {pos:Vector2i, color:int, from_row:int}
	RESHUFFLE,            # data: {}
	OBJECTIVE_PROGRESS,   # data: {objective_id:int, current:int, target:int}
}

var type: int
var positions: Array[Vector2i] = []
var data: Dictionary = {}


func _init(p_type: int = Type.SWAP, p_positions: Array[Vector2i] = [], p_data: Dictionary = {}) -> void:
	type = p_type
	positions = p_positions
	data = p_data


## Factory ringkas untuk event umum (mengurangi boilerplate di board.gd).
static func make(p_type: int, p_positions: Array[Vector2i] = [], p_data: Dictionary = {}) -> MoveAction:
	return MoveAction.new(p_type, p_positions, p_data)


func _to_string() -> String:
	return "MoveAction(%s, pos=%s, data=%s)" % [Type.keys()[type], positions, data]
