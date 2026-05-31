# 04 — Technical Design Document (TDD) & Arsitektur

> Gimana game dibangun secara teknis di Godot 4.6.3. Acuan utama AI agent saat ngoding.

---

## 1. Prinsip Arsitektur

1. **Separation of Concerns: Data ↔ Logika ↔ Tampilan.**
   - **Data:** definisi level, config, save (resource/JSON). Pasif.
   - **Logika (core):** aturan main murni. **Tidak tahu apa pun soal grafis/Node visual.** Bisa jalan headless.
   - **Tampilan (view):** render, animasi, input. Membaca logika, menampilkannya.
2. **Logika headless & deterministik.** Board logic harus bisa dijalankan tanpa scene tree → penting untuk solver bot & unit test. Pakai seed untuk randomness (reproducible).
3. **Logic mengembalikan TurnReport (bukan event-driven via signal).** Saat pemain swap, core menghitung SELURUH hasil (cascade dst) secara instan lalu mengembalikan satu **TurnReport** (replay log). View "memutar ulang" report itu dengan animasi (`await` per step). Lihat §3.7. (Signal hanya untuk komunikasi logic→view tingkat tinggi, BUKAN untuk sequencing cascade.)
4. **Modular per fitur.** Tiap rintangan/special item = modul yang bisa ditambah tanpa ngerusak core.
5. **Composition over inheritance.** Manfaatkan node & resource Godot; hindari hierarki warisan dalam.

---

## 2. Struktur Folder Project

```
res://
├── project.godot
├── data/
│   ├── level_definition.gd     # Resource: skema 1 level (Godot-dependent → di data/, bukan core/)
│   ├── obstacle_entry.gd       # Resource: 1 entry obstacle (type-safe, hindari Array[Dictionary])
│   ├── objective_entry.gd      # Resource: 1 entry objektif
│   ├── levels/                 # level data (.tres / .json)
│   │   ├── handcrafted/        # ~30 level FTUE/kurikulum + draft-assisted
│   │   └── generated/          # hasil generator (101+)
│   ├── difficulty_curve.tres   # parameter kurva kesulitan
│   └── config/                 # game config (ekonomi, balancing)
├── i18n/                       # LOKALISASI (translation CSV/PO) — EN default + ID
├── tools/                      # TOOL DEV (tidak ikut build pemain)
│   └── forge.gd                # runner generator+solver (godot --headless)
├── core/                       # LOGIKA MURNI (headless, no visuals)
│   ├── board.gd                # state grid, swap, match, gravity, cascade
│   ├── match_detector.gd       # deteksi match (3/4/5/L/T)
│   ├── special_items.gd        # logika roket/bom/colorbomb + combo
│   ├── obstacles/              # tiap rintangan = file modul
│   │   ├── obstacle_base.gd
│   │   ├── ice.gd
│   │   └── box.gd
│   ├── objectives/             # kontrak di Fase 1, impl Fase 4
│   │   ├── objective_base.gd
│   │   └── (collect/clear_obstacle/bring_down/score).gd
│   ├── score.gd                # scoring murni (terpisah dari objectives)
│   ├── move_action.gd          # tipe event (dok 14 §0.1)
│   ├── turn_report.gd          # hasil 1 giliran (replay log)
│   ├── rng.gd                  # RNG berseed (deterministik)
│   ├── generator/
│   │   ├── level_generator.gd
│   │   └── difficulty_model.gd
│   └── solver/
│       ├── solver_bot.gd       # ensemble 5 persona + noise
│       ├── solver_personas.gd  # strategi: random/greedy_combo/greedy_obstacle/scan/setup
│       └── solver_stats.gd     # agregasi win-rate + metrik kualitas (near-miss, variance, stuck)
├── view/                       # TAMPILAN & ANIMASI (juice)
│   ├── board_view.tscn/.gd     # render papan, terjemahkan signal core
│   ├── tile_view.tscn/.gd
│   ├── effects/                # partikel, shake, suara
│   └── hud.tscn/.gd            # langkah, objektif, skor
├── meta/                       # META & PROGRESSION
│   ├── meta_scene.tscn/.gd     # layar koleksi Lumi (album, pulau menyala)
│   ├── economy.gd              # koin, nyawa, booster (singleton)
│   ├── progression.gd          # level unlock, bintang (singleton)
│   └── save_manager.gd         # baca/tulis user:// (singleton)
├── ui/                         # menu, peta level, popup, toko, settings
│   ├── main_menu.tscn
│   ├── level_map.tscn
│   ├── popups/
│   └── shop.tscn
├── services/                   # integrasi eksternal
│   ├── ads_service.gd          # AdMob wrapper (interface)
│   ├── iap_service.gd          # IAP wrapper
│   ├── analytics_service.gd    # event tracking wrapper
│   └── audio_manager.gd        # singleton suara/musik
├── tests/                      # unit test (GUT framework)
│   ├── test_board.gd
│   ├── test_match_detector.gd
│   └── test_solver.gd
└── addons/                     # plugin pihak ketiga (ads, GUT, dll)
```

