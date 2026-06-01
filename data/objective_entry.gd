class_name ObjectiveEntry extends Resource
## T4.0 — Objektif level (type-safe, editable di inspector). Hindari Array[Dictionary]
## yang rawan bug (dok 04 §12). Dipakai LevelDefinition.objectives: Array[ObjectiveEntry].
## Acuan tipe: dok 05 §2 ("collect"/"clear_obstacle"/"bring_down"/"score").

@export var objective_type: String = "collect"   # collect|clear_obstacle|bring_down|score
@export var target: int = 10
@export var tile_color: int = 1                   # untuk collect (warna TileCodes 1-6)
@export var obstacle_type: int = 0                # untuk clear_obstacle (TileCodes.ObstacleType)


func _init(p_type: String = "collect", p_target: int = 10, p_color: int = 1, p_obstacle: int = 0) -> void:
	objective_type = p_type
	target = p_target
	tile_color = p_color
	obstacle_type = p_obstacle


## Konversi dari dict JSON (dok 05 §2). Field: type, target, tile_color, obstacle_type.
static func from_dict(d: Dictionary) -> ObjectiveEntry:
	return ObjectiveEntry.new(
		str(d.get("type", "collect")),
		int(d.get("target", 10)),
		int(d.get("tile_color", 1)),
		int(d.get("obstacle_type", 0)),
	)


func to_dict() -> Dictionary:
	return {
		"type": objective_type,
		"target": target,
		"tile_color": tile_color,
		"obstacle_type": obstacle_type,
	}
