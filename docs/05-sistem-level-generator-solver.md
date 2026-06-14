# 05 — Sistem Level: Generator + Solver

> Jawaban teknis untuk masalah utama: "gimana caranya bikin ribuan level tanpa mendesain satu-satu?"
> Ini dokumen paling kritis untuk skalabilitas konten.

---

## 1. Prinsip Dasar

> **Level = DATA. Satu mesin (board logic) membaca ribuan file data.**

Kita TIDAK memprogram tiap level. Kita membangun:
1. **Generator** — memproduksi kandidat level dari aturan + kurva kesulitan.
2. **Solver bot** — memainkan tiap kandidat ribuan kali untuk mengukur kualitas (solvable? terlalu mudah/susah?).
3. **Pipeline** — generate → solve → saring → simpan level valid.

Semua ini dijalankan **offline** (saat development), bukan di HP pemain. Yang dikirim ke pemain hanya **level data final** yang sudah tervalidasi.

---

## 2. Skema Data Level (Lengkap)

```gdscript
class_name LevelDefinition extends Resource

@export var id: String                  # ID stabil (mis. "lvl_042"), BUKAN dari filename
@export var board_width: int            # mis. 6-9
@export var board_height: int           # mis. 7-9
@export var playable_mask: PackedInt32Array # 1=aktif, 0=non-playable (bentuk papan) — konsisten dgn cells (dok 04)
@export var num_colors: int             # jumlah warna AKTIF (= color_subset.size())
@export var color_subset: Array[int]    # authoring pakai Array[int] (editable di inspector); runtime boleh konversi ke PackedInt32Array
@export var move_limit: int
@export var objectives: Array           # lihat di bawah
@export var obstacles: Array            # lihat di bawah (dukung 'layer' untuk bertumpuk)
@export var prefilled: Dictionary       # {cell_index: tile_type} kondisi awal khusus
@export var spawn_pattern: Array        # kontrol tile awal (penting untuk tutorial/forced-win FTUE)
@export var gravity_direction: int      # default DOWN; variasi opsional
@export var allowed_specials: Array      # special apa yang aktif di level ini
@export var special_item_config: Dictionary  # override aturan pembuatan special per level (opsional)
@export var archetype: String           # niat desain (combo_playground, bottleneck, dll)
@export var difficulty_band: String     # label: lihat enum DifficultyBand di bawah
@export var hand_crafted: bool          # true = level manual (1-30), JANGAN disentuh regenerator
@export var is_tutorial: bool           # true = L1-L5, aktifkan tutorial blocking di BoardView
@export var tutorial_forced_swaps: Array[Vector2i] # urutan swap yang di-highlight (tiap entry = posisi tile "dari") — hanya dipakai kalau is_tutorial=true; Array kosong = hint otomatis via find_best_hint_move()
@export var generator_version: int      # versi generator pembuat (deteksi level usang)
@export var ruleset_version: int        # versi aturan resolusi (dok 14) saat level dibuat
@export var rng_algorithm_version: int  # versi algoritma RNG/shuffle (reproducibility)
@export var board_hash_expected: String # (opsional) hash board awal untuk validasi tooling
@export var seed: int                   # reproducibility
# --- metadata solver (TIDAK wajib ikut build pemain; bisa di laporan terpisah) ---
@export var difficulty_score: float     # SOLVER METADATA ONLY — TIDAK dipakai di gameplay logic (boleh float)
@export var target_winrate: float       # band target (early 0.85-0.95 ... late 0.45-0.70)
@export var estimated_winrate: float    # hasil simulasi ensemble solver
@export var near_miss_rate: float       # metrik kualitas (menang di sisa langkah sedikit)
@export var min_moves_optimal: int
@export var validated: bool
```