---

## 3. Modul Inti (Core) — Tanggung Jawab

### 3.1 `board.gd` (jantung logika) — `RefCounted`, BUKAN Node
**Representasi state: `PackedInt32Array` flat row-major** (`index = y * width + x`), bukan Array 2D nested / Dictionary.
- Alasan: cache locality (board 8×8 muat L1 cache — signifikan di solver loop), serialisasi 1 baris (`cells.to_byte_array()`), snapshot murah (`cells.duplicate()`), iterasi deterministik.
- **Bit-encoding per cell (1 int32):** bits 0-5 = warna (0=kosong/blocked, 1-6=warna), bits 6-10 = tipe special (0=normal, 1=rocket_h, 2=rocket_v, 3=bomb, 4=colorbomb). Zero-alloc, tanpa `is`/`typeof` di hot path solver.
  - `encode(color, special) = color | (special << 6)`; `decode_color = v & 0x3F`; `decode_special = (v >> 6) & 0x1F`.
- `playable_mask: PackedInt32Array` (0=blocked, 1=playable) untuk board irregular. (Konsisten dgn `cells` — hindari konversi tipe; samakan di dok 05 §2.)
- **Penyimpanan obstacle (KEPUTUSAN):** untuk **v1 (obstacle simpel: ice hp1-2, box hp1-3)** pakai **`obstacle_layer: PackedInt32Array` paralel** (indexing sama dgn `cells`), encode `bits 0-7=type, 8-15=hp, 16-23=layer` → full cache locality untuk solver hot-path. Naik ke `Array` variant HANYA jika obstacle butuh state kompleks (v2+). `blocks_movement()` per-tipe dipakai gravity (box menahan, ice tidak).
- `class_name Board extends RefCounted` — **tidak meng-extend Node**, tidak menyentuh scene tree.
- **RNG di-INJECT** sebagai parameter (`resolve_swap(..., rng: GameRNG)`), **BUKAN autoload** → boleh ada banyak Board simultan (wajib untuk solver paralel).

Tanggung jawab:
- `setup(level_definition)` — bangun papan dari data.
- `resolve_swap(r1,c1,r2,c2, rng) -> TurnReport` — validasi swap, hitung SELURUH cascade, kembalikan replay log (lihat §3.7).
- `find_possible_moves()` — daftar swap valid (hint, solver, deteksi deadlock).
- `reshuffle(rng)` — acak ulang (berseed) jika tidak ada move (lihat §3.9 dead-board).

> Penting: `board.gd` **murni data + aturan**. Tidak `await`, tidak panggil Node visual, tidak emit signal untuk cascade. Mengembalikan TurnReport; view yang menganimasikan.

