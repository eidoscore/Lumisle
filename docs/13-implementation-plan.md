# 13 — Implementation Plan (Breakdown Eksekusi per Task)

> Jembatan antara **roadmap** (dok 08: apa & kapan) dan **kode nyata** (gimana eksekusinya).
> Ini peta kerja harian: task atomik, file output, dependensi, dan acceptance criteria (DoD) tiap task.
> Acuan arsitektur: dok 04 (TDD). Sistem level: dok 05. Definition of Fun & workflow: dok 12.

---

## Cara Pakai Dokumen Ini

- **Format Task ID:** `T<fase>.<urutan>` — mis. `T1.3` = fase 1 task ke-3.
- **Tiap task punya:** Tujuan · Output (file/artefak) · Depends · DoD (Definition of Done) · Est (estimasi kasar).
- **DoD global per modul kode** (dari dok 12 §B.3): kode + komentar "kenapa" + unit test lulus (untuk logika) + Dev baca & paham + 0 error diagnostik + Dev setujui.
- **Status:** tandai `[ ]` → `[~]` (jalan) → `[x]` (selesai) saat dikerjakan.
- **Prinsip:** kerjakan berurutan dependensi. Logika + test dulu, baru view. Commit per task (saat diminta).
- **Estimasi** = kasar, asumsi ~5 jam/hari + bantuan AI. Bukan janji.

### Legenda effort
`XS` <½ hari · `S` ~½-1 hari · `M` ~1-2 hari · `L` ~3-5 hari · `XL` >1 minggu

---

## Peta Fase (ringkas)

| Fase | Nama | Output utama | Gate |
|---|---|---|---|
| 0 | Setup | Project Godot + git + GUT + CI | — |
| 1 | Core Playable | Board logic + match + cascade + view minimal | Checkpoint fun internal |
| 2 | Special Items + Juice | Roket/Bom/ColorBomb + combo + juice | Checkpoint fun internal |
| 3 | **VERTICAL SLICE** | 3-5 level full-juice + tes orang | ⛔ GATE (dok 12 §A) |
| 4 | Level Data + FTUE | LevelDefinition + objektif + rintangan + 20-30 level | Kurikulum mulus |
| 5 | Generator + Solver | Generator archetype + ensemble solver + pipeline | Distribusi win-rate sehat |
| 6 | Meta + Ekonomi + Save | Nyawa, koin, progress, peta level, save | Progress persist |
| 7 | Koleksi Lumi + FTUE penuh | Meta koleksi + daily + comeback | Ada "alasan balik" |
| 8 | Monetisasi + Polish + Soft Launch | Ads + IAP + analytics + ASO + closed test | Data soft launch |
| 9 | Rilis Global + Iterasi | Staged rollout + live ops ringan | Metric gate |

---

## FASE 0 — Setup Proyek
**Tujuan:** fondasi teknis siap, semua tooling jalan, satu test dummy lulus.
**Output fase:** project Godot bisa dibuka, struktur folder, git privat, GUT, CI skeleton.

> **STATUS FASE 0: ✅ SELESAI PENUH — 2026-05-31.** 9 unit test lulus headless (smoke + verifikasi setup). Deploy & jalan di HP fisik (Xiaomi, Android 16, GPU Mali-G57, OpenGL ES 3.2 Compatibility). Semua T0.1-T0.9 done.