**Enum DifficultyBand (konsisten, 5 band):**
```gdscript
enum DifficultyBand { FTUE_1_10, LEARNING_11_30, PRACTICE_31_60, CHALLENGE_61_100, ENDGAME_101_PLUS }
# Win-rate target per band: FTUE 85-95%, LEARNING 80-90%, PRACTICE 70-85%, CHALLENGE 60-80%, ENDGAME 45-70%
```

**Contoh konkret skema `pack_*.json` (kontrak generator↔loader — field name PERSIS):**
```json
{
  "schema_version": 1,
  "levels": [
    {
      "id": "lvl_042",
      "ruleset_version": 1, "rng_algorithm_version": 1, "generator_version": 1,
      "hand_crafted": false, "archetype": "combo_playground", "difficulty_band": "PRACTICE_31_60",
      "seed": 123456789,
      "board_width": 7, "board_height": 8,
      "playable_mask": [1,1,1,1,1,1,1, 1,1,1,1,1,1,1],
      "color_subset": [0,2,3,5], "num_colors": 4,
      "move_limit": 25,
      "objectives": [ {"type":"collect","tile_color":0,"target":30} ],
      "obstacles": [ {"type":"ice","layer":1,"positions":[[2,3],[3,3]],"hp":2} ],
      "prefilled": {},
      "allowed_specials": ["rocket","bomb","colorbomb"]
    }
  ]
}
```
> `snake_case` semua key. Loader & generator WAJIB pakai nama field ini persis (cegah `board_width` vs `boardWidth`).

**Obstacle entry (dukung bertumpuk via `layer`):**
```
{ "type": "ice",   "layer": 1, "positions": [[2,3],[3,3]], "params": {"hp": 2} }
{ "type": "crate", "layer": 2, "positions": [[2,3]],       "params": {"hp": 1} }
```
> `layer` = Z-order eksekusi (satu cell bisa punya beberapa obstacle bertumpuk). Saat match kena cell ber-obstacle, **layer teratas kena damage dulu**. Solver harus memodelkan ini identik.

> Catatan tipe: untuk **hand-crafted (1-30)** pakai `.tres` (editor visual Godot). Untuk **generated (101+)** pakai **JSON** (parse cepat, git-friendly, ringan untuk ratusan-ribuan file). Field gameplay pakai Array/int (lihat dok 04 §3.8 determinisme); Dictionary hanya metadata.

**Objective entry:**
```
{ "type": "collect", "tile": "red", "target": 40 }
{ "type": "clear_obstacle", "obstacle": "ice", "target": 25 }
{ "type": "bring_down", "item": "key", "target": 3 }
{ "type": "score", "target": 5000 }
```

> Format simpan: handcrafted → `.tres` (authoring) lalu di-export JSON; generated → `.json`. Obstacle pakai **Format A** di atas (`layer` + `positions` array + `params`) — bukan format `cell`/`layers` lama.

---

## 3. Kurva Kesulitan (Difficulty Model)

Generator dikendalikan oleh fungsi yang memetakan **nomor level → parameter**. Bukan linear; mengikuti pola "naik bertahap + variasi + sesekali spike + lalu lega".

### 3.1 Parameter yang dikontrol oleh kesulitan
| Parameter | Mudah | Susah |
|---|---|---|
| Ukuran papan | kecil (6x7) | besar (9x9) |
| Jumlah warna | 4 | 6 |
| (Pool warna selalu 6; generator memilih SUBSET aktif per level) | subset 4 | subset 6 |
| Rasio langkah vs kebutuhan | longgar (banyak langkah) | mepet |
| Jumlah & jenis rintangan | sedikit/none | banyak/campur |
| Kompleksitas objektif | tunggal | majemuk |
| "Ruang gerak" (kepadatan rintangan) | lega | sempit |