### 3.2 `match_detector.gd`
- Input: state grid. Output: daftar grup match + tipe (3, 4-line, 5-line, L, T, 2x2).
- Stateless / fungsi murni → mudah di-unit-test.

### 3.2b `gravity.gd` — KEPEMILIKAN STATE (klarifikasi)
- **Opsi A (DIPILIH):** `gravity.gd` = fungsi **static helper** yang menerima state board + mengembalikan `Array[MoveAction]` (daftar TileFell/TileSpawned). **TIDAK memodifikasi board langsung.** `board.gd` yang menerapkan perubahan.
- Alasan: hanya SATU tempat yang mutasi state board (`board.gd`) → cegah bug determinisme dari mutasi ganda. `gravity.gd` murni & mudah dites.
- `refill()` mengikuti pola sama: helper menghasilkan MoveAction, board apply. Urutan kolom kiri→kanan + RNG urut (dok 14 §4).

### 3.3 `special_items.gd`
- Aturan pembuatan special dari tipe match.
- Aturan aktivasi efek (area terdampak).
- Aturan combo (special + special) via **COMBO_TABLE** (dok 14 §3.2), bukan if-else.

### 3.4 `obstacles/` (pola modul)
- `obstacle_base.gd` (kontrak abstract) **dibuat sebagai stub di Fase 0/T0.x** (sebelum gravity T1.6) → interface: `get_type()`, `blocks_movement()`, `on_adjacent_match(match_size)->damage`, `is_destroyed()`, `get_layer()`.
- **Gravity (T1.6) cek `blocks_movement()` dari encoding `obstacle_layer`** (baca bit type), TANPA instantiate object → ringan & benar saat obstacle nyata datang (Fase 4).
- Implementasi konkret (ice/box/collectible) di Fase 4. Tambah rintangan = tambah file, gak ubah core.

### 3.5 `objectives/` — kontrak di Fase 1, implementasi Fase 4
- `objective_base.gd` (kontrak) **dibuat di Fase 1** (T1.13) supaya win/lose minimal pakai interface yang sama dgn versi final → T4.2 tinggal nambah implementasi konkret, bukan rewrite.
- Lacak progress dari **MoveAction event** (dok 14 §5), tentukan menang/kalah.

### 3.6 `rng.gd` — `GameRNG` (RefCounted)
- Wrapper `RandomNumberGenerator` berseed. Semua randomness lewat sini → reproducible.
- **JANGAN pernah pakai `randf()`/`randi()` global** di core. Fisher-Yates shuffle deterministik via RNG ini.
- State game pakai **int** (warna, skor, posisi grid); float HANYA untuk visual (posisi tween).

### 3.7 TurnReport — Pola Replay (KRITIS)
Core menghitung satu giliran penuh secara instan, mengembalikan `TurnReport` (RefCounted) berisi urutan **step** cascade. View memutar ulang dengan `await`.

> **Aturan resolusi LENGKAP & otoritatif ada di dok 14 (Ruleset Spec)** — urutan swap→match→special→clear→obstacle→gravity→refill→cascade, aturan combo, objective-credit-from-event. Core/solver/view/test WAJIB ikut dok 14.

```
TurnReport:
  is_valid_swap: bool
  steps: Array            # tiap step = satu gelombang cascade
  final_board: Array[int]
  objectives_progress: Dictionary   # metadata (bukan untuk gameplay logic)

Tiap step (Array/Dictionary terstruktur):
  matched           : sel yang match
  specials_created  : [{type, pos}]
  specials_triggered: [{type, pos, affected}]
  board_after_clear / after_gravity / after_refill : snapshot Array[int]
  new_tiles         : [{pos, color, from_row}]
```

