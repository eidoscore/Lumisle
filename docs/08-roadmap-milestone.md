# 08 — Roadmap & Milestone

> Urutan eksekusi dari nol sampai rilis. Tiap tahap punya tujuan, deliverable, dan "definition of done".

---

## Prinsip Roadmap

1. **Buktikan fun sebelum bangun banyak.** Jangan bikin meta/ekonomi sebelum core terasa enak.
2. **Vertical slice dulu.** Satu level yang lengkap & dipoles > sepuluh fitur setengah jadi.
3. **Tiap tahap menghasilkan sesuatu yang bisa dijalankan/diuji.**
4. **Generator+solver datang setelah core stabil**, bukan di awal.

---

## Tahap 0 — Setup Proyek
**Tujuan:** fondasi teknis siap.
- [ ] Buat project Godot 4.6.3 + struktur folder (dok 04).
- [ ] Init git + .gitignore Godot.
- [ ] Setup GUT (unit test framework).
- [ ] Window/portrait config + resolusi referensi mobile.
- [ ] Stub singleton (GameState, SaveManager kosong).

**Done when:** project Godot terbuka, struktur folder ada, git jalan, satu test dummy lulus.

---

## Tahap 1 — Core Playable (Buktikan Fun)
**Tujuan:** match-3 bisa dimainkan. Arsitektur dari tech review.
- [ ] `Board` sebagai **`RefCounted`** (BUKAN Node), state **flat `Array[int]`** row-major.
- [ ] `match_detector.gd`: deteksi SEMUA match simultan (3/4/5/L/T) + unit test.
- [ ] `resolve_swap()` mengembalikan **TurnReport** (replay log cascade) — special chain via QUEUE, guard MAX_CASCADE, gravity per-kolom.
- [ ] `GameRNG` berseed (Fisher-Yates), no global random.
- [ ] **Test determinisme** (`test_determinism.gd`): seed sama → board sama; + **error handling** (validate board state + rollback).
- [ ] **Performance monitor (autoload)** dipasang sejak awal: track FPS, frame time, device model → ke analytics nanti.
- [ ] Deteksi no-move + reshuffle (dead-board) — masuk TurnReport sbg action RESHUFFLE.
- [ ] `board_view.gd` (Node2D): replay TurnReport via `await` per step; render board via **MultiMeshInstance2D**.
- [ ] 1 level hardcoded, bisa dimenangkan.
- [ ] **Test di 1 HP low-end fisik** (jangan tunggu nanti).

**Done when:** bisa main match-3 di editor + HP, swap/match/cascade jalan via TurnReport, unit test match_detector lulus. **Checkpoint fun pertama.**

---

## Tahap 2 — Special Items + Juice Dasar
**Tujuan:** game mulai "kerasa enak".
- [ ] Roket (match-4), Bom (L/T/2x2), Color Bomb (match-5).
- [ ] Combo dasar (minimal 2-3 kombinasi).
- [ ] Juice: partikel, suara, shake ringan, animasi ledakan.
- [ ] Unit test special items.

**Done when:** memicu special & combo terasa memuaskan. **Checkpoint fun kedua (krusial).**

---

## Tahap 3 — VERTICAL SLICE (GATE WAJIB — buktikan FUN sebelum bangun apa pun lagi)
**Tujuan:** buktikan 1 slice game terasa **lebih hidup** daripada template match-3 generik. Ini gate paling penting di seluruh roadmap (temuan KONVERGEN 3 review: validasi fun DULU, pabrik level BELAKANGAN).

- [ ] **3-5 level hand-crafted dengan JUICE PENUH** (bukan placeholder): animasi, SFX, partikel, screen shake, haptic — semuanya jadi.
- [ ] 2-3 special item terasa enak + minimal 1 combo "wow".
- [ ] 1 maskot sederhana + 1 layar meta "pulau" dengan ~3 state upgrade visual (placeholder art OK).
- [ ] **Analytics lokal / Debug HUD** (level_start/complete/fail, moves_left, dll) — dipasang DI SINI, bukan nanti.
- [ ] **Uji di 3 HP Android fisik (min. 1 low-end Rp1-2jt).** Cek FPS, panas, memori.
- [ ] **Fail-state design:** kalah harus terasa "hampir menang" & fair (bukan RNG curang).

**GATE — Done when (semua harus YA):**
- 3+ orang non-dev main 15-20 menit tanpa dijelaskan.
- Mereka paham tile tanpa instruksi.
- Kalah terasa fair, bukan curang.
- Mereka bilang (atau nunjukin) "satu level lagi".
- Jalan mulus di HP low-end.

> ⛔ **Kalau GATE gagal → STOP. Iterasi slice sampai fun, JANGAN lanjut.** Generator 10.000 level tidak akan menyelamatkan core yang hambar. (Konvergen di Qwen + GPT + DeepSeek.)