### 3.2 Bentuk kurva (konsep)
```
Kesulitan
  ^
  |                                 .-''   (plateau menantang)
  |                       _.-'''---'
  |            spike→ /\  /
  |        _.--'''   /  \/
  |  _.--''         (lega setelah spike = napas)
  +------------------------------------------> nomor level
   1   10   30   50      150        500 ...
```
- Naik halus, tapi selipkan "lega" setelah level susah (ritme, bukan tangga lurus).
- Spike sesekali memberi rasa pencapaian; jangan beruntun (frustrasi).

### 3.3 Implementasi
- `difficulty_model.gd`: `func params_for_level(n: int) -> Dictionary`.
- Disetir oleh `difficulty_curve.tres` (bisa di-tweak tanpa ubah kode).
- Tambahkan jitter/variasi berseed supaya level berdekatan tidak terasa identik.

---

## 4. Generator (Archetype-Based — niat, bukan cuma bentuk)

> **Revisi pasca-3-review:** generator = **drafting tool**, dibangun SETELAH vertical slice & FTUE terbukti fun (lihat roadmap Tahap 3 & 5). Pure-random / template-bentuk saja menghasilkan level "valid tapi hambar". Generator harus menghasilkan **ARCHETYPE** (niat desain), bukan sekadar tata letak.

### 4.0 Level Archetype (niat desain)
Tiap archetype punya "maksud" yang bikin level terasa disengaja:
| Archetype | Niat |
|---|---|
| `combo_playground` | papan terbuka, ruang untuk bikin & meledakkan special |
| `blocker_clearing` | rintangan mengarahkan perhatian; objektif = bersihkan |
| `bottleneck` | jalur sempit memaksa pemain berpikir penempatan |
| `objective_race` | kejar target spesifik dalam langkah terbatas |
| `special_tutorial` | dirancang agar special tertentu = cara termudah menang |
| `hard_near_miss` | sengaja ketat; kemenangan terasa "hampir kalah" (late game) |

Generator memilih archetype sesuai band level + difficulty, lalu mengisi parameter.

### 4.1 Alur
```
params = difficulty_model.params_for_level(n)
1. Pilih ARCHETYPE sesuai band level + difficulty (berseed).
2. Terapkan tata letak/mask khas archetype + ukuran papan.
3. Pilih subset warna aktif (4/5/6) + special yang diizinkan.
4. Tempatkan rintangan sesuai niat archetype (berseed).
5. Pilih objektif yang konsisten dgn archetype & rintangan.
6. Hitung move_limit awal (dikalibrasi solver ke band target).
7. Hasilkan LevelDefinition (kandidat, belum tervalidasi).
```

### 4.2 Aturan validitas dasar (sebelum solver)
- Tidak ada match otomatis saat papan mulai (atau di-resolve dulu).
- Objektif secara prinsip mungkin (mis. jumlah tile warna target cukup tersedia).
- Tidak ada konfigurasi rintangan yang mengunci papan secara permanen.

---

## 5. Solver Bot (Validasi)

### 5.1 Tujuan
Mengukur apakah level: **(a) bisa diselesaikan**, dan **(b) tingkat kesulitannya pas** — tanpa manusia memainkannya.

### 5.2 Cara kerja
```
Untuk tiap kandidat level:
  wins = 0; moves_list = []; stuck_list = []; special_list = []
  for i in range(N):                 # N = 100-500 simulasi (cukup; ribuan boros)
    seed_run = base_seed + i
    hasil = solver_play(level, seed_run, strategy)
    if hasil.menang: wins += 1
    moves_list.append(hasil.moves_used)
    stuck_list.append(hasil.moves_without_progress)
    special_list.append(hasil.specials_created)
  winrate = wins / N
  # + hitung metrik kualitas (lihat 5.4)
```

### 5.3 Strategi solver — ENSEMBLE (bukan greedy tunggal)
> Temuan KONVERGEN (GPT + DeepSeek): greedy tunggal tidak mensimulasikan manusia → win-rate solver tak berkorelasi dengan win-rate pemain. Pakai **ensemble 5 persona** lalu rata-ratakan.