**Aturan resolusi (jebakan match-3):**
1. **Match detection simultan** — deteksi SEMUA match sekaligus; horizontal+vertikal yang berpotongan → special di titik potong.
2. **Special chain via QUEUE (BFS/FIFO), bukan rekursif** — rocket memicu bomb memicu bomb lain: push ke queue, proses FIFO. Rekursif = stack overflow + non-deterministik.
3. **Urutan eksekusi special yang ter-trigger bersamaan (deterministik):** prioritas **ColorBomb > Rocket+Bomb (combo) > Bomb > Rocket**; tie-break by posisi (kiri→kanan, atas→bawah, sama dengan urutan iterasi). Solver WAJIB pakai urutan identik.
4. **Guard cascade** — `MAX_CASCADE = 50`; kalau depth >20, kemungkinan bug (log).
5. **Gravity per-kolom** menghormati blocker (obstacle yang menahan jatuh), bukan global.
6. **Special baru di-spawn di posisi swap terakhir pemain** (bukan tengah match) — konvensi terbukti.

> View: `for step in report.steps: await _animate_step(step)` → animasi cascade otomatis berurutan, input dikunci selama replay. Mudah di-test (assert ke report) & debug (print report).

### 3.8 Aturan Determinisme (WAJIB)
- Game logic **hanya pakai Array/typed Array** untuk state; Dictionary hanya metadata non-gameplay. (Godot 4 Dictionary mempertahankan insertion order, tapi konvensi Array lebih aman & cepat.)
- **int untuk semua game state**, float hanya visual.
- Semua random lewat `GameRNG` berseed.
- **Core TIDAK pakai signal** (urutan callback multi-listener tak dijamin). Signal hanya logic→view tingkat tinggi.
- **Verifikasi via test (wajib):** `test_determinism.gd` — board dengan seed sama harus hasilkan `final_board` identik setelah N move; seed beda harus (kemungkinan besar) beda. Ini test integrasi + jaring pengaman determinisme.

### 3.10 Error Handling & Crash Recovery di Core
- `resolve_swap()` ambil `initial_snapshot := cells.duplicate()` di awal.
- Setelah cascade, jalankan `_validate_board_state()`: tidak ada match tersisa (cascade benar selesai), tidak ada cell playable yang invalid.
- Jika invalid → `push_error`, **rollback** ke snapshot, return `TurnReport.invalid("internal_error")`. Lebih baik turn "gagal aman" daripada board corrupt yang merusak save.
- Validasi murah & headless-testable; jadi jaring pengaman saat ada bug cascade.

### 3.9 Dead-Board Detection & Reshuffle (keputusan desain — dok 11 D16)
- Setelah board settle, cek `find_possible_moves()`. Jika kosong → **tidak ada swap valid** → reshuffle.
- Reshuffle: acak ulang posisi tile yang ada (berseed via GameRNG), pastikan hasilnya punya ≥1 move valid & tidak ada match instan.
- **Keputusan terbuka (D11/D16):** reshuffle = GRATIS (tidak makan langkah) atau makan 1 langkah? **Default disarankan: GRATIS** (anti-frustrasi; bukan salah pemain). 
- **Solver WAJIB memodelkan reshuffle identik** dengan game — kalau beda, win-rate prediksi meleset. Masuk ke TurnReport sebagai action `RESHUFFLE`.

---

## 4. Lapisan View

- `board_view.gd` (Node2D) memanggil `logic.resolve_swap()`, lalu **memutar ulang `TurnReport`**: `for step in report.steps: await _animate_step(step)`. Input dikunci selama replay.
- Swap tidak valid → animasi shake + bounce-back (report.is_valid_swap == false).
- Input pemain (drag/tap) → `board.resolve_swap(...)`.
- Tidak ada logika game di view (hanya presentasi). Tidak ada state game yang "hidup" di view — semua dari report/snapshot.
- **Tween:** selalu `kill()` tween lama sebelum buat baru; kill tween di `_exit_tree()` (hindari crash pada freed node).

---

## 5. Singleton (Autoload)

