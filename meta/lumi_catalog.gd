extends Node
## LumiCatalog (autoload, T7.1) — data statis 18 Lumi (3 area × 6).
## Rarity: "common" | "rare" | "epic".
## star_threshold = kumulatif bintang dalam area untuk bebas Lumi ini.
## Warna render di LumiGrid ditentukan oleh rarity + area.
## GDD §6.1.1.

const AREA_LEVEL_RANGES: Array = [
	{"area": 1, "level_min": 1,  "level_max": 30},   # Pesisir Lumira
	{"area": 2, "level_min": 31, "level_max": 70},   # Hutan Cahaya
	{"area": 3, "level_min": 71, "level_max": 999},  # Puncak Bintang
]

func _ready() -> void:
	set_process(false)


## Kumulatif bintang per slot dalam satu area.
## Slot 1→3, Slot 2→8, Slot 3→16, Slot 4→28, Slot 5→44, Slot 6→64.
const STAR_THRESHOLDS: Array[int] = [3, 8, 16, 28, 44, 64]

## 18 Lumi: 3 area × 6 slot. Urutan = area 1 slot 1-6, area 2 slot 1-6, area 3 slot 1-6.
const ALL: Array = [
	# --- Area 1: Pesisir Lumira ---
	{
		"id": "lumi_1_1", "area": 1, "slot": 1, "rarity": "common",
		"name": "Ora",
		"lore": "Roh ombak paling muda di Pesisir Lumira. Ia suka melompat di antara buih putih dan bersembunyi di balik kerang.",
		"color": Color(0.35, 0.75, 1.0),
	},
	{
		"id": "lumi_1_2", "area": 1, "slot": 2, "rarity": "common",
		"name": "Biru",
		"lore": "Penjaga laguna tenang. Warnanya berkilau seperti air laut saat matahari siang menyentuhnya.",
		"color": Color(0.20, 0.55, 0.95),
	},
	{
		"id": "lumi_1_3", "area": 1, "slot": 3, "rarity": "common",
		"name": "Karang",
		"lore": "Dulu tinggal di terumbu karang merah. Ketika cahaya pulau meredup, terumbu ikut memucet.",
		"color": Color(1.0, 0.50, 0.40),
	},
	{
		"id": "lumi_1_4", "area": 1, "slot": 4, "rarity": "common",
		"name": "Pasir",
		"lore": "Bergerak lambat dan hangat seperti pasir di sore hari. Roh tertua yang tersisa di pesisir.",
		"color": Color(0.95, 0.85, 0.55),
	},
	{
		"id": "lumi_1_5", "area": 1, "slot": 5, "rarity": "rare",
		"name": "Mutiara",
		"lore": "Lumi langka yang hanya muncul saat bulan purnama. Kilauannya tersimpan dalam kerang terdalam.",
		"color": Color(0.92, 0.92, 1.0),
	},
	{
		"id": "lumi_1_6", "area": 1, "slot": 6, "rarity": "epic",
		"name": "Lumira",
		"lore": "Roh induk Pesisir Lumira. Namanya menjadi nama pulau ini. Saat ia kembali, seluruh pantai bersinar.",
		"color": Color(0.70, 0.95, 1.0),
	},
	# --- Area 2: Hutan Cahaya ---
	{
		"id": "lumi_2_1", "area": 2, "slot": 1, "rarity": "common",
		"name": "Pijar",
		"lore": "Roh kecil yang suka bersembunyi di balik daun lebar. Cahayanya berkedip seperti kunang-kunang.",
		"color": Color(0.60, 1.0, 0.40),
	},
	{
		"id": "lumi_2_2", "area": 2, "slot": 2, "rarity": "common",
		"name": "Akar",
		"lore": "Terhubung ke jaringan akar pohon tua. Ia merasakan semua yang terjadi di bawah tanah hutan.",
		"color": Color(0.50, 0.30, 0.15),
	},
	{
		"id": "lumi_2_3", "area": 2, "slot": 3, "rarity": "common",
		"name": "Embun",
		"lore": "Muncul tiap fajar di ujung dedaunan. Tubuhnya dingin dan segar seperti butir embun pagi.",
		"color": Color(0.70, 0.90, 0.85),
	},
	{
		"id": "lumi_2_4", "area": 2, "slot": 4, "rarity": "common",
		"name": "Dahan",
		"lore": "Melompat antar dahan dengan gesit. Selalu meninggalkan jejak cahaya hijau di ranting yang dipijaknya.",
		"color": Color(0.30, 0.75, 0.35),
	},
	{
		"id": "lumi_2_5", "area": 2, "slot": 5, "rarity": "rare",
		"name": "Jamur",
		"lore": "Roh langka jamur bercahaya. Hanya terlihat di malam hari ketika hutan benar-benar gelap.",
		"color": Color(0.85, 0.60, 1.0),
	},
	{
		"id": "lumi_2_6", "area": 2, "slot": 6, "rarity": "epic",
		"name": "Cahaya",
		"lore": "Penjaga sejati Hutan Cahaya. Saat ia terbang, seluruh hutan menerangi malam layaknya siang hari.",
		"color": Color(1.0, 1.0, 0.60),
	},
	# --- Area 3: Puncak Bintang ---
	{
		"id": "lumi_3_1", "area": 3, "slot": 1, "rarity": "common",
		"name": "Kristal",
		"lore": "Lahir dari kristal es di puncak gunung. Tubuhnya membiaskan cahaya bintang menjadi pelangi.",
		"color": Color(0.75, 0.90, 1.0),
	},
	{
		"id": "lumi_3_2", "area": 3, "slot": 2, "rarity": "common",
		"name": "Puncak",
		"lore": "Selalu berdiri di titik tertinggi batu. Dari sana ia mengamati seluruh pulau dengan tenang.",
		"color": Color(0.80, 0.80, 0.95),
	},
	{
		"id": "lumi_3_3", "area": 3, "slot": 3, "rarity": "common",
		"name": "Kelip",
		"lore": "Bergerak cepat dan sulit ditangkap mata. Cahayanya muncul sebentar lalu menghilang di balik awan.",
		"color": Color(1.0, 0.95, 0.60),
	},
	{
		"id": "lumi_3_4", "area": 3, "slot": 4, "rarity": "common",
		"name": "Malam",
		"lore": "Roh yang memeluk kegelapan. Ia justru paling terang saat langit paling pekat.",
		"color": Color(0.30, 0.25, 0.70),
	},
	{
		"id": "lumi_3_5", "area": 3, "slot": 5, "rarity": "rare",
		"name": "Bintang",
		"lore": "Jatuh dari langit ribuan tahun lalu dan memilih tinggal. Cahayanya seperti bintang yang belum padam.",
		"color": Color(1.0, 0.85, 0.30),
	},
	{
		"id": "lumi_3_6", "area": 3, "slot": 6, "rarity": "epic",
		"name": "Astral",
		"lore": "Lumi tertua di seluruh pulau. Konon ia ada sebelum pulau terbentuk, mengampu langit malam Puncak Bintang.",
		"color": Color(0.90, 0.70, 1.0),
	},
]


## Ambil entry Lumi berdasar id. null kalau tidak ada.
func get_lumi(id: String) -> Variant:
	for e in ALL:
		if e["id"] == id:
			return e
	return null


## Semua Lumi di area tertentu (1-indexed), sorted by slot.
func for_area(area: int) -> Array:
	var out: Array = []
	for e in ALL:
		if e["area"] == area:
			out.append(e)
	return out


## Index (0-based) level → area index (1-indexed).
## level_number adalah 1-based (1 = lvl_001, 31 = lvl_031, dst).
func area_for_level(level_number: int) -> int:
	for r in AREA_LEVEL_RANGES:
		if level_number >= r["level_min"] and level_number <= r["level_max"]:
			return r["area"]
	return 3  # default area terakhir untuk level sangat tinggi


## Threshold kumulatif bintang per slot (0-indexed).
func threshold_for_slot(slot: int) -> int:
	var idx := clampi(slot - 1, 0, STAR_THRESHOLDS.size() - 1)
	return STAR_THRESHOLDS[idx]