| Persona | Perilaku | Mensimulasikan |
|---|---|---|
| `random_valid` | move valid acak | baseline bawah |
| `greedy_combo` | prioritas move yang memicu cascade/special | pemain agresif |
| `greedy_obstacle` | prioritas clear rintangan target | pemain fokus-objektif |
| `horizontal_scan` | scan kiri→kanan, ambil match pertama "cukup baik" | mata manusia kasual |
| `strategic_setup` | coba setup match-4/5 (lookahead 2-ply ringan) | pemain berpengalaman |

- **+ noise 10-20%** di pemilihan langkah (human error).
- Win-rate level = **rata-rata ensemble**, bukan satu strategi.
- MCTS/RL **TIDAK untuk v1** (terlalu lambat untuk ribuan level × ratusan run).

**Optimasi runtime ensemble (dari tech review):**
- **Adaptive run count dengan rigor statistik (BUKAN cutoff naif):** mulai 50 run, hitung **confidence interval (95% CI)** win-rate. Kalau CI **tidak overlap** dengan pita target band → STOP (data cukup). Kalau overlap → tambah 100 run, hitung ulang. Cap di 500 run. (50 run @ win-rate 50% punya CI ±~14% — terlalu lebar untuk diputuskan mentah; CI mencegah keputusan dari data noisy.)
- **Early-exit per run:** hentikan run kalau (a) tidak ada move valid (dead-board → reshuffle, bukan exit), (b) sisa langkah < minimum objektif, (c) **`moves_since_last_objective_progress > 5`** (stuck objective-focused). Potong 40-60%.

### 5.4 Penyaringan: win-rate PER-BAND + near-miss (REVISI pasca-3-review)
> **Win-rate 30-65% global itu SALAH** (GPT + DeepSeek): 30% di early level = uninstall massal. Target berbeda per band level:

```
Band level     Target win-rate (ensemble)   Catatan
Level 1-10      85-95%                       FTUE; hampir tak mungkin kalah
Level 11-30     80-90%
Level 31-60     70-85%
Level 61-100    60-80%
Level 101+      45-70% (boleh ada hard 35-50% sesekali, JANGAN beruntun)
```

**Gate kualitas (selain win-rate):**
**Gate kualitas (selain win-rate) — definisi & formula:**
```
- win_rate           = wins / total_runs
- near_miss_rate     = (menang dgn sisa langkah 1-3) / wins   → target ADA (jangan 0); SERU
- moves_variance     = variance(moves_used pada run yang menang) → jangan terlalu lebar (konsisten)
- stuck_rate         = run dengan "moves_since_last_objective_progress > 5" / total_runs → rendah
- reshuffle_per_run  = total_reshuffle / total_runs → rendah
- "menang dgn >30% langkah tersisa terlalu sering" → level TERLALU MUDAH → perketat
```
> **Definisi "stuck" (eksplisit):** bukan "tidak ada match" (itu dead-board → reshuffle), tapi **"tidak ada progress ke OBJEKTIF dalam >5 langkah"** (objective-focused). Track `moves_since_last_objective_progress`. Ini menangkap level membingungkan/terlalu sulit, bukan sekadar papan mentok.
> Formula lengkap diimplementasikan di `solver_stats.gd`.

### 5.5 Auto-kalibrasi move_limit
Solver mencari `move_limit` yang memberi win-rate sesuai band target level:
- Naik/turunkan langkah, uji ulang sampai win-rate masuk pita band-nya. Otomatis.

### 5.6 Keterbatasan & kalibrasi nyata
- Solver "melihat seluruh board & optimal"; pemain nyata di layar 6 inci, terdistraksi. Maka win-rate solver = **proksi kasar**, bukan kebenaran.
- **Wajib playtest manual** setiap level ship-able (penuh untuk hand-crafted, sampel untuk generated).
- Pasca-rilis: kalibrasi bobot ensemble terhadap fail-rate pemain asli (analytics).

