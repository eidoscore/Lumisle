extends Control
## PreLevelPopup (T6.5) — overlay sebelum masuk level: judul, objektif, booster, Mulai/Batal.
## Ditambahkan sebagai child PopupLayer di LevelMap (lihat level_map.gd).

signal start_pressed(level_id: String)
signal cancelled

var _level_id: String = ""
var _booster_rocket_active := false
var _booster_bomb_active   := false

@onready var _title_lbl: Label      = $Panel/VBox/TitleLabel
@onready var _obj_lbl: Label        = $Panel/VBox/ObjectivesLabel
@onready var _lives_lbl: Label      = $Panel/VBox/LivesLabel
@onready var _rocket_btn: Button    = $Panel/VBox/BoosterRow/RocketBtn
@onready var _bomb_btn: Button      = $Panel/VBox/BoosterRow/BombBtn
@onready var _start_btn: Button     = $Panel/VBox/StartButton
@onready var _cancel_btn: Button    = $Panel/VBox/CancelButton


func setup(level_id: String) -> void:
	_level_id = level_id
	_booster_rocket_active = false
	_booster_bomb_active   = false
	var lv := LevelLoader.get_level(level_id)
	if lv == null:
		return
	if _title_lbl:
		_title_lbl.text = "%s — %s" % [level_id.replace("lvl_", "L"), lv.title]
	if _obj_lbl:
		var parts: Array[String] = []
		for e in lv.objectives:
			parts.append(_objective_summary(e))
		_obj_lbl.text = "Objektif: " + "  |  ".join(parts)
	_refresh_lives()
	_refresh_booster_btns()


func _refresh_lives() -> void:
	if _lives_lbl:
		_lives_lbl.text = "Nyawa: %d / %d" % [Economy.lives, Economy.MAX_LIVES]


func _refresh_booster_btns() -> void:
	if _rocket_btn:
		var cost := Booster.COST["pre_rocket"]
		var on   := _booster_rocket_active
		_rocket_btn.text = "🚀 Roket %s(%d 🪙)" % ["[ON] " if on else "", cost]
		_rocket_btn.modulate = Color(1.0, 0.9, 0.4) if on else Color(1, 1, 1)
	if _bomb_btn:
		var cost := Booster.COST["pre_bomb"]
		var on   := _booster_bomb_active
		_bomb_btn.text = "💣 Bom %s(%d 🪙)" % ["[ON] " if on else "", cost]
		_bomb_btn.modulate = Color(1.0, 0.9, 0.4) if on else Color(1, 1, 1)


func _on_rocket_pressed() -> void:
	if _booster_rocket_active:
		# Toggle off — refund
		Economy.add_coins(Booster.COST["pre_rocket"])
		_booster_rocket_active = false
	else:
		if Economy.spend_coins(Booster.COST["pre_rocket"]):
			_booster_rocket_active = true
		# else: tidak cukup koin — biarkan disabled feedback dari button modulate
	_refresh_booster_btns()


func _on_bomb_pressed() -> void:
	if _booster_bomb_active:
		Economy.add_coins(Booster.COST["pre_bomb"])
		_booster_bomb_active = false
	else:
		if Economy.spend_coins(Booster.COST["pre_bomb"]):
			_booster_bomb_active = true
	_refresh_booster_btns()


func _on_start_pressed() -> void:
	# Simpan booster yang dipilih ke GameState agar game_screen bisa menggunakannya
	GameState.pre_level_boosters = []
	if _booster_rocket_active:
		GameState.pre_level_boosters.append("rocket")
	if _booster_bomb_active:
		GameState.pre_level_boosters.append("bomb")
	start_pressed.emit(_level_id)


func _objective_summary(e: ObjectiveEntry) -> String:
	match e.objective_type:
		"collect":    return "Kumpul %d" % e.target
		"clear_obstacle": return "Hancurkan %d rintangan" % e.target
		"bring_down": return "Antar %d item" % e.target
		"score":      return "Skor %d" % e.target
		_:            return "Target %d" % e.target


func _on_cancel_pressed() -> void:
	# Refund booster yang sudah dibeli
	if _booster_rocket_active:
		Economy.add_coins(Booster.COST["pre_rocket"])
	if _booster_bomb_active:
		Economy.add_coins(Booster.COST["pre_bomb"])
	cancelled.emit()
