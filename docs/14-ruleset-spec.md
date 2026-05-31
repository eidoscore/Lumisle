# 14 — Ruleset Spec (Kontrak Resolusi Board yang Otoritatif)

> **SUMBER KEBENARAN TUNGGAL** untuk SEMUA aturan resolusi board.
> Core, solver, view, dan test WAJIB mengikuti dokumen ini PERSIS. Kalau ada konflik dengan dokumen lain soal urutan/aturan resolusi → dokumen ini menang.
> Alasan keberadaan (temuan GPT-5.5): tanpa spec eksplisit tunggal, core/solver/view/test bisa "benar" dengan cara berbeda → bug halus yang sangat sulit dilacak.
> **Ditulis & dibekukan SEBELUM koding core (task T1.0).** Perubahan aturan = naikkan `ruleset_version`.

---

## 0. Prinsip
- Resolusi **berbasis snapshot & simultan**, bukan "scan-and-clear satu per satu" (urutan scan tidak boleh mempengaruhi hasil).
- Semua randomness lewat `GameRNG` berseed (tidak ada `randi()` global).
- Semua state gameplay = int (tidak ada float di logika).
- Output satu giliran = **TurnReport** (list event berurutan) — view replay, tidak menghitung ulang.
- **Objective credit dihitung dari EVENT semantik** (TileCleared/ObstacleDamaged/ObstacleDestroyed), BUKAN dari animasi atau dari scan board.

`ruleset_version` saat ini: **1**.

---

## 0.1 Tipe Event (MoveAction) — STRUKTUR OTORITATIF
> Semua step cascade = `MoveAction` typed (bukan Dictionary ad-hoc). Core menulis, view & test membaca tipe yang SAMA. Ini mencegah core/view menafsirkan key dict berbeda.

```gdscript
# core/move_action.gd
class_name MoveAction extends RefCounted

enum Type {
    SWAP,                 # data: {from:Vector2i, to:Vector2i, valid:bool}
    MATCH_DETECTED,       # informational; positions = sel match
    SPECIAL_CREATED,      # data: {special_type:int, pos:Vector2i}
    SPECIAL_TRIGGERED,    # data: {special_type:int, pos:Vector2i, affected:Array[Vector2i]}
    COMBO_TRIGGERED,      # data: {combo_id:int, pos:Vector2i, affected:Array[Vector2i]}
    TILE_CLEARED,         # positions = sel yang dihapus (union, sekali); data: {colors:Array[int]}
    OBSTACLE_DAMAGED,     # data: {pos:Vector2i, type:int, hp_left:int}
    OBSTACLE_DESTROYED,   # data: {pos:Vector2i, type:int}
    TILE_FELL,            # data: {from:Vector2i, to:Vector2i}
    TILE_SPAWNED,         # data: {pos:Vector2i, color:int, from_row:int}
    RESHUFFLE,            # data: {} (board diacak)
    OBJECTIVE_PROGRESS,   # data: {objective_id:int, current:int, target:int}
}

var type: Type
var positions: Array[Vector2i] = []
var data: Dictionary = {}
```

`TurnReport` (field final):
```gdscript
# core/turn_report.gd
class_name TurnReport extends RefCounted
var is_valid_swap: bool          # swap fisik valid (bersebelahan, playable)
var is_accepted: bool            # STEP C: swap menghasilkan match/aktivasi
var move_cost: int               # 0 = rejected, 1 = diterima
var steps: Array[MoveAction] = []
var initial_board_hash: int
var final_board_hash: int
var score_delta_x2: int          # skor basis ×2 (lihat §6)
var objective_complete: bool
var error: String = ""           # non-empty → rollback terjadi (STEP D/§ error handling)
```

---

## 0.2 Format Obstacle Runtime (jembatan Format A → PackedInt32Array)
- **Design-time (Format A, dok 05 §2):** `{type, layer, positions[], params{hp}}`.
- **Runtime:** `obstacle_layer: PackedInt32Array` paralel dgn `cells` (indexing sama). Encode per cell: **bit 0-7 = type_id** (0=none), **bit 8-15 = hp**, **bit 16-23 = layer**.
- **Konversi saat `board.setup()`:** untuk tiap entry, untuk tiap `pos` → `idx = y*width+x` → `obstacle_layer[idx] = encode(type_id, hp, layer)`.
- **V1: MAKS 1 obstacle per cell.** Kalau 2 entry menumpuk di cell sama → simpan yang `layer` lebih tinggi. Multi-layer penuh = **deferred v2** (Format A sudah mendukung secara data; runtime menyusul).