---

## 6. Pipeline Produksi Level (End-to-End)

```
┌──────────────┐   ┌──────────┐   ┌──────────┐   ┌─────────────┐
│ Difficulty   │ → │Generator │ → │ Solver   │ → │ Filter &    │
│ Model (n)    │   │(kandidat)│   │(winrate) │   │ Calibrate   │
└──────────────┘   └──────────┘   └──────────┘   └─────┬───────┘
                                                        │ lolos?
                              regenerate ←── tidak ─────┤
                                                        │ ya
                                                  ┌─────▼───────┐
                                                  │ Simpan .json │
                                                  │ + metadata   │
                                                  └─────────────┘
```

- Dijalankan sebagai **tool script** di editor Godot (mode `--headless`) atau scene khusus "Level Forge".
- Output: batch file level + laporan ringkas (distribusi kesulitan, winrate, dll).
- Bisa generate ratusan/ribuan level dalam sekali jalan (semalaman jika perlu).

### 6.1 Realita Runtime & Keputusan Implementasi (dari tech review)
**Estimasi jujur (GDScript, interpreted):**
- 1 simulasi board (swap+cascade) ≈ 0.3-1 ms.
- 1 solver run (20-30 move) ≈ 10-30 ms.
- 500 run × 1 level ≈ ~15 detik. 1000 level ≈ **~4 jam** (sekuensial, best case); dengan re-generate iteratif bisa **8-20 jam**.

**Keputusan: solver tetap GDScript untuk v1** (BUKAN port C++/Rust dulu). Alasan:
- **Hindari dual-implementation.** Solver native = DUA implementasi match-3 (native + GDScript) yang bisa divergen → solver bisa memvalidasi level yang berperilaku beda dari game asli (validasi jadi bohong). Untuk solo dev baru-Godot, ini risiko korektnes & maintenance yang besar.
- **Belum perlu.** Generator hanya untuk level 101+ dan **setelah** soft launch buktiin retensi. Saat tuning, jalankan **batch kecil (10-20 level)**; batch penuh dijalankan **semalaman (one-time)**, bukan tiap iterasi.

**Mitigasi performa (urut, tanpa dual-impl):**
1. Core logic sudah **pure `RefCounted` tanpa dependensi Godot** → ringan & cepat relatif. Versi solver pakai `PackedInt32Array` + bit-encoding, minim alokasi.
2. **Adaptive run count + early-exit** (dok 05 §5.3): 50 run dulu, stop kalau jelas; early-exit kalau stuck/objektif mustahil. Untuk level non-kritis cukup **~20-50 run**; 500 run hanya level di zona abu-abu yang akan di-ship.
3. **Default: single-process sequential, jalankan overnight.** Untuk ~1000 level × adaptive run (~20-50 non-kritis) ≈ 2-3 jam — cukup untuk v1. **Multi-process OPSIONAL** kalau perlu lebih cepat — TAPI hati-hati: tiap instance Godot headless makan ~0.5-1GB RAM (4 proses = 4GB; bisa mentok di laptop dev) + overhead IPC file-based. Jadi multi-process hanya kalau RAM cukup & benar-benar perlu.
4. **Escape hatch:** KARENA core logic portable (tanpa Godot API), kalau kelak kebukti terlalu lambat di skala besar, port hot-path (`board`, `match_detector`) ke **GDExtension** — **tanpa nulis ulang game**, tinggal cermin logika yang sudah teruji. Lakukan HANYA jika ada bukti masalah nyata.

> **Kenapa BUKAN solver Python/C++ external (saran beberapa reviewer)?** Itu = implementasi match-3 KEDUA yang bisa **divergen** dari game GDScript → solver memvalidasi level yang berperilaku beda dari yang dimainkan pemain (validasi jadi bohong) + beban sinkronisasi 2 implementasi. Untuk solo dev, risiko korektnes ini lebih besar daripada manfaat kecepatan. GDExtension (kalau perlu) lebih aman karena bisa berbagi/mencerminkan satu sumber logika, dan dilakukan hanya saat terbukti perlu.