| Singleton | Tanggung jawab |
|---|---|
| `GameState` | State global, level aktif, mode |
| `SceneManager` | Navigasi/transisi antar screen + app lifecycle (pause/resume, back button) |
| `Progression` | Level unlock, bintang, statistik |
| `Economy` | Koin, nyawa (+regen timer), booster |
| `SaveManager` | Persist ke `user://` (JSON terstruktur + versi schema) |
| `AudioManager` | Musik & SFX, volume settings |
| `AdsService` | Interface iklan (implementasi plugin-spesifik di belakang) |
| `Analytics` | Kirim event |
| `Settings` | Preferensi (suara, haptic, bahasa) |

> Pola: service eksternal (ads/iap/analytics) diakses lewat **interface** sehingga bisa di-stub saat development/test tanpa SDK Android.

### 5.1 GameState — spec field (jembatan view ↔ core)
```gdscript
# services/game_state.gd (autoload)
var current_level_id: String = ""
var current_level_def: LevelDefinition         # null kalau tidak in-game
var current_board: Board                        # RefCounted, dibuat saat level mulai
var current_rng: GameRNG
var moves_used: int = 0
var moves_limit: int = 0
var objectives_tracker                          # instance pelacak objektif
var score_x2: int = 0                           # basis ×2 (dok 14 §6)
var is_game_active: bool = false
func score_display() -> int: return score_x2 / 2
```

### 5.2 SceneManager — spec API
```gdscript
# services/scene_manager.gd (autoload)
func change_screen(screen_id: String, params := {}) -> void
    # screen_id: "main_menu" | "level_map" | "game" | "meta" | "settings"
    # transisi: fade out → ganti scene → fade in
func push_popup(popup: PackedScene, params := {}) -> void   # overlay di CanvasLayer
func go_back() -> void
    # popup aktif → tutup popup; in-game → konfirmasi keluar; menu → keluar app
# Lifecycle (skeleton di T0.8, isi penuh T6.7):
func _notification(what):
    # APPLICATION_PAUSED / WM_GO_BACK_REQUEST → auto-save + pause audio
    # APPLICATION_RESUMED → recompute nyawa offline (timestamp) + resume audio
```

> Autoload yang tak butuh frame update → `set_process(false)` (overhead kumulatif di low-end).

---

## 6. Skema Data Level (ringkas — detail di dok 05)

`LevelDefinition` adalah `Resource`. **Skema lengkap & otoritatif ada di dok 05 §2** (sumber kebenaran tunggal — jangan duplikasi di sini agar tidak drift).

Ringkas, isinya: identitas (`id:String`, `archetype`, `difficulty_band`, `hand_crafted`, `generator_version`, `seed`), bentuk papan (`board_width/height`, `playable_mask`), isi (`num_colors`/`color_subset`, `move_limit`, `objectives`, `obstacles` [Format A: layer+positions+params], `prefilled`, `spawn_pattern`, `allowed_specials`), dan metadata solver (`target_winrate`, `estimated_winrate`, `near_miss_rate`, `validated`).

Disimpan: handcrafted authoring `.tres` → export JSON; generated `.json` (chunked, dok 05 §7.1).

---

## 7. Save Data

- Lokasi: `user://save_v1.json` + `user://save_v1.bak`.
- **Atomic write:** tulis ke `.tmp` → rename existing ke `.bak` → rename `.tmp` ke file utama. Hindari corrupt saat app keburu ditutup.
- **Checksum** + **schema_version** disimpan. Load gagal/parse error → fallback ke `.bak`. Versi lama → `_migrate()`.
- Berisi: progress level, bintang, koin, nyawa + timestamp regen, state koleksi Lumi, settings, flag tutorial.
- **Anti-cheat ringan** (checksum) — bukan prioritas v1, tapi atomic+backup wajib. **Jangan repot enkripsi save** (Android root bisa bongkar; max XOR-obfuscation dengan salt kalau perlu) — effort tak sepadan.
- Cloud save: **TIDAK di v1** (overhead Google Play Games API + conflict resolution besar; pemain casual jarang expect cross-device). Tambah pasca-rilis jika retensi bagus.