---

## Tahap 4 — Level jadi DATA + Konten Hand-Crafted
**Tujuan:** lepas dari level hardcoded + bangun fondasi konten manual.
- [ ] `LevelDefinition` resource + loader.
- [ ] `objectives.gd`: collect, clear-obstacle, move limit, menang/kalah.
- [ ] Rintangan dasar: Es, Box, Collectible (bring-down).
- [ ] HUD: langkah tersisa, objektif, progress.
- [ ] **Hand-craft 20-30 level pertama** sebagai FTUE/kurikulum (lihat GDD §8) — ini yang di-soft-launch, bukan generator.

**Done when:** bisa load level dari data, menang/kalah berfungsi, 3 rintangan jalan, 20-30 level FTUE terasa enak (di-playtest).

---

## Tahap 5 — Generator (Archetype-Based) + Ensemble Solver
**Tujuan:** produksi konten skala **sebagai drafting tool** — HANYA setelah slice & FTUE terbukti fun.
- [ ] `difficulty_model.gd` + `difficulty_curve.tres`.
- [ ] **Level ARCHETYPE (niat, bukan cuma bentuk):** "combo playground", "blocker clearing", "bottleneck", "objective race", "special tutorial", "hard near-miss". Generator menghasilkan archetype, bukan sekadar parameter acak.
- [ ] `level_generator.gd`: archetype + parameter + seed.
- [ ] **Ensemble solver (5 persona, bukan greedy tunggal):** random-valid, greedy-combo, greedy-obstacle, horizontal-scan (mata manusia), strategic-setup. + noise 10-20% (human error). Lihat dok 05 §5.
- [ ] **Win-rate PER-BAND** (bukan 30-65% global): early 85-95%, mid 65-80%, late 40-65%. Lihat dok 05 §5.4.
- [ ] **Metrik kualitas:** near-miss rate (menang di 2-3 langkah terakhir), filter "menang dgn >30% langkah sisa = terlalu mudah", variance, % stuck.
- [ ] Pipeline: generate → ensemble-solve → filter → **playtest/spot-check manual** → simpan.

**Done when:** generator menghasilkan kandidat yang lolos metrik + di-spot-check. Generator = draft, BUKAN auto-publish.

---

## Tahap 6 — Meta, Ekonomi & Save
**Tujuan:** progress & pacing.
- [ ] `SaveManager`: persist progress, koin, nyawa, settings.
- [ ] `Economy`: koin, nyawa + regen, booster dasar.
- [ ] `Progression`: unlock level berurutan, bintang.
- [ ] Peta level (navigasi).
- [ ] Popup pra-level & hasil (menang/kalah + tawaran +langkah).

**Done when:** progress tersimpan antar sesi, ekonomi nyawa/koin berfungsi, peta level jalan.

---

## Tahap 7 — Meta "Koleksi Lumi" + FTUE Lengkap (Anti-Bosen & Retensi D1)
**Tujuan:** alasan main jangka panjang + sesi pertama yang memikat.
- [ ] Meta scene: **koleksi Lumi** (album, kumpulkan pakai bintang, area menyala saat Lumi kembali) — lihat GDD §6.1.
- [ ] Minimal 3 area pulau dengan state redup→bercahaya.
- [ ] **FTUE sebagai KURIKULUM (bukan sekadar level mudah):** 1-3 swap dasar + auto-guided, 4-8 kenalkan 1 special per 2 level (beri situasi di mana special = satu-satunya cara menang), 9-15 combo, 15-30 obstacle pertama. Lihat GDD §8.
- [ ] Tutorial invisible (highlight tile, BUKAN popup) + value prop pulau dalam 60 detik.
- [ ] Cerita ringan / maskot pemandu (1-2 kalimat per area).
- [ ] Daily reward / login streak + **comeback reward** (pemain churn 7+ hari).

**Done when:** sesi pertama memikat (uji ke 5+ orang baru), kurikulum FTUE mulus, progress koleksi memuaskan.

---

## Tahap 8 — Monetisasi + Polish + Soft Launch
**Tujuan:** siap rilis terbatas & ukur retensi nyata.
- [ ] Integrasi AdMob: **rewarded dulu** (+5 langkah, +nyawa) — interstitial **ditahan** sampai yakin session length & D1 tidak hancur.
- [ ] IAP "Remove Ads".
- [ ] Analytics produksi (Firebase + GameAnalytics) + crash reporting — sudah ada sejak slice, di sini dilengkapi.
- [ ] Settings (suara, haptic, bahasa EN/ID).
- [ ] Polish menyeluruh (juice, transisi, sound pooling, haptic — ROI utama).
- [ ] Audio: SFX pool-based + 3 music loop (menu/gameplay/meta), kurasi 1-2 sumber konsisten.
- [ ] ASO: ikon (3 varian A/B), screenshot yang jual meta pulau (bukan board polos), feature graphic, copy ID/EN.
- [ ] Setup Android export (JDK, SDK, keystore) → build AAB.
- [ ] Closed testing: 12 tester × 14 hari (syarat akun personal baru).
- [ ] **Soft launch di Filipina/Vietnam** (CPI murah) — kumpulkan data retensi 4-12 minggu.