---

## 1. Urutan Resolusi Satu Giliran (Authoritative Pipeline)

```
try_swap(a, b):
  STEP A. Validasi swap
  STEP B. Lakukan swap (tukar 2 cell bersebelahan)
  STEP C. Tentukan apakah giliran VALID
  STEP D. Loop cascade sampai stabil
  STEP E. Cek dead-board → reshuffle
  STEP F. Cek menang/kalah
  → return TurnReport
```

### STEP A — Validasi swap
- `a` dan `b` harus bersebelahan ortogonal (bukan diagonal), keduanya playable, tidak terkunci obstacle yang melarang swap.
- Jika tidak valid secara fisik → `TurnReport.rejected` (tidak makan langkah, animasi tidak ada).

### STEP B — Lakukan swap
- Tukar nilai cell `a` dan `b`.

### STEP C — Apakah giliran valid?
Giliran dianggap **accepted** jika SALAH SATU benar:
1. Swap menghasilkan ≥1 match (deteksi dari snapshot setelah swap), ATAU
2. Salah satu dari `a`/`b` adalah **special item** yang aktivasinya tidak butuh match (mis. ColorBomb di-swap dengan tile biasa), ATAU
3. Swap adalah **combo special+special** (kedua cell special).

Jika tidak ada satupun → **swap dibatalkan (swap-back)**, `TurnReport.rejected`, **tidak makan langkah** (anti-frustrasi).
Jika accepted → **−1 langkah** (move cost = 1), lanjut STEP D.

> Catatan: combo special+special (C2/C3) **bypass match detection** dan langsung masuk trigger queue di STEP D.

### STEP D — Loop Cascade (jantung)
```
cascade_count = 0
trigger_queue = []   # special yang harus diaktifkan
# Seed awal: kalau swap memicu combo/aktivasi special → push ke trigger_queue

while true:
  cascade_count += 1
  assert(cascade_count < MAX_CASCADE = 64)   # guard

  matches  = MatchDetector.find_all(snapshot)      # SEMUA match dari snapshot
  triggers = trigger_queue.drain()                 # FIFO, dedupe per step

  if matches.is_empty() and triggers.is_empty():
      break

  # D.1 Tentukan special yang DIBUAT dari matches (sebelum clear)
  created = decide_specials_created(matches)        # lihat §2

  # D.2 Hitung resolusi SIMULTAN (matches + triggers digabung)
  resolution = resolve_simultaneous(matches, triggers)   # lihat §3
      -> clear_mask         (tile yang dihapus)
      -> obstacle_damage    (obstacle yang kena, per layer atas)
      -> new_triggers       (special yang ikut meledak → masuk queue lagi)

  # D.3 Terapkan, urutan WAJIB:
  emit TileCleared events (dari clear_mask, KECUALI posisi 'created' yang jadi special)
  place 'created' specials di posisi anchor (§2.3)
  apply_obstacle_damage(obstacle_damage) -> emit ObstacleDamaged/ObstacleDestroyed
  credit_objectives(events)                  # dari EVENT, bukan board scan (§5)
  apply_gravity()        -> emit TileFell events (per kolom, hormati blocker §4)
  refill(rng)            -> emit TileSpawned events (§4)
  trigger_queue.append(new_triggers)
  append semua events ke TurnReport step
```

### STEP E — Dead-board & Reshuffle
- Setelah loop stabil, `find_possible_moves()`. Jika kosong → `reshuffle(rng)` (acak ulang, no match instan, ada ≥1 move). Emit `Reshuffle` event.
- Reshuffle **GRATIS** (tidak makan langkah) — keputusan D16.

### STEP F — Menang/Kalah
- **Menang:** semua objektif `is_complete()` → emit `LevelWon`. (Cek setelah credit objektif.)
- **Kalah:** langkah habis (`moves_left == 0`) DAN objektif belum lengkap → tawarkan +langkah (rewarded/koin) sebelum `LevelLost`.

---

## 2. Aturan Pembuatan Special (deterministik)

### 2.1 Tipe match → special
| Match | Special dibuat |
|---|---|
| 4 segaris (horizontal) | Roket horizontal |
| 4 segaris (vertikal) | Roket vertikal |
| 5 bentuk L atau T (dua garis berpotongan) | Bom |
| 5 segaris lurus | Color Bomb |
| (kotak 2x2 — opsional v1.x) | (TBD, default: tidak dipakai v1) |