### T0.1 — Inisialisasi project Godot `XS` — [x] SELESAI
- **Tujuan:** project Godot 4.6.3 baru, konfigurasi dasar mobile.
- **Output:** `project.godot` di `d:\Project\eidosMobile\Lumisle\` (folder game, terpisah dari folder engine). ✅ + `icon.svg`.
- **DoD:** ✅ project terbuka & jalan headless tanpa error; window **portrait** 1080×1920, stretch `canvas_items`/`keep`, orientation portrait; renderer **GL Compatibility**; nama app "Lumisle".
- **Depends:** —

### T0.2 — Struktur folder `XS` — [x] SELESAI
- **Tujuan:** folder sesuai arsitektur (dok 04 §2).
- **Output:** ✅ `core/`, `core/obstacles/`, `core/objectives/`, `core/generator/`, `core/solver/`, `view/`, `view/effects/`, `meta/`, `ui/`, `ui/popups/`, `services/`, `data/levels/handcrafted/`, `data/levels/generated/`, `data/config/`, `i18n/`, `tools/`, `tests/`, `tests/fixtures/`, `addons/`.
- **DoD:** ✅ semua folder ada + `.gdkeep` di folder kosong agar ter-commit.
- **Depends:** T0.1

### T0.3 — Git repo privat + .gitignore `XS` — [x] SELESAI
- **Tujuan:** version control + backup (dok 11 D12).
- **Output:** ✅ `git init` di `Lumisle/` (branch `main`), `.gitignore` Godot (`.godot/`, `export_presets.cfg`, `*.keystore`, engine folder, build artefak). ✅ remote `origin` (github.com:eidoscore/Lumisle.git) + initial commit ter-push ke `main`.
- **DoD:** ✅ repo lokal + remote siap; commit Fase 0 ter-push; engine folder TIDAK ikut (di-ignore).
- **Depends:** T0.1

### T0.4 — Setup GUT (unit test) `S` — [x] SELESAI
- **Tujuan:** framework test siap.
- **Output:** ✅ GUT 9.6.0 (kompatibel Godot 4.6) di `addons/gut/`; `.gutconfig.json`; `tests/test_smoke.gd` + `tests/test_t0_setup.gd`.
- **DoD:** ✅ test **lulus** via GUT runner headless CLI (9/9 test, 37 assert).
- **Depends:** T0.2

### T0.5 — Konvensi kode + template file `XS` — [x] SELESAI
- **Tujuan:** konsistensi (dok 04 §11).
- **Output:** ✅ `CONVENTIONS.md` (snake_case, static typing, core/view, TurnReport vs signal, tween, i18n CSV + key naming, test).
- **DoD:** ✅ dokumen ada.
- **Depends:** —

### T0.6 — CI skeleton (GitHub Actions) `S` — [~] FILE SIAP & TER-PUSH (verifikasi run di GitHub)
- **Tujuan:** build/test otomatis sejak awal (cegah panik export — dok 04 §12).
- **Output:** ✅ `.github/workflows/ci.yml` (setup-godot 4.6.3 → import → GUT headless; android-build placeholder `continue-on-error`). Ter-push ke remote.
- **DoD:** ⬜ verifikasi CI hijau di tab Actions GitHub (cek manual user di web). Command GUT identik dengan yang lulus lokal (9/9).
- **Depends:** T0.3, T0.4
- **Catatan:** ABI `arm64-v8a`; NDK/JDK17 sesuai Godot 4.6.3 (dok 04 §12).

### T0.7 — Autoload skeleton + spec `S` — [x] SELESAI
- **Tujuan:** singleton + spec field/API ke-set (dok 04 §5, §5.1, §5.2).
- **Output:** ✅ `services/game_state.gd` (field §5.1 + `score_display`/`reset_level_state`), `services/scene_manager.gd` (API §5.2: `change_screen`/`push_popup`/`go_back` + `_notification` lifecycle skeleton), `meta/save_manager.gd` (stub), `services/audio_manager.gd` (stub), `services/settings.gd` (stub). Semua `set_process(false)`.
- **DoD:** ✅ project jalan tanpa error; autoload terdaftar & ter-test (test_autoloads_registered, test_game_state_spec_fields).
- **Depends:** T0.2

### T0.7b — Kontrak abstract: `obstacle_base.gd` + `objective_base.gd` (stub) `XS` — [x] SELESAI
- **Tujuan:** interface ada SEBELUM gravity (T1.6) & win/lose (T1.13) butuh.
- **Output:** ✅ `core/obstacles/obstacle_base.gd` (get_type/blocks_movement/on_adjacent_match/is_destroyed/get_layer), `core/objectives/objective_base.gd` (credit_from_event/is_complete/get_progress/get_target). + `core/tile_codes.gd` (encoding + ObstacleType) sbg dependensi.
- **DoD:** ✅ kontrak terdefinisi (abstract, push_error); ter-test (test_abstract_contracts_exist, test_tile_codes_encode_decode).
- **Depends:** T1.2 (tile_codes — disediakan minimal di sini)

### T0.8 — Scene architecture & navigasi skeleton `M` (gap review — KRITIS) — [x] SELESAI
- **Tujuan:** struktur scene & navigasi jelas sejak awal (dok 04 §14).
- **Output:** ✅ `SceneManager.change_screen()` + `SCREENS` map; placeholder scene: `ui/main_menu.tscn`, `ui/level_map.tscn`, `view/game_screen.tscn`, `meta/meta_scene.tscn`, `ui/settings.tscn`. GameScreen berstruktur §14.2 (BoardView{TileLayer/SpecialLayer/ObstacleLayer/EffectsLayer} + HUD + PopupLayer).
- **DoD:** ✅ semua scene load & instantiate tanpa error (test_screens_instantiable); navigasi via tombol terhubung (main_menu↔level_map↔game↔meta↔settings). Transisi fade = ditambah saat polish.
- **Depends:** T0.7

### T0.9 — Android debug workflow `M` (gap review) — [x] SELESAI
- **Tujuan:** export & deploy ke device lancar sejak awal.
- **Output:** ✅ `export_presets.cfg` (Android, ABI **arm64-v8a** only, package `com.eidoscore.lumisle`, permission internet/vibrate/network). JDK17 (`JAVA_HOME`=microsoft-jdk-17) + Android SDK (`ANDROID_HOME`) + **export templates 4.6.3.stable terpasang** + debug keystore (auto Godot) + adb. `export/` dibuat (gitignored).
- **DoD:** ✅ APK debug (26.4 MB) ter-build, signed, aligned, verified → **install Success** ke device → **app jalan tanpa crash**.
- **Device terverifikasi:** Xiaomi 2312FPCA6G, **Android 16, arm64-v8a, GPU Mali-G57 MC2, OpenGL ES 3.2** (Compatibility) — jauh di atas floor ES 3.0. Bitmap font belum diuji (belum ada teks font kustom; UI pakai default — diuji saat ada font kustom).
- **Depends:** T0.1
- **Catatan:** Godot otomatis deteksi SDK/JDK dari env var. Build pakai template APK langsung (bukan gradle) — cukup untuk debug. Gradle custom build diaktifkan saat butuh plugin Android (AdMob/IAP, T8.x).

> **GATE FASE 0:** ✅ project terbuka & jalan, ✅ GUT lulus (9 test), ✅ navigasi antar-screen jalan (scene load+instantiate), ✅ git push ke origin/main, ✅ deploy & jalan di HP fisik (Android 16, ES 3.2). **FASE 0 SELESAI PENUH — lanjut Fase 1.**

---

## FASE 1 — Core Playable (Buktikan Fun)
**Tujuan:** match-3 bisa dimainkan end-to-end (1 level hardcoded), arsitektur Data/Logic/View berdiri.
**Output fase:** bisa swap → match → cascade → menang, jalan di editor + 1 HP low-end.
**Acuan:** dok 04 §3 (core), §3.7 (TurnReport), §3.8 (determinisme), §3.10 (error handling), **dok 14 (Ruleset Spec)**.

> **STATUS FASE 1: ✅ SELESAI (core) — 2026-05-31.** 63 unit test lulus (11 script, 693 assert). Deploy & jalan di HP fisik (Xiaomi Mali-G57, ES 3.2): board render via MultiMesh, swap interaktif, cascade, win/lose, tanpa crash, FPS sehat. T1.16 (art) = paralel, masih placeholder kotak warna (cukup untuk gate fun internal). Gate fun → Fase 2 (juice) untuk "kerasa enak".
>
> **CATATAN DEV (penting):** Setiap menambah `class_name` baru, WAJIB jalankan `godot --headless --import` SEKALI sebelum test/jalankan, agar class ter-registrasi di cache global (kalau tidak: "Identifier not declared"/"does not extend GutTest").

### T1.0 — Bekukan Ruleset Spec (dok 14) `S` — [x] SELESAI
- **Tujuan:** kontrak resolusi board tunggal & eksplisit SEBELUM nulis core.
- **Output:** ✅ dok 14 dibaca penuh & dipakai sebagai acuan; `ruleset_version: 1`.
- **DoD:** ✅ jadi acuan semua task core; semua implementasi core ikut §1-§7.
- **Depends:** —

### T1.1 — `GameRNG` (RefCounted, berseed) `XS` — [x] SELESAI
- **Output:** ✅ `core/rng.gd` — `next_int`/`next_range`/`pick`/`pick_packed`/`shuffle` (Fisher-Yates), `RNG_ALGORITHM_VERSION`.
- **DoD:** ✅ `test_rng.gd` (6 test): seed sama→urutan sama, shuffle deterministik, no global random.
- **Depends:** T0.4

### T1.2 — Encoding cell + konstanta `XS` — [x] SELESAI
- **Output:** ✅ `core/tile_codes.gd` — encode/decode warna+special (bit 0-5 / 6-10), ObstacleType, encode/decode obstacle (bit type/hp/layer, dok 14 §0.2).
- **DoD:** ✅ `test_tile_codes.gd`: round-trip semua kombinasi + obstacle.
- **Depends:** —

### T1.2b — `MoveAction` + `TurnReport` typed structures `S` — [x] SELESAI
- **Output:** ✅ `core/move_action.gd` (enum 12 tipe + factory), `core/turn_report.gd` (field final dok 14 §0.1 + `rejected()`/`invalid()`).
- **DoD:** ✅ kontrak tunggal core↔view; dipakai di semua resolusi.
- **Depends:** T1.2

### T1.3 — `Board` state + akses `S` — [x] SELESAI
- **Output:** ✅ `core/board.gd` (RefCounted) — `PackedInt32Array` cells + obstacle_layer paralel + playable_mask, idx/get/set, RNG di-inject, `setup()`, `board_hash()`.
- **DoD:** ✅ `test_board_setup.gd`: dimensi, idx, akses, obstacle, setup deterministik.
- **Depends:** T1.1, T1.2

### T1.4 — `MatchDetector` (fungsi murni) `M` — [x] SELESAI
- **Output:** ✅ `core/match_detector.gd` (static) — `find_all` (runs → merge intersecting (union-find) → classify), klasifikasi LINE_3/4/5/SHAPE_LT, `has_any_match`.
- **DoD:** ✅ `test_match_detector.gd` (10 test): H/V-3, line-4/5, L, T, perpotongan, no-match, non-playable break.
- **Depends:** T1.3

### T1.5 — Board init tanpa match awal `S` — [x] SELESAI
- **Output:** ✅ `_fill_no_initial_match` + `_pick_safe_color` (re-roll vs 2 tetangga kiri/atas).
- **DoD:** ✅ `test_board_setup.gd`: 100 seed + subset-4 50 seed → tidak ada match awal.
- **Depends:** T1.4

### T1.6 — Gravity + Refill (static helper) `M` — [x] SELESAI
- **Output:** ✅ `core/gravity.gd` (static) — `apply_gravity`/`apply_refill` → Array[MoveAction]; per kolom kiri→kanan, RNG urut (dok 14 §4); blocker via encoding (no instantiate). Board yang apply (ownership Opsi A).
- **DoD:** ✅ `test_gravity.gd` (6 test): fall, stack, blocker menahan, refill penuh, deterministik.
- **Depends:** T1.3, T0.7b

### T1.7 — `TurnReport` + `resolve_swap` (cascade loop) `L` — [x] SELESAI
- **Output:** ✅ `board.resolve_swap()` (STEP A-F dok 14 §1): validasi swap → swap → cek match → loop cascade (clear union → gravity → refill) → dead-board reshuffle → validasi. Guard MAX_CASCADE=64. **Hook modular** `_special_create_fn`/`_special_trigger_fn` (Callable) untuk Fase 2 TANPA rewrite loop.
- **DoD:** ✅ `test_resolve_swap.gd`: swap invalid ditolak, no-match bounce-back (tak makan langkah), valid accepted+clear, cascade stabil, no infinite loop. Skor basis ×2 (dok 14 §6).
- **Depends:** T1.4, T1.6

### T1.8 — Error handling + validasi state `S` — [x] SELESAI
- **Output:** ✅ `_validate_board_state()` (no match tersisa + no sel kosong) + snapshot/rollback di `resolve_swap` → `TurnReport.invalid()`.
- **DoD:** ✅ tercakup di test_resolve_swap (error="" pada resolusi normal; rollback path tersedia).
- **Depends:** T1.7

### T1.9 — `find_possible_moves` + dead-board/reshuffle `M` — [x] SELESAI
- **Output:** ✅ `find_possible_moves()` (cek swap kanan/bawah → match), `reshuffle(rng)` (GRATIS, no match instan + ≥1 move, dok 14 §1 STEP E / D16).
- **DoD:** ✅ `test_resolve_swap.gd`: deteksi deadlock (2x2 catur), reshuffle hasilkan board valid + ada move.
- **Depends:** T1.7

### T1.10 — Test determinisme `S` — [x] SELESAI
- **Output:** ✅ `tests/test_determinism.gd` — `board_hash()` + replay runner `(seed, moves) → urutan hash`.
- **DoD:** ✅ setup seed sama identik, seed beda berbeda, replay 2x identik.
- **Depends:** T1.7

### T1.10b — Golden board fixtures `M` — [x] SELESAI
- **Output:** ✅ `tests/test_golden_fixtures.gd` — fixture match 3/4/5/L-T, gravity+blocker, resolve stabil, deadlock+reshuffle.
- **DoD:** ✅ semua fixture lulus. **Living artifact** — tambah saat special/combo/obstacle (Fase 2/4).
- **Depends:** T1.7, T1.10

### T1.11 — `BoardView` minimal + render MultiMesh `L` — [x] SELESAI
- **Output:** ✅ `view/board_view.gd` (Node2D) + `MultiMeshInstance2D` (1 draw call, tile = quad berwarna placeholder, 6 palet), replay TurnReport per step, refresh via `set_instance_color`. Struktur GameScreen §14.2.
- **DoD:** ✅ board render di HP; swap → animasi clear/gravity/refill berurutan; input dikunci saat replay.
- **Depends:** T1.7, T0.8

### T1.12 — Input swap (drag/tap) `S` — [x] SELESAI
- **Output:** ✅ `_unhandled_input` (mouse + touch) → tap 2 tile bersebelahan → `resolve_swap`; tap jauh = seleksi ulang.
- **DoD:** ✅ bisa main pakai sentuh/mouse (terverifikasi di HP); swap invalid → refresh (bounce).
- **Depends:** T1.11

### T1.13 — Win/lose minimal (via ObjectiveStub) + 1 level hardcoded `S` — [x] SELESAI
- **Output:** ✅ `core/objectives/collect_objective.gd` (impl `ObjectiveBase`, credit dari event TILE_CLEARED, dok 14 §5) + `view/game_screen.gd` (level hardcoded 7×8, 5 warna, move limit 20, objektif kumpulkan 25 merah) + HUD (langkah/objektif/hasil).
- **DoD:** ✅ menang (objektif lengkap) & kalah (langkah habis); HUD update. T4.2 tinggal nambah tipe objektif.
- **Depends:** T1.7, T0.7b

### T1.14 — Performance monitor (autoload) `S` — [x] SELESAI
- **Output:** ✅ `services/performance_monitor.gd` (autoload) — sampling FPS + frame-time p95 + `OS.get_model_name()`, warning kalau <30 FPS, TODO kirim analytics (T8.5).
- **DoD:** ✅ jalan di HP, tidak ada warning FPS drop (FPS sehat).
- **Depends:** T0.7

### T1.15 — Uji di HP fisik `S` — [x] SELESAI
- **Output:** ✅ APK debug 26MB → install → jalan di Xiaomi (Android 16, Mali-G57, **ES 3.2**).
- **DoD:** ✅ tidak crash, swap/cascade jalan, FPS sehat (≥30, no drop warning), navigasi Menu→Map→Game OK.
- **Depends:** T1.13, T0.9

### T1.16 — Art acquisition & pipeline (PARALEL, non-blocking) `M` — [ ] DITUNDA (placeholder dipakai)
- **STATUS:** Belum dikerjakan. Fase 1 pakai **tile placeholder kotak warna** (cukup untuk validasi logika & gate fun internal). Aset CC0 + palet final dikerjakan paralel sebelum/awal Fase 2-3 (vertical slice butuh art proper). TIDAK memblok core.
- **Depends:** — (paralel)

> **GATE FASE 1 (checkpoint fun internal):** ✅ match-3 bisa dimainkan (board render, swap, cascade, win/lose), ✅ jalan di HP, ✅ 63 unit test core lulus. Core terasa benar secara mekanik. **Lanjut Fase 2** (special items + juice) untuk bikin "kerasa enak". Art (T1.16) menyusul paralel.

---

## FASE 2 — Special Items + Juice Dasar
**Tujuan:** game mulai "kerasa enak" — special items, combo, dan juice.
**Acuan:** GDD §3.4-3.5 (special & combo), §9 (juice), dok 04 §3.7 (urutan eksekusi).

### T2.1 — Pembuatan special dari match `M`
- **Tujuan:** spawn roket/bom/colorbomb sesuai tipe match (GDD §3.4).
- **Output:** `core/special_items.gd` — aturan: line-4 → roket (orientasi sesuai arah match), L/T → bom, line-5 → colorbomb. Spawn di posisi swap terakhir.
- **DoD:** unit test: tiap pola match → special benar di posisi benar.
- **Depends:** T1.7

### T2.2 — Aktivasi efek special `M`
- **Tujuan:** efek saat special meledak (roket = baris/kolom, bom = area, colorbomb = 1 warna).
- **Output:** logika area-of-effect di `special_items.gd`; integrasi ke cascade (queue/FIFO).
- **DoD:** unit test: tiap special → sel terdampak benar; integrasi ke TurnReport.
- **Depends:** T2.1

### T2.3 — Combo special + special `M`
- **Tujuan:** gabungan 2 special (GDD §3.5) dengan urutan deterministik (ColorBomb>Combo>Bomb>Rocket).
- **Output:** tabel combo di `special_items.gd`; aturan resolusi.
- **DoD:** unit test: minimal roket+roket, roket+bom, colorbomb+roket, colorbomb+colorbomb. Hasil deterministik.
- **Depends:** T2.2

### T2.4 — Chain reaction (special trigger special) `M`
- **Tujuan:** special yang kena ledakan ikut meledak (via QUEUE, bukan rekursif).
- **Output:** queue FIFO di cascade loop; guard.
- **DoD:** unit test: bom kena roket → keduanya resolve berurutan, deterministik, no stack overflow.
- **Depends:** T2.2

### T2.5 — Juice: animasi & partikel `L`
- **Tujuan:** sensasi memuaskan (GDD §9).
- **Output:** `view/effects/` — animasi tile hancur (scale+fade), partikel CPU + pooling, screen shake ringan, flash; tween easing untuk jatuh (bounce).
- **DoD:** memicu match/special terasa "enak"; pooling jalan (no alloc saat gameplay); throttle cascade >5 step.
- **Depends:** T1.11, T2.2

### T2.6 — Juice: audio + haptic `M`
- **Tujuan:** SFX & getaran (GDD §9, dok 04 §13).
- **Output:** `services/audio_manager.gd` — pool 8-16 AudioStreamPlayer, preload SFX (.ogg); SFX match (pitch naik per tingkat), special, combo, menang/kalah; haptic combo/menang.
- **DoD:** suara sinkron dgn animasi; no load saat gameplay; haptic best-effort (cek device).
- **Depends:** T2.5

### T2.7 — Juice: idle hint + reward menang `S`
- **Tujuan:** polish kecil berdampak besar.
- **Output:** idle hint (tile berkedip setelah ~5 detik); animasi reward menang (koin/bintang terbang).
- **DoD:** hint muncul saat idle; layar menang memuaskan.
- **Depends:** T2.5, T1.9

> **GATE FASE 2 (checkpoint fun krusial):** memicu special & combo terasa memuaskan (penilaian Dev). Kalau belum "enak" → iterasi juice dulu. Ini fondasi sebelum vertical slice.

---

## FASE 3 — VERTICAL SLICE (⛔ GATE WAJIB)
**Tujuan:** buktikan 1 slice terasa LEBIH HIDUP daripada match-3 generik, ke ORANG NYATA.
**Acuan:** dok 12 §A (Definition of Fun F1-F8). Ini gate paling penting di seluruh proyek.

### T3.1 — 3-5 level hand-crafted (full juice) `M`
- **Tujuan:** level yang dipoles habis (bukan placeholder), kurva sangat mudah → mulai menantang.
- **Output:** 3-5 level hardcoded/`.tres` dengan objektif, juice penuh, balancing manual.
- **DoD:** tiap level bisa dimenangkan, terasa "disengaja" (ada momen wow), bukan acak.
- **Depends:** Fase 2 selesai

### T3.2 — FTUE mini (tutorial invisible) `M`
- **Tujuan:** level 1-3 ajari tanpa popup (dok 12, GDD §8).
- **Output:** highlight tile swap pertama; guaranteed win level 1; perkenalan 1 special.
- **DoD:** orang baru bisa main level 1 tanpa dijelaskan.
- **Depends:** T3.1

### T3.3 — Meta placeholder (1 layar pulau, ~3 state) `S`
- **Tujuan:** kasih "alasan main" minimal untuk diuji.
- **Output:** `meta/meta_scene.gd` — layar pulau redup→bercahaya, 3 langkah upgrade pakai bintang (art placeholder).
- **DoD:** menang level → progress meta terlihat.
- **Depends:** T3.1

### T3.4 — Analytics lokal / Debug HUD `S`
- **Tujuan:** ukur perilaku tester (dok 09 §7, struktur event).
- **Output:** logger lokal: level_start/complete/fail, moves_left, waktu, FPS. HUD debug toggle.
- **DoD:** data sesi tercatat ke file lokal untuk ditinjau.
- **Depends:** T1.14

### T3.5 — Build & uji ke ≥5 orang non-dev `M`
- **Tujuan:** eksekusi Definition of Fun (dok 12 §A.2).
- **Output:** APK; sesi observasi terpandu (jangan bantu); catat F1-F8.
- **DoD:** data terkumpul dari ≥5 orang + 1 HP low-end (F8).
- **Depends:** T3.1-T3.4

### T3.6 — Evaluasi GATE `XS`
- **Tujuan:** keputusan jujur lanjut/iterasi/stop.
- **Output:** ringkasan F1-F8 vs ambang (dok 12 §A.3).
- **DoD:** **LULUS semua F1-F8 → lanjut Fase 4.** Gagal sebagian → iterasi slice. Gagal 3 ronde → evaluasi fundamental.
- **Depends:** T3.5

> **⛔ GATE FASE 3:** Tidak lanjut ke Fase 4 (apalagi generator) sebelum gate ini LULUS. Ini rem darurat objektif sebelum investasi besar.

---

## FASE 4 — Level Data + FTUE Kurikulum
**Tujuan:** lepas dari hardcoded; 20-30 level FTUE yang mengajarkan tiap konsep.
**Acuan:** dok 05 §2 (skema + JSON schema), GDD §8 (kurikulum), dok 05 §7.1 (chunked JSON).

### T4.0 — Entry Resources (ObstacleEntry + ObjectiveEntry) `S` (gap review)
- **Tujuan:** type-safe + hindari bug `@export Array[Dictionary]` (dok 04 §12).
- **Output:** `data/obstacle_entry.gd` (Resource: obstacle_type, layer, positions:Array[Vector2i], hp, blocks_movement), `data/objective_entry.gd` (Resource: objective_type, target, tile_color, obstacle_type).
- **DoD:** bisa di-edit via inspector; LevelDefinition pakai `Array[ObstacleEntry]`/`Array[ObjectiveEntry]`.
- **Depends:** —

### T4.1 — `LevelDefinition` Resource + loader `M`
- **Output:** `data/level_definition.gd` (Resource, semua field dok 05 §2; pakai entry resources T4.0); loader JSON chunked (`pack_001_030.json`, schema dok 05) + cache `{id → LevelDefinition}`. Pakai `FileAccess` untuk JSON (bukan ResourceLoader yang di-cache).
- **DoD:** load level dari JSON sesuai schema, board ter-setup benar (termasuk konversi Format A → obstacle_layer, dok 14 §0.2); unit test loader.
- **Depends:** T1.3, T4.0

### T4.1b — Exporter `.tres` → JSON `S` (gap review)
- **Tujuan:** authoring di `.tres` (editor visual) tapi runtime baca JSON (satu format runtime, no drift).
- **Output:** `tools/export_levels.gd` (tool script) — baca `.tres` LevelDefinition → tulis JSON ke `data/levels/handcrafted/pack_*.json`.
- **DoD:** level `.tres` ter-export ke JSON valid sesuai schema; runtime load hasilnya.
- **Depends:** T4.1

### T4.2 — `objectives` (semua tipe) + `score.gd` terpisah `M`
- **Output:** implementasi `objective_base` (T0.7b): collect, clear_obstacle, bring_down, score. **`core/score.gd` TERPISAH** (fungsi murni: MoveAction → delta skor ×2, cascade multiplier int, dok 14 §6) — objective tipe `score` memakainya.
- **DoD:** unit test tiap tipe objektif + score (basis ×2, multiplier int); credit dari MoveAction event (dok 14 §5).
- **Depends:** T1.13 (sudah ada collect + objective_base)

### T4.3a — Obstacle: integrasi base ke board `S`
- **Output:** integrasi `obstacle_base` + konversi Format A → `obstacle_layer` (dok 14 §0.2) lengkap; `on_adjacent_match` damage flow ke cascade.
- **DoD:** unit test damage obstacle dari match di sebelah; integrasi gravity (blocks_movement).
- **Depends:** T4.1, T0.7b

### T4.3b — Obstacle statis: Ice + Box `M`
- **Output:** `core/obstacles/ice.gd` (hp, pecah dari match sebelah, tidak block gravity), `box.gd` (block gravity).
- **DoD:** unit test ice & box; emit ObstacleDamaged/Destroyed event benar.
- **Depends:** T4.3a

### T4.3c — Obstacle bergerak: Collectible (bring-down) `M`
- **Output:** `core/obstacles/collectible.gd` — item yang harus diturunkan ke baris bawah (mekanik movement beda dari statis).
- **DoD:** unit test bring-down; event `ItemDelivered`; integrasi objektif bring_down.
- **Depends:** T4.3a

### T4.4 — HUD lengkap `S`
- **Output:** `view/hud.gd` — langkah, objektif (ikon+counter), skor, tombol pause/booster placeholder.
- **DoD:** HUD update real-time dari TurnReport/objectives.
- **Depends:** T1.13, T4.2

### T4.5 — Hand-craft 20-30 level (kurikulum) `L`
- **Output:** level 1-30 sesuai tabel GDD §8 (swap→special→combo→obstacle), win-rate band early tinggi. Authoring `.tres` → export JSON (T4.1b).
- **DoD:** tiap level di-playtest Dev; kurva terasa mulus; konsep diajarkan bertahap.
- **Depends:** T4.1, T4.1b, T4.2, T4.3b

### T4.6 — Level editor tool (in-engine) `M` (opsional tapi disarankan)
- **Output:** `tools/level_editor` — scene untuk menyusun level visual → simpan `.tres` → export JSON.
- **DoD:** bisa bikin/edit level tanpa ngetik JSON manual.
- **Depends:** T4.0, T4.1b

> **GATE FASE 4:** 20-30 level FTUE jalan dari data (JSON), kurikulum mulus, rintangan dasar berfungsi.

---

## FASE 5 — Generator + Ensemble Solver
**Tujuan:** produksi konten skala sebagai drafting tool (HANYA setelah slice & FTUE terbukti).
**Acuan:** dok 05 (lengkap). Berjalan offline (headless).

### T5.1 — `difficulty_model.gd` + `difficulty_curve.tres` `M`
- **Output:** `params_for_level(n) -> Dictionary` (ukuran, subset warna, rintangan, move_limit, band); kurva tunable.
- **DoD:** kurva menghasilkan parameter masuk akal per band; unit test boundary.
- **Depends:** T4.1

### T5.2 — Generator archetype-based `L`
- **Output:** `core/generator/level_generator.gd` — archetype (combo_playground/blocker_clearing/bottleneck/objective_race/special_tutorial/hard_near_miss) + parameter + seed; validitas dasar (no initial match, objektif mungkin).
- **DoD:** generate kandidat valid per archetype; unit test validitas.
- **Depends:** T5.1, T4.3

### T5.3 — Ensemble solver (5 persona) `L`
- **Output:** `core/solver/solver_personas.gd` (random_valid, greedy_combo, greedy_obstacle, horizontal_scan, strategic_setup 2-ply) + noise; `solver_bot.gd` (simulasi penuh pakai core yang sama — bukan implementasi kedua).
- **DoD:** solver memainkan level via `board` yang sama; deterministik per seed; unit test tiap persona jalan.
- **Depends:** T5.2, T1.7

### T5.4 — `solver_stats.gd` (metrik + formula) `M`
- **Output:** win_rate, near_miss_rate, moves_variance, stuck_rate (objective-focused >5), reshuffle_per_run — formula dok 05 §5.4.
- **DoD:** unit test formula dgn data sintetis.
- **Depends:** T5.3

### T5.5 — Adaptive run count (CI-based) + early-exit `M`
- **Output:** loop run dengan confidence interval (stop kalau CI tak overlap band, cap 500); early-exit (stuck/objektif mustahil).
- **DoD:** runtime turun signifikan vs fixed-500; keputusan stop berbasis CI, bukan cutoff naif.
- **Depends:** T5.4

### T5.6 — Pipeline tool "Level Forge" (headless) `M`
- **Output:** `tools/forge.gd` — `godot --headless`: generate → solve → filter (band + gate kualitas) → kalibrasi move_limit → simpan JSON chunk + laporan distribusi. Single-process sequential default.
- **DoD:** hasilkan batch 50-100 level tervalidasi + laporan; spot-check manual sampel.
- **Depends:** T5.5, T5.2

### T5.7 — Validasi & kurasi `M`
- **Output:** spot-check manual ≥10% level generated; tandai yang jelek; tuning model.
- **DoD:** distribusi win-rate per-band sehat; near-miss rate ada; level generated layak.
- **Depends:** T5.6

> **GATE FASE 5:** generator menghasilkan level berkualitas (lolos metrik + spot-check). Kalau distribusi kacau → perbaiki model/solver.

---

## FASE 6 — Meta, Ekonomi & Save
**Tujuan:** progress, pacing, persistence.
**Acuan:** dok 06 (ekonomi), dok 04 §7 (save).

### T6.1 — `SaveManager` (atomic + backup + schema + checksum) `M`
- **Output:** `meta/save_manager.gd` — atomic write (.tmp→rename), backup .bak, schema_version, checksum, migrasi.
- **DoD:** unit test: save/load round-trip; corrupt → fallback backup; versi lama → migrate.
- **Depends:** T0.7

### T6.2 — `Economy` (koin + nyawa + regen) `M`
- **Output:** `meta/economy.gd` — koin; nyawa max 5, regen 1/25 mnt, +iklan cap 5/hari (D4); timestamp regen persist.
- **DoD:** unit test regen timer; nyawa berkurang saat kalah; cap iklan.
- **Depends:** T6.1

### T6.3 — `Progression` (unlock + bintang) `S`
- **Output:** `meta/progression.gd` — level unlock berurutan, bintang per level.
- **DoD:** unit test unlock logic; persist.
- **Depends:** T6.1

### T6.4 — Peta level (navigasi) `M`
- **Output:** `ui/level_map.gd` — node level + jalur, status (locked/unlocked/cleared), bintang.
- **DoD:** navigasi peta → pilih level → main → balik dengan progress terupdate.
- **Depends:** T6.3, T4.4

### T6.5 — Popup pra-level & hasil `S`
- **Output:** `ui/popups/` — pra-level (objektif, booster), menang (reward), kalah (tawaran +5 langkah via koin/rewarded).
- **DoD:** flow lengkap; tawaran +langkah anti-frustrasi.
- **Depends:** T6.2

### T6.6 — Booster dasar `M`
- **Output:** pre-level (mulai dgn special) + in-level (palu, swap, +langkah); konsumsi koin.
- **DoD:** booster mengubah board/economy benar; unit test.
- **Depends:** T6.2

### T6.7 — App lifecycle handling (mobile) `M` (gap review)
- **Tujuan:** Android pause/resume/background tanpa kehilangan progress (dok 04 §14.4). **Skeleton sudah ada di T0.8/SceneManager; ini isi penuh.**
- **Output:** lengkapi `_notification()` — auto-save saat pause/go_back; recompute nyawa & daily dari timestamp (offline calc); pause/resume audio; back button handling. **Tulis ke variable saat pause, flush I/O di next frame** (hindari I/O berat saat backgrounding).
- **DoD:** tutup app saat main → buka lagi → progress utuh, nyawa benar sesuai waktu berlalu, audio normal.
- **Depends:** T6.1, T6.2, T0.8

> **GATE FASE 6:** progress persist antar sesi, ekonomi nyawa/koin jalan, peta level berfungsi, lifecycle mobile aman.

---

## FASE 7 — Koleksi Lumi + FTUE Penuh
**Tujuan:** hook retensi (koleksi) + sesi pertama memikat.
**Acuan:** GDD §6.1 (koleksi Lumi), §8 (FTUE).

### T7.1 — Sistem koleksi Lumi + album `L`
- **Output:** `meta/` — kumpulkan Lumi pakai bintang, album (entri+lore+rarity), area menyala saat lengkap.
- **DoD:** menang → bintang → bebaskan Lumi → album terisi → area bercahaya. Persist.
- **Depends:** T6.3, T3.3

### T7.2 — Cerita ringan / maskot `M`
- **Output:** dialog pendek antar-area (1-2 kalimat), maskot pemandu.
- **DoD:** narasi muncul di transisi area; tidak mengganggu flow.
- **Depends:** T7.1

### T7.3 — FTUE penuh (kurikulum + invisible tutorial) `M`
- **Output:** sempurnakan onboarding 1-30 (dok 12, GDD §8); value prop pulau 60 detik.
- **DoD:** uji 5 orang baru → kurikulum mulus, tak ada kebingungan.
- **Depends:** T4.5, T7.1

### T7.4 — Daily reward + login streak + comeback `M`
- **Output:** hadiah harian (hari 1-7), kotak waktu, comeback reward (churn 7+ hari).
- **DoD:** reward muncul sesuai waktu device; persist; unit test logika streak/comeback.
- **Depends:** T6.1

### T7.5 — Dynamic Difficulty Adjustment (DDA) runtime `M` (could; bisa defer ke v1.x)
- **Tujuan:** jaga flow state (dok 05 §8).
- **Output:** kalau pemain kalah ≥3x di satu level → bantuan halus (+1-2 langkah / papan awal sedikit murah hati); menang beruntun → sedikit lebih ketat. Halus & tak terlihat.
- **DoD:** terdeteksi & bantuan diterapkan; tidak terasa "dikasihani" terang-terangan. **Boleh ditunda ke v1.x kalau waktu mepet** (dok 11 D18).
- **Depends:** T6.2, T4.2

> **GATE FASE 7:** ada "alasan balik" (koleksi+daily), FTUE mulus saat diuji orang baru.

---

## FASE 8 — Monetisasi + Polish + Soft Launch
**Tujuan:** siap rilis terbatas, ukur retensi nyata.
**Acuan:** dok 06 (monetisasi), dok 09 (plugin/build), dok 10 (publishing/ASO).

### T8.1 — Verifikasi plugin AdMob/IAP/analytics (Godot 4.6) `S`
- **Output:** tes plugin di device fisik SEBELUM integrasi penuh (cegah delay rilis).
- **DoD:** plugin jalan di HP; kalau tidak kompatibel → rencana cadangan.
- **Depends:** T0.6
- **Catatan:** mulai paralel lebih awal kalau bisa (risiko R7).

### T8.2 — `AdsService` (rewarded dulu) `M`
- **Output:** `services/ads_service.gd` (interface + impl AdMob) — rewarded (+nyawa, +langkah, double reward). Interstitial DITAHAN sampai data session length aman.
- **DoD:** rewarded jalan; reward diberikan adil; interface bisa di-stub untuk test.
- **Depends:** T8.1, T6.2

### T8.3 — Interstitial (frequency cap) `S`
- **Output:** interstitial antar-level, cap (1/2-3 menit atau tiap 3 level), JANGAN setelah kalah pertama.
- **DoD:** cap dihormati; tidak muncul di momen sensitif.
- **Depends:** T8.2

### T8.4 — IAP "Remove Ads" `M`
- **Output:** `services/iap_service.gd` — non-consumable remove ads; restore purchase.
- **DoD:** beli → interstitial/banner hilang; restore jalan; test sandbox.
- **Depends:** T8.1

### T8.5 — Analytics produksi (GameAnalytics) `M`
- **Output:** integrasi GameAnalytics (D17); event dok 09 §7 + performance + comeback.
- **DoD:** event terkirim; dashboard retensi tampil.
- **Depends:** T3.4

### T8.6 — Settings + lokalisasi EN/ID `M`
- **Output:** `ui/` settings (suara/musik/haptic/bahasa); `i18n/` string EN+ID (default EN).
- **DoD:** ganti bahasa jalan; semua string ter-ekstrak (no hardcode).
- **Depends:** T6.5

### T8.7 — Polish menyeluruh `L`
- **Output:** juice final, transisi mulus, balancing 1-30, bitmap font, atlas final (1024/split), audio mixing.
- **DoD:** game terasa "premium"; FPS stabil di low-end.
- **Depends:** Fase 7

### T8.8 — Build rilis (AAB) + keystore `M`
- **Output:** JDK17 + Android SDK + export templates; keystore (backup ≥2 tempat); AAB.
- **DoD:** AAB ter-build via CI; arm64-v8a; size <60MB target.
- **Depends:** T0.6, T8.7

### T8.9 — Store listing + ASO `M`
- **Output:** ikon (3 varian A/B), feature graphic, screenshot (jual koleksi Lumi), video, copy EN/ID, privacy policy URL, Data Safety form, content rating.
- **DoD:** listing siap; aset kepatuhan lengkap (dok 10 §8).
- **Depends:** T8.7

### T8.10 — Closed test (12 tester × 14 hari) `L`
- **Output:** rilis closed testing track; kumpulkan feedback+data.
- **DoD:** 12 tester opt-in, 14 hari berjalan, lulus syarat akun.
- **Depends:** T8.8, T8.9

### T8.11 — Soft launch (Filipina/Vietnam) `L`
- **Output:** rilis terbatas pasar kecil; kumpulkan retensi 4-12 minggu.
- **DoD:** data D1/D7 terkumpul; iterasi berdasar data.
- **Depends:** T8.10

> **GATE FASE 8:** game utuh ter-monetisasi, lulus closed test, data soft launch terkumpul.

---

## FASE 9 — Rilis Global & Iterasi
**Tujuan:** live & belajar dari data.
**Acuan:** dok 02 §6 (metric gate), dok 10.

### T9.1 — Evaluasi metric gate `S`
- **DoD:** D1≥40%, D7≥15%, session≥15mnt, ad-watch≥30%, IAP≥1%. **Tidak tercapai → iterasi/pivot, JANGAN global launch.**
- **Depends:** T8.11

### T9.2 — Staged rollout global `M`
- **Output:** Indonesia → SEA → global, 10%→50%→100%.
- **DoD:** crash-free ≥99%; rollout dinaikkan bertahap.
- **Depends:** T9.1

### T9.3 — Iterasi data-driven `XL` (ongoing)
- **Output:** perbaiki titik churn, kalibrasi solver vs fail-rate nyata, tambah level dari generator, ASO A/B.
- **DoD:** loop iterasi berjalan; metrik membaik.
- **Depends:** T9.2

### T9.4 — LiveOps ringan (jika retensi bagus) `L`
- **Output:** daily challenge, event lokal, season pass offline.
- **DoD:** event berjalan tanpa server (berbasis waktu device).
- **Depends:** T9.3

> **GATE FASE 9:** game live global, metrik terpantau, loop iterasi jalan.

---

## Ringkasan Dependensi Kritis (jalur utama)
```
T0 (setup) → T1.1→T1.2→T1.3→T1.4→T1.7 (jantung) → T1.11 (view) → T1.13 (loop)
          → Fase 2 (special+juice) → ⛔ Fase 3 GATE (fun) 
          → Fase 4 (data+FTUE) → Fase 5 (generator) 
          → Fase 6 (save+ekonomi) → Fase 7 (koleksi) 
          → Fase 8 (monetisasi+soft launch) → ⛔ metric gate → Fase 9 (global)