---

## 7. Strategi Konten (Manual vs Generated) — REVISI v2 pasca-3-review

> **Urutan KRITIS (konvergen 3 review):** buktikan fun (vertical slice) → hand-craft FTUE → BARU generator. Generator dibangun HANYA jika slice & soft-launch retensi menjanjikan.

| Rentang | Sumber | Alasan |
|---|---|---|
| 1-3 | **Vertical slice** full-juice (gate) | Buktikan fun sebelum apa pun |
| 1-30 | **Manual, kurikulum FTUE** | Penentu retensi D1/D7; tiap konsep diajarkan |
| 31-100 | **Manual / draft-assisted** (generator buat skeleton, lalu di-tweak tangan) | Kualitas + kontrol |
| 101+ | Generator (archetype) + ensemble solver + **playtest/spot-check** | Skala; HANYA setelah retensi terbukti |

### 7.1 Penyimpanan Level (chunked JSON)
- **JSON, di-chunk per ~100 level**, bukan 1 file raksasa (parse 5000 level sekaligus = 100-200ms blocking) atau 5000 file terpisah (overhead filesystem Android).
```
res://data/levels/
  pack_001_030.json   # hand-crafted (curriculum)
  pack_031_100.json   # draft-assisted
  pack_101_200.json   # generated
  ...
```
- Load pack saat dibutuhkan (lazy). Cache hasil parse di Dictionary `{id → LevelDefinition}` (~5000 × 2KB ≈ 10MB, aman).
- Hand-crafted (1-30) boleh `.tres` saat authoring (editor visual), tapi **di-export ke JSON** untuk konsistensi runtime + portabilitas (kalau solver kelak diport ke bahasa lain, JSON tetap kebaca).

> **Prinsip (3 review):** "3 level yang bikin senyum > 1000 level hambar." Generator = drafting tool, BUKAN auto-publish. Jangan pre-optimize scaling sebelum validasi demand (soft launch). Simpan seed + parameter tiap generated level agar reproducible.

---

## 8. Dynamic Difficulty Adjustment (DDA) — Runtime

Berbeda dari generator (offline). DDA berjalan di HP saat main:
- Jika pemain **kalah ≥ 3x** di satu level → diam-diam beri sedikit kelonggaran (mis. +1-2 langkah, atau papan awal sedikit lebih murah hati).
- Jika pemain **menang beruntun tanpa kesulitan** → boleh sedikit lebih ketat.
- Tujuan: jaga "flow state" (tidak bosan, tidak frustrasi).
- **Halus & tak terlihat.** Jangan sampai pemain merasa "dikasihani" secara terang-terangan.

---

## 9. Kalibrasi terhadap Data Nyata (pasca-rilis)

- Bandingkan winrate prediksi solver vs fail-rate pemain asli (dari analytics).
- Sesuaikan bobot heuristik solver agar prediksinya makin akurat.
- Loop ini bikin generator makin pintar seiring waktu — tanpa mendesain level manual.

---

## 10. Kenapa Ini Cocok untuk "Dibangun AI"

- Generator & solver adalah **logika murni & terukur** — ideal untuk AI implementasikan & uji otomatis.
- Tidak butuh kreativitas artistik manual untuk skala — mesin yang produksi, solver yang jaga kualitas.
- "10.000 level" berubah dari proyek mustahil jadi **"jalankan pipeline + verifikasi distribusi"**.

> Catatan jujur: kualitas level generated tetap di bawah level yang dirancang desainer ahli. Strategi mitigasi: handcraft bagian krusial (1-50), pakai solver ketat, dan kurasi spot-check. Tujuan kita "mendekati", bukan "menyamai" studio besar.