### 2.2 Prioritas klasifikasi (kalau satu grup match ambigu)
Color Bomb (5-lurus) > Bom (L/T) > Roket (4). Klasifikasi dihitung dari bentuk grup match terbesar yang melibatkan tile.

### 2.3 Posisi anchor special yang dibuat
1. **Posisi tile yang digerakkan pemain** (salah satu dari `a`/`b`) jika tile itu bagian dari match → pakai itu.
2. Jika bukan (mis. match dari cascade), fallback: **titik potong** (untuk L/T), atau **sel paling bawah lalu paling kiri** untuk match lurus.
- Aturan fallback ini harus identik di core & solver.

---

## 3. Aktivasi & Combo Special

### 3.1 Efek dasar (saat special diaktifkan)
| Special | Area terdampak |
|---|---|
| Roket H | seluruh baris special |
| Roket V | seluruh kolom special |
| Bom | area 3x3 di sekitar special (atau radius r=1) |
| Color Bomb | semua tile berwarna = warna target (warna tile yang di-swap; jika di-swap dgn special, lihat combo) |

### 3.2 Combo special + special (di-swap berdampingan)
| Combo | Efek |
|---|---|
| Roket + Roket | palang: 1 baris + 1 kolom penuh di titik combo |
| Roket + Bom | palang tebal (3 baris + 3 kolom) |
| Bom + Bom | ledakan area besar (mis. 5x5) |
| Color Bomb + Roket | semua tile 1 warna (terbanyak/target) → jadi Roket → semua meledak |
| Color Bomb + Bom | semua tile 1 warna → jadi Bom → semua meledak |
| Color Bomb + Color Bomb | **bersihkan SELURUH papan** + kupas 1 layer tiap obstacle |

**Combo table = STRUKTUR DATA (bukan if-else berserakan).** Lookup by key `(special_a << 4) | special_b` (komutatif: normalkan urutan a≤b sebelum lookup):
```gdscript
# special_items.gd
class ComboDef:
    var combo_id: int
    var effect: int      # enum: CROSS, THICK_CROSS, BIG_AREA, CONVERT_TO_ROCKET, CONVERT_TO_BOMB, CLEAR_ALL
    var radius: int      # untuk efek area
COMBO_TABLE: Dictionary  # key:int -> ComboDef. Diisi sekali saat init.
```
Menambah combo = tambah entry di tabel + fixture test, BUKAN cabang if baru (cegah regresi combo lama).

### 3.3 Urutan eksekusi saat banyak special ter-trigger bersamaan
Prioritas: **ColorBomb > Combo (Roket+Bom dst) > Bom > Roket**. Tie-break: posisi **(y kecil dulu, lalu x kecil)** = atas→bawah, kiri→kanan (sama dengan urutan iterasi index flat).

### 3.4 Chain reaction
- Special yang **terkena** efek special lain → masuk `trigger_queue` (BFS/FIFO), **bukan rekursi langsung**.
- **Dedupe per resolution step**: satu special tidak di-trigger dua kali dalam satu step.
- Guard `MAX_CASCADE = 64`.

### 3.5 Resolusi Simultan — aturan eksplisit (GAP yang ditutup, temuan GLM)
> Tanpa aturan ini, core & solver bisa implement "benar" dengan cara berbeda.

1. **Satu cell di-clear MAKSIMAL sekali per step**, walau termasuk dalam beberapa match DAN/ATAU beberapa area efek special. `clear_mask = bitwise OR` dari semua area terdampak (union). Penghapusan fisik sekali.
2. **Objective credit tetap dihitung dari EVENT semantik** (§5), bukan dari `clear_mask`. Satu cell bisa memunculkan beberapa event (mis. TileCleared + ObstacleDamaged) — itu wajar; yang sekali hanyalah penghapusan fisik.
3. **Special yang BARU dibuat di step ini KEBAL terhadap clear di step yang sama** (baru lahir, belum bisa diledakkan). Posisi anchor-nya dikecualikan dari `clear_mask`, walau posisi itu termasuk area efek special lain yang aktif di step yang sama.
4. **Special yang masuk `trigger_queue` langsung di-set EMPTY di board** saat di-drain (tidak ada state "triggered tapi masih ada di board" → cegah race/double-trigger). Area efeknya lalu dihitung.
5. **Urutan deterministik** saat menggabungkan: proses matches dan triggers dalam urutan index flat (y kecil→besar, lalu x), tie-break sesuai §3.3.