```

## Prinsip Eksekusi (rangkuman)
1. **Logika + test dulu, baru view.** Core (T1.1-T1.10) sebelum BoardView.
2. **Gate adalah rem nyata** — Fase 3 (fun) & Fase 8 (metric) bisa menghentikan/mengubah arah.
3. **Commit per task** (saat diminta), branch untuk fitur besar.
4. **Test di HP low-end sejak Fase 1**, bukan nanti.
5. **Detail implementasi yang belum tercantum = D18** (dok 11) → address iteratif saat tahap terkait.
6. **Estimasi = kasar.** Yang penting urutan & DoD, bukan tanggal.

## Target Test Coverage (dari workflow dok 12)
- **WAJIB unit test:** `board`, `match_detector`, `special_items`, `objectives`, `gravity`, `rng`, `solver` (core logic murni). Ini fondasi yang harus terbukti benar sebelum dibungkus view.
- **Integration test:** solver memainkan level handcrafted = test core sehat; `test_determinism`.
- **Manual test:** view/animasi/juice (dok 12 §A gate) — ROI rendah untuk auto-test, kecuali screenshot regression opsional (deferred D18).
- **Service layer** (ads/iap/analytics): test saat implementasi (Fase 8), pakai stub interface.
- Tidak ada angka % coverage kaku — patokannya: **semua core logic punya test, tiap bug yang ditemukan → tambah test regresi.**