**Done when:** game utuh, ter-monetisasi, lulus closed test, data soft launch terkumpul.

---

## Tahap 9 — Rilis Global & Iterasi
**Tujuan:** live & belajar dari data.
- [ ] **Metric gate sebelum global:** D1 ≥40%, D7 ≥15%, session ≥15 mnt, ad-watch ≥30%, IAP ≥1%. Tidak tercapai → iterasi/pivot, JANGAN global launch.
- [ ] Rilis Indonesia → SEA/global (staged rollout 10%→50%→100%).
- [ ] Pantau D1/D7/D30, fail rate per level, drop-off, crash.
- [ ] Iterasi balancing dari data nyata (kalibrasi solver vs fail-rate asli).
- [ ] Tambah level dari generator berdasar data + ASO A/B test.
- [ ] (Jika retensi bagus) LiveOps ringan: daily challenge, event lokal, season pass offline.

**Done when:** game live global, metrik terpantau, loop iterasi berbasis data jalan.

---

## Timeline Target (REVISI v2 pasca-3-review — estimasi, bukan janji)

> 3 reviewer (Qwen/GPT/DeepSeek) konvergen: 4-5 bulan terlalu optimis; bagian "rasa" (juice/level design/playtest) tidak bisa dikompres AI. Estimasi jujur **~8 bulan** dengan ~5 jam/hari. Prinsip: **validasi fun dulu (slice), baru bangun mesin konten.**

| Bulan | Tahap | Fokus |
|---|---|---|
| 1 - 2 | Tahap 0-2 | Core match-3 + special items + juice |
| 2.5 - 3 | **Tahap 3 (VERTICAL SLICE GATE)** | 3-5 level full-juice + test orang nyata. **STOP kalau gagal.** |
| 3.5 - 4.5 | Tahap 4 | Level data + 20-30 level FTUE hand-crafted |
| 5 - 6 | Tahap 5 | Generator archetype + ensemble solver (HANYA jika slice lolos) |
| 6 - 7 | Tahap 6-7 | Meta koleksi + ekonomi + save + FTUE kurikulum |
| 7 - 8 | Tahap 8 | Monetisasi + polish + ASO + closed test + soft launch |
| 8+ | Tahap 9 | Iterasi data → rilis global (gated by metrik) |

Faktor pelambat: kurasi aset/audio, tuning "rasa", spot-check level, setup Android build, closed test 14 hari, soft launch 4-12 minggu.

> **Pemotongan scope bila mepet (urut prioritas potong):** generator → tunda, cukup hand-craft 20-30 dulu; DDA runtime → static curve; Color Bomb & combo lanjutan → v2; subset warna 5/6 → mulai 4 warna; narasi → 1-2 kalimat/area; area meta → 3 dulu. Prinsip: **"3 level yang bikin senyum > 1000 level hambar."**

---

## Aksi yang Dimulai SEKARANG (paralel, jangan tunggu)
- [ ] **Daftar Google Play Developer account ($25) SEKARANG** — verifikasi identitas Indonesia (Sep 2026) butuh lead time (KTP/dok, proses 2-4 minggu). Jangan tunggu game jadi.
- [ ] Siapkan/pinjam **2-3 HP Android low-end** untuk testing rutin.
- [ ] Kumpulkan **12+ calon tester** untuk closed test nanti.

---

## Checkpoint Keputusan (Gate)

- **Setelah Tahap 2:** Core terasa enak? Kalau tidak → iterasi, jangan lanjut.
- **⛔ Setelah Tahap 3 (VERTICAL SLICE — GATE TERPENTING):** 3+ orang non-dev bilang "satu level lagi"? Tile kebaca tanpa dijelaskan? Kalah terasa fair? Mulus di low-end? Kalau TIDAK → STOP & iterasi slice. JANGAN bangun generator/meta di atas core hambar.
- **Setelah Tahap 5:** Distribusi win-rate per-band masuk akal? Near-miss rate sehat? Kalau kacau → perbaiki solver/model.
- **Setelah Tahap 7:** Internal playtest — ada "alasan balik"? FTUE mulus?
- **Setelah Tahap 8 (soft launch):** Metric gate (D1≥40%, D7≥15%) tercapai? Kalau tidak → iterasi/pivot, JANGAN global launch.