---

## 8. Pola Performa (Mobile)

- Object pooling untuk tile & partikel (hindari alokasi tiap frame).
- Batasi partikel & shader; uji di perangkat low-end.
- Atlas tekstur untuk sprite tile (kurangi draw call).
- Hindari proses berat di `_process`; pakai signal & timer.
- Generator & solver dijalankan **offline (saat dev/build)**, bukan saat runtime di HP — hasilnya level data jadi yang dikirim.

---

## 9. Testing

- Framework: **GUT** (Godot Unit Test).
- Unit test wajib untuk: `match_detector`, `board.resolve()`, `special_items`, `solver`.
- Solver bot juga berfungsi sebagai **integration test**: kalau bot bisa menyelesaikan level handcrafted, berarti core sehat.
- Target: core logic ter-cover test sebelum dibungkus view.

---

## 10. Build & Ekspor (ringkas — detail di dok 09)

- Ekspor Android via Godot export templates.
- Butuh: JDK, Android SDK, keystore (signing).
- Output: AAB (Android App Bundle) untuk Play Store.
- Plugin Android (Ads/IAP) lewat Godot Android plugin system.

---

## 11. Konvensi Kode

- GDScript, `snake_case` untuk var/fungsi, `PascalCase` untuk class_name.
- Static typing sebisa mungkin (`var x: int`) — bantu performa & deteksi error.
- Tiap file punya tanggung jawab tunggal yang jelas.
- Komentar fokus ke "kenapa", bukan "apa".
- Signal untuk komunikasi logic→view tingkat tinggi, BUKAN sequencing cascade (pakai TurnReport).

---

## 12. Jebakan Godot 4.6 yang Harus Diwaspadai (dari tech review)

- **Tween pada freed node** → crash. Selalu `kill()` tween di `_exit_tree()` & sebelum assign baru.
- **Signal double-connect** saat re-enter scene → cek `is_connected()` atau connect sekali di `_init()`.
- **Signal membawa Array/Dictionary = pass-by-reference** → view bisa tak sengaja memutasi state core. **Kirim `.duplicate()` / data immutable** saat emit. (Lebih kuat lagi: pakai TurnReport, bukan signal, untuk data game.)
- **`await` pada object yang sudah freed** → coroutine stuck selamanya. Cek `is_instance_valid()` setelah await.
- **Android ABI:** export WAJIB `arm64-v8a`. JANGAN sertakan `x86_64` di APK produksi.
- **NDK version mismatch** → build bisa SUKSES tapi **crash saat startup**. Pakai NDK & Android Build Template yang TEPAT untuk Godot 4.6.3. (Alasan kuat untuk CI build dari awal.)
- **Resource loading di Android:** path salah/corrupt → crash tanpa stack trace jelas. GDScript tak punya try/catch → **validasi `ResourceLoader.exists()` / `FileAccess.file_exists()` sebelum load**.
- **Plugin AdMob (Poing Studios)** sering telat 1-2 bulan dari rilis Godot → **pin versi Godot, jangan upgrade minor di tengah proyek**.
- **`@export Array[Dictionary]`** nested masih buggy di inspector → untuk level editor, pakai custom Resource/inspector plugin.
- **RefCounted runtime type:** `obj is Board` works, tapi `get_class()` balikin "RefCounted". Pakai method `get_type()` sendiri kalau perlu cek tipe runtime.
- **`@export` default vs loaded Resource:** `LevelDefinition.new()` (di solver headless) pakai default value; `ResourceLoader.load()` (di game) pakai nilai dari file. Pastikan `setup()` **meng-override semua field** → kedua path identik.
- **`ResourceLoader` cache:** Resource di-cache permanen. Untuk JSON level yang load/unload per level, pakai **`FileAccess`** (tidak di-cache), bukan ResourceLoader. Saat dev edit `.tres`, pakai `CACHE_MODE_IGNORE` agar perubahan ke-load.
- **PackedInt32Array indexing:** simpan index ke local var dulu (`var i := y*width+x; cells[i]=v`) — lebih cepat di GDScript daripada `cells[y*width+x]=v`.
- **Tween memory leak:** tiap swap/cascade bikin tween; SELALU simpan ref & `kill()` sebelum buat baru + di `_exit_tree()`. Tanpa ini, leak baru muncul setelah 50+ level (bukan langsung crash).
- **Autoload `_process`:** set `set_process(false)` di autoload yang tak butuh frame update (overhead kumulatif di low-end).
- **`@export Array[Dictionary]` buggy** di inspector → pakai **custom Resource** untuk obstacle entry & objective entry (type-safe + hindari bug).