---

## 4. Gravity & Refill

### 4.1 Gravity
- **Per kolom, urutan kolom WAJIB kiri→kanan (x=0 → x=width-1)**, dari bawah ke atas dalam tiap kolom. Tile jatuh mengisi sel kosong di bawahnya.
- **Blocker** (obstacle dengan `blocks_movement() == true`, mis. box/crate) **menahan** jatuh: tile di atasnya tidak melewatinya. Ice (`blocks_movement() == false`) tidak menahan.
- Sel non-playable di-skip.
- Emit `TileFell {from, to}` untuk tiap tile yang berpindah.

### 4.2 Refill
- Tile baru muncul dari **atas kolom** (baris teratas playable), warna dipilih via `GameRNG` dari `color_subset` level.
- **RNG WAJIB dipanggil dalam urutan kolom yang sama dengan gravity (kiri→kanan, lalu atas→bawah dalam kolom)** — ini kritis untuk determinisme & agar solver identik dengan game.
- Emit `TileSpawned {pos, color, from_offscreen_row}`.
- **Tidak ada constraint "no match on refill"** secara default (match dari refill = cascade, itu fitur). KECUALI saat board init (§ board setup): init harus bebas match.

---

## 5. Objective Credit (dari EVENT, bukan scan)

Objektif di-kredit dari event semantik yang dihasilkan resolusi:
| Objektif | Di-kredit oleh event |
|---|---|
| `collect` warna X | `TileCleared` dengan warna == X |
| `clear_obstacle` tipe Y | `ObstacleDestroyed` tipe == Y |
| `bring_down` item Z | item Z mencapai baris bawah (event khusus `ItemDelivered`) |
| `score` | akumulasi skor dari event clear (lihat §6) |

> **Penting:** jangan hitung objektif dengan men-scan board setelah giliran. Hitung dari event yang terjadi selama resolusi — supaya core, solver, dan tampilan setuju 100%.

---

## 6. Scoring (deterministik — INT MURNI, tanpa float)
- Skor disimpan dengan **basis ×2** untuk menghindari float: base = 20 (=10×2) per `TileCleared`.
- **Cascade multiplier (int):** cascade ke-n → faktor `(n+1)` pada basis ×2 → cascade 1 = ×2, cascade 2 = ×3, cascade 3 = ×4 (setara ×1.0/×1.5/×2.0 setelah dibagi 2). 
- Bonus special (basis ×2): Roket +100, Bom +160, ColorBomb +240 (angka final = tuning).
- Skor di-track sebagai int (`score_delta_x2`) di TurnReport. **Bagi 2 HANYA saat display.** Tidak ada float di logika/solver.

---

## 7. Board Hash & Replay (untuk test determinisme)
- `board_hash()` = hash deterministik dari `cells` + `obstacle_layer` (mis. hash dari `cells.to_byte_array()` + serialisasi obstacle terurut).
- **Replay runner:** `(level, seed, daftar move) → urutan board_hash`. Dijalankan 2x harus identik. Ini fondasi test determinisme & regresi.
- `board_hash_expected` (opsional) disimpan di golden fixtures untuk validasi cepat.

---

## 8. Versioning
- `ruleset_version` (dokumen ini) — naik kalau aturan resolusi berubah.
- `rng_algorithm_version` — naik kalau algoritma RNG/shuffle berubah (mempengaruhi reproducibility).
- Level menyimpan `ruleset_version` & `rng_algorithm_version` saat dibuat. Saat load: jika beda dengan versi engine → tandai (regenerate kalau generated, atau migrate/accept kalau aman). Lihat dok 05 §2.

---

## 9. Hal yang SENGAJA belum dispesifikasi (v1)
- Kotak 2x2 → special (opsional v1.x).
- Propeller (special ke-4) — v1.x.
- Multi-warna campur (color mixing) — kandidat signature mechanic, v2.
- Gravity arah non-bawah — schema mendukung, tapi v1 hanya DOWN.

> Tambahkan ke sini (dan naikkan `ruleset_version`) saat aturan baru dibakukan. Jangan biarkan aturan baru "tersirat" di kode tanpa masuk spec ini.