---

## 13. Performa Mobile — Detail Low-End (target: Adreno 306 / Mali-T620+ kelas)

> **PENTING (terverifikasi):** Godot 4 Compatibility renderer butuh **OpenGL ES 3.0**. **Mali-400 hanya ES 2.0 → TIDAK didukung** (akan crash/fallback). Maka floor device = **GPU ES 3.0** (Adreno 306, Mali-T620+, dll — umumnya HP Android **2016/2017+**). Mali-400 (HP ~2012-2015) **di luar target**. Ini masih mencakup mayoritas HP low-end SEA relevan di 2026. **Verifikasi di T0.9 dengan HP target nyata.**

- **Render board via `MultiMeshInstance2D` (1 draw call untuk seluruh papan), BUKAN 64 `Sprite2D` terpisah.** Update tile yang berubah via `set_instance_custom_data()`. Ini bisa jadi pembeda 30 vs 60 FPS di low-end. Target **< 80 draw calls total**.
- **Tidak ada `GPUParticles2D`** di GL Compatibility → pakai `CPUParticles2D` + **pooling** (pre-alloc ~20 emitter, max 10-15 partikel aktif, jangan alokasi saat gameplay). Alternatif lebih murah: **sprite-sheet flipbook** (4-8 frame) untuk efek pecah.
- **Background: pre-rendered noise TEXTURE (sampler2D) atau sprite-sheet, BUKAN shader noise procedural.** Shader procedural (sin/cos/fract/loop) bisa **gagal compile & crash-to-desktop di driver Mali lama tanpa error log**. Pre-rendered texture jauh lebih aman. Kalau tetap shader: maksimal 1-2 sample TANPA loop + test di device asli + fallback.
- **Font: BITMAP font (`.fnt` + `.png`), BUKAN TTF/OTF dinamis.** Beberapa Mali-400 render TTF buggy (glyph hilang/artifact) di GL Compatibility. Test font EARLY di device asli.
- **Text popup (skor/combo):** `Label` + tween scale/fade, bukan particle.
- **Atlas: target 1024×1024, atau 2048 dengan SPLIT.** Sebagian Mali-400 (VRAM <512MB shared) gagal load atlas 2048. Tekstur ETC2 (default export Android).
- **Draw calls < 80/frame.**
- **Audio:** preload SFX (.ogg q4, mono, 22050Hz) ke pool 8-16 `AudioStreamPlayer` (BUKAN `AudioStreamPlayer2D`). Jangan `load()` saat gameplay. Latency Android ~50-200ms — OK untuk match-3.
- **Memory target < 200MB.** APK target 40-60MB.
- **Throttle cascade thermal:** kalau cascade > 5 step beruntun, percepat animasi (durasi × 0.5) atau skip ke hasil akhir — cegah CPU spike → thermal throttling di HP murah.
- **WAJIB test di device fisik low-end**, bukan emulator.

---

## 14. Arsitektur Scene & Navigasi (gap dari review — KRITIS)

> Memisahkan logika (RefCounted) sudah jelas, tapi **struktur scene & navigasi** harus didefinisikan sejak awal agar AI agent tidak bikin keputusan ad-hoc.

### 14.1 Main scene & flow
```
Main (autoload-aware root)
  └─ SceneManager (autoload)  → kelola transisi antar "screen"
Screens (di-swap oleh SceneManager):
  - MainMenuScreen      (ui/main_menu.tscn)
  - LevelMapScreen      (ui/level_map.tscn)
  - GameScreen          (view/game_screen.tscn)   ← scene gameplay
  - MetaScreen          (meta/meta_scene.tscn)     ← koleksi Lumi / pulau
  - SettingsScreen      (ui/settings.tscn)
```

Flow navigasi:
```
MainMenu → LevelMap → (pilih level) → GameScreen → (menang) → MetaScreen → LevelMap
                                          → (kalah/keluar) → LevelMap
```

### 14.2 Struktur GameScreen (scene gameplay)
```
GameScreen (Node2D / Control root)
 ├─ BoardView (Node2D)            ← MultiMeshInstance2D untuk tile
 │   ├─ TileLayer (MultiMesh)     ← warna tile (1 draw call)
 │   ├─ SpecialLayer (Node2D)     ← special items (visual beda; sprite per item)
 │   ├─ ObstacleLayer (Node2D)    ← ice/box overlay
 │   └─ EffectsLayer (Node2D)     ← partikel, popup skor (di atas board)
 ├─ HUD (CanvasLayer)             ← langkah, objektif, skor, pause
 └─ PopupLayer (CanvasLayer)      ← pra-level, menang, kalah
```
- `BoardView` pegang referensi ke `Board` (logic, RefCounted) — bukan sebaliknya.
- **MultiMesh untuk tile normal** (identik, beda warna via instance custom data). **Special & obstacle = Node2D layer terpisah** (visual unik, jumlah sedikit) — bukan dipaksa ke MultiMesh.

### 14.3 SceneManager (autoload)
- `change_screen(screen_id, params)` — ganti screen via `change_scene_to_file()` ATAU show/hide (untuk transisi mulus + state retain).
- Transisi: fade in/out sederhana.
- **Aturan:** screen besar (menu/map/game/meta) = ganti scene. Popup/overlay = `add_child` di CanvasLayer (tidak ganti scene).

### 14.4 App Lifecycle (mobile — gap dari review)
Tangani via `_notification()` di autoload (mis. `GameState` / `SceneManager`):
- `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_GO_BACK_REQUEST` → **auto-save** + pause audio + pause timer visual.
- `NOTIFICATION_APPLICATION_RESUMED` → recompute **nyawa offline** (selisih waktu real, bukan timer in-app) + resume audio.
- Nyawa & daily reward dihitung dari **timestamp tersimpan vs `Time.get_unix_time_from_system()`**, bukan dari timer yang jalan — supaya benar walau app ditutup.
- Back button Android (`go_back_request`) → konfirmasi keluar / kembali ke screen sebelumnya, jangan langsung quit saat in-game.

### 14.5 Render special & obstacle dengan MultiMesh (klarifikasi limitasi)
- MultiMesh = grid tile identik (cepat, 1 draw call). Untuk yang butuh visual/animasi unik:
  - **Special items:** sprite Node2D di `SpecialLayer` (jumlah sedikit, OK).
  - **Obstacle:** sprite Node2D di `ObstacleLayer`.
  - **Animasi tile (hancur/jatuh):** untuk tile yang sedang animasi, bisa "lepas" dari MultiMesh sementara → animasikan sebagai Node2D sprite → kembalikan ke MultiMesh saat settle. ATAU animasikan via instance transform/custom-data kalau cukup. Pilih saat T1.11 (dokumentasikan keputusan final di kode).
