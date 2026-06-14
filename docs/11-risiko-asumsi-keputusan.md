# 11 — Risiko, Asumsi & Keputusan Terbuka

> Tempat ngumpulin semua hal yang belum pasti + risiko + keputusan yang NUNGGU lu (game director).
> Selesaikan keputusan di bagian 3 sebelum tahap terkait dimulai.

---

## 1. Risiko Utama & Mitigasi

| # | Risiko | Dampak | Kemungkinan | Mitigasi |
|---|---|---|---|---|
| R1 | **Pasar match-3 sangat padat** — susah ditemukan & menang | Tinggi | Tinggi | Diferensiasi via **meta koleksi "Lumi"** + polish; ASO kuat; soft launch pasar kecil; pasar awal SEA; target "mendekati", bukan menyaingi raksasa |
| R2 | **Art & game feel jadi bottleneck** (bukan kode) — **risiko #1 menurut review** | Tinggi | Tinggi | CC0 fondasi + prosedural aksen; ROI ke juice/sound/haptic; JANGAN habiskan bulan-bulan di shader; rencana aset sejak awal (dok 07) |
| R3 | **Kualitas level generated < desainer ahli** ("solvable ≠ fun") | Tinggi | Tinggi | Generator = draft tool; handcraft ~100; metrik kualitas (bukan cuma winrate); playtest manual setiap level ship-able; kalibrasi data nyata |
| R4 | **Scope melebar (over-scope)** — proyek tak selesai | Tinggi | Tinggi | Patuhi Non-Goals (dok 01); gate keputusan tiap tahap; MVP dulu |
| R5 | **Retensi rendah** setelah rilis | Tinggi | Sedang | Fokus fun & anti-frustrasi; analytics dari awal; iterasi data-driven |
| R6 | **Solo dev burnout / waktu terbatas** | Tinggi | Sedang | Milestone kecil & terukur; AI handle beban kode; rayakan checkpoint |
| R7 | **Kompatibilitas plugin Android (Ads/IAP) dgn Godot 4.6** | Sedang | Sedang | Verifikasi plugin lebih awal (jelang Tahap 8); punya rencana cadangan mediation |
| R8 | **Kebijakan Play berubah** (verifikasi, chargeback, API) | Sedang | Sedang | Pantau; daftar akun & verifikasi lebih awal; ikuti checklist dok 10 |
| R9 | **Monetisasi mengganggu UX** → uninstall | Sedang | Sedang | Iklan opt-in (rewarded); frequency cap; jangan iklan setelah kalah |
| R10 | **Performa di Android low-end** + **floor device ES 3.0** | Sedang | Sedang | Compatibility renderer (butuh ES 3.0 → Mali-400/ES2.0 di luar target); object pooling; uji di HP ES 3.0 murah sejak T0.9 |
| R11 | **Lisensi aset bermasalah** (terutama AI/gratis) | Sedang | Rendah | Audit lisensi (`ASSETS_LICENSES.md`); utamakan CC0; cek izin komersial |
| R12 | **Kehilangan keystore** → tak bisa update app | Tinggi | Rendah | Backup keystore di banyak tempat aman sejak dibuat |
| R13 | **Retensi jangka panjang lemah** (tak ada LiveOps/event/social) | Tinggi | Sedang | Daily reward + comeback + koleksi Lumi (v1); LiveOps ringan & event lokal (v1.x); ukur D30 |
| R14 | **FTUE membingungkan** (6 warna + special + combo tanpa diajari) | Tinggi | Sedang | FTUE sebagai kurikulum eksplisit (GDD §8); tutorial invisible; uji ke 5+ orang baru |
| R15 | **Bangun mesin konten sebelum fun terbukti** (urutan risiko terbalik) | Tinggi | Sedang→teratasi | Vertical Slice GATE (Tahap 3) wajib lolos sebelum generator |
| R16 | **Solver pipeline lambat** (GDScript interpreted, ribuan level × ratusan run) | Sedang | Sedang | Batch kecil saat tuning, batch penuh semalaman; multi-process; core portable → port GDExtension HANYA jika kebukti perlu (dok 05 §6.1) |
| R17 | **Logic layer "bocor" ke scene tree** (Godot menggoda nambah Node ref demi convenience) | Sedang | Sedang | Disiplin: core = RefCounted murni; unit test headless membuktikan tak ada dependensi Node |

---

## 2. Asumsi (perlu dikonfirmasi)

| # | Asumsi | Jika salah... |
|---|---|---|
| A1 | Lu siap berperan sebagai game director (ambil keputusan desain, kurasi art, playtest) | Proyek melambat; perlu sesuaikan ekspektasi |
| A1b | **Lu bisa coding (paham logika/algoritma) tapi belum kenal Godot/GDScript** — bisa review & verifikasi logika AI, perlu belajar sintaks GDScript (~1-2 minggu, mirip Python) | Risiko "tak bisa verifikasi AI" turun signifikan; kualitas lebih terjaga |
| A2 | Lu bisa sediakan/setujui aset art & audio (gratis/AI/komisi) | Art jadi blocker; perlu budget/waktu |
| A3 | Target "mendekati Royal Match", bukan 1:1 | Scope tak realistis; revisi tujuan |
| A4 | Monetisasi iklan-first dapat diterima | Revisi model ke IAP-first/premium |
| A5 | Anggaran tersedia untuk: akun Play ($25), kemungkinan aset & sedikit UA tes | Sesuaikan rencana GTM |
| A6 | Perangkat Android tersedia untuk testing | Perlu beli/pinjam perangkat uji |
| A7 | Waktu development realistis (proyek bulan-an, bukan minggu) | Sesuaikan timeline |

---

## 3. KEPUTUSAN TERBUKA (butuh input lu) ⚠️

> Ini yang gw butuh dari lu. Beberapa bisa diputuskan sekarang, sebagian bisa nanti saat tahap terkait. Tandai saat sudah diputuskan.

### D1 — Tema & Setting (paling penting) ✅ DIPUTUSKAN (REVISI pasca-review)
Menentukan art, meta, diferensiasi.
- **Jawaban user:** tema pulau fiksi imajinatif; art prosedural; KLARIFIKASI: kalau ada aset gratis yang boleh diotak-atik, lebih disukai.
- **KEPUTUSAN FINAL (revisi setelah review Qwen):** Tema **pulau fiksi imajinatif** dikunci. Strategi art DIBALIK:
  - **Aset CC0 = FONDASI** (terutama **tile gameplay** & UI) — demi keterbacaan 0.5 detik & performa Android low-end.
  - **Prosedural = AKSEN saja** (background, glow "redup→bercahaya", partikel) — bukan lagi identitas utama.
  - **Alasan revisi:** pemain casual tak peduli cara art dibuat (peduli clarity/feel/juice); prosedural di tile berisiko dingin + berat di low-end SEA; ROI shader < CC0 + juice. Detail dok 07 §2.0.
  - ROI effort dialihkan ke: color grading konsisten, particle generous, screen-shake+haptic timing, sound design.

### D2 — Twist/Diferensiasi ✅ DIPUTUSKAN (REVISI pasca-review)
Apa 1 hal yang bikin game ini beda dari match-3 lain?
- **Jawaban user:** ikut rekomendasi.
- **KEPUTUSAN FINAL (revisi setelah review Qwen):** Diferensiator utama = **meta KOLEKSI "Roh Cahaya / Lumi" + tema pulau** (lihat GDD §6.1), DIDUKUNG polish/game-feel.
  - Bukan lagi "art prosedural" (review: bukan hook yang menjual untuk casual).
  - Bukan "dekorasi pulau" (sudah jenuh: Gardenscapes/Matchington). **Koleksi** memberi hook "gotta catch 'em all" + album + cocok untuk daily/event.
  - Elevator pitch: *"match-3 santai di mana kamu mengumpulkan roh cahaya untuk menghidupkan kembali pulau yang meredup."*
  - **1 signature mechanic (DITUNDA, maks 1):** kandidat *color-mixing* — hanya setelah core fun terbukti.
  - Catatan: pivot ke merge-2 (saran review) DITOLAK — merge lebih kompleks dibangun untuk solo dev (tier item, energy, order, ekonomi). Match-3 core lebih "solved" & aman.

### D3 — Mekanik Inti Match-3 ✅ DIPUTUSKAN
Match-3 swap klasik (seperti Royal Match) atau varian (block-blast/tap-to-clear, dll)?
- **Default disarankan:** match-3 swap klasik (paling banyak referensi & solver-friendly).
- **KEPUTUSAN FINAL:** Match-3 **swap klasik** (core seperti Royal Match), TIDAK 1:1. Diferensiasi lewat tema pulau + art prosedural (D1/D2), bukan lewat mengubah mekanik inti. Konsisten & solver-friendly.

### D4 — Sistem Nyawa ✅ DIPUTUSKAN
Nyawa klasik (5, regen), versi longgar, atau tanpa nyawa? (dok 06 §3)
- **Pertimbangan:** nyawa = pacing + monetisasi, tapi bisa terasa menghukum.
- **KEPUTUSAN FINAL:** Nyawa klasik. Maks **5 nyawa**, regen **1 nyawa / 25 menit**, bisa **+nyawa via rewarded ad**. Cap: maksimal **5 nyawa/hari** yang bisa didapat dari iklan (anti-abuse). Ini standar industri (mirip Candy Crush ~30 mnt). Sehat untuk pacing + monetisasi lembut.

### D5 — Jumlah Warna Tile ✅ DIPUTUSKAN (dengan klarifikasi user)
4, 5, atau 6 warna dasar? (lebih sedikit = lebih mudah/santai)
- **Default disarankan:** mulai 5, atur per level via difficulty.
- **Jawaban user awal:** 6 warna dasar, tile jangan norak, referensi simpel seperti Royal Match.
- **KLARIFIKASI user:** maksudnya bukan ke-6 warna selalu muncul bareng. **Pool 6 warna**, tapi tiap level hanya memunculkan SUBSET secara acak (mis. 1 level cuma 4 warna kombinasi). Jadi tidak selalu 6 sekaligus.
- **KEPUTUSAN FINAL (sejalan dengan klarifikasi):**
  - **Pool total = 6 warna** (aset/identitas disiapkan untuk 6).
  - **Warna AKTIF per level = subset** yang dipilih (acak berseed + dipandu difficulty): level awal/santai = 4 warna, level menengah = 5, level susah = 6.
  - Subset dipilih saat generate level & disimpan di `LevelDefinition` (deterministik, bukan acak saat runtime — agar level konsisten & solver bisa memvalidasi).
  - **Aksesibilitas wajib:** tiap warna punya BENTUK/IKON berbeda.
  - **Palet "tidak norak":** harmonis (hue jelas beda, saturasi terkendali, glow lembut). Palet referensi disiapkan saat tahap art.

### D6 — Nama Game & Branding ✅ DIPUTUSKAN — **LUMISLE**
- **Nama final: Lumisle** (lumen + isle = "pulau cahaya"). Sesuai tema pulau imajinatif + motif redup→bercahaya + estetika gem/glow.
- **HASIL CEK (aman):**
  - Tidak ada game/app bernama "Lumisle" di Google Play (kategori games bersih).
  - Hanya ada: kursi furniture "Lumisle" (kategori beda → risiko trademark rendah) & situs wellness "Luminisle" (ejaan beda). Tidak ada konflik di ranah game.
- **Catatan:** sebelum rilis, sebaiknya cek pendaftaran trademark resmi di wilayah target (mis. DJKI Indonesia) bila ingin perlindungan merek; untuk mulai development, nama AMAN dipakai.
- **Riwayat:** "Pelago" ditolak (bentrok "Puzzle Pelago" puzzle+pulau).
- **Package ID rencana:** `com.<studio>.lumisle` (nama studio menyusul).

### D7 — Strategi Art ✅ DIPUTUSKAN (selaras revisi D1)
Aset gratis / AI-generated / komisi / bikin sendiri? Ada budget?
- **Jawaban user:** aset gratis free-to-use commercial / open source, TIDAK ada budget.
- **KEPUTUSAN FINAL (sinkron dengan D1 pasca-review):** Strategi 2 lapis:
  1. **Aset CC0 = FONDASI:** tile gameplay (wajib terbaca), special, UI, meta/Lumi, audio. Sumber: **OpenGameArt.org** ("Rotating Gems for Match3", "Match 3 GUI"), **Kenney.nl** (CC0 konsisten), **Ponywolf match-three** (itch.io), audio **Kenney + Freesound (CC0)**.
  2. **Prosedural = AKSEN (bukan fondasi):** background, glow "redup→bercahaya", partikel — pakai **pre-rendered noise texture / sprite-sheet** (BUKAN shader procedural berat; lihat dok 04 §13).
  - **Wajib:** `ASSETS_LICENSES.md` (utamakan CC0; CC-BY butuh atribusi).
  - **Catatan jujur:** aset gratis berisiko terlihat generik → **konsistensi palet (recolor 1 pack) + polish/juice + identitas glow** yang menyelamatkan, BUKAN art prosedural sebagai jualan.

### D8 — Model Monetisasi Final ✅ DIPUTUSKAN
Hybrid iklan-first (disarankan) atau lain?
- **KEPUTUSAN FINAL:** **Hybrid iklan-first.** Rewarded (prioritas) + interstitial (frequency cap) + IAP "Remove Ads". Sesuai dok 06.

### D9 — Pasar & Bahasa Awal ✅ DIPUTUSKAN
ID + EN dulu? Tambah bahasa lain?
- **KEPUTUSAN FINAL:** **ID + EN**, default **EN**. Tidak ada rencana bahasa lain (cukup ini ke depan). Pasar awal Indonesia/SEA.

### D10 — Target Timeline & Komitmen ✅ DIPUTUSKAN
Berapa jam/minggu realistis lu bisa curahkan? (mempengaruhi estimasi)
- **Jawaban user:** ~5 jam/hari.
- **ANALISIS:** Ini komitmen besar (~35 jam/minggu, mendekati full-time). Timeline ~8 bulan (dok 08, revisi pasca-review) realistis. **Warning:** jaga ritme & hindari burnout (risiko R6). Rayakan checkpoint tiap tahap.

---

## 3b. KEPUTUSAN TERTUNDA (gap dari deep-dive — tidak memblok start coding, tapi harus di radar)

### D11 — Skill coding & belajar Godot ✅ TERJAWAB
- **Jawaban user:** bisa coding, belum kenal Godot.
- **KEPUTUSAN:** Dev review & verifikasi logika AI; belajar GDScript sambil jalan (~1-2 minggu). Workflow di dok 12 §B. Definition-of-done per modul wajib (kode + test + Dev paham + setujui).

### D12 — Backup & Disaster Recovery ⬜ (urus jelang/awal coding)
- Source code → **GitHub/GitLab privat** (jangan cuma lokal). Commit rutin.
- Save format → atomic write + backup file (anti-corrupt) — sudah di dok 04 §7.
- Keystore (nanti Tahap 8) → backup di ≥2 tempat aman. Kehilangan = tak bisa update app selamanya.
- **Aksi:** buat repo privat di Tahap 0.

### D13 — Legal Entity & Pajak ⬜ (belum urgent, radar)
- "Publisher" + revenue iklan/IAP = penghasilan kena pajak.
- Akun Play: Personal cukup untuk mulai. Pertimbangkan badan usaha bila revenue signifikan.
- Indonesia: NPWP, pajak penghasilan dari pembayaran Google (Google bisa potong withholding tertentu). Konsultasi saat mulai ada revenue.
- **Aksi:** tidak menghambat development; tinjau sebelum monetisasi aktif (Tahap 8).

### D14 — Audio Identity ⬜ (putuskan jelang Tahap 2/8)
- Audio = ~50% game feel (dok 07) tapi arah masih tipis.
- Perlu: mood musik (cozy/relaxing/island ambient?), gaya SFX (organik vs digital "glow"?), 1-2 sumber konsisten (hindari campur 5 sumber).
- **Aksi:** kurasi pack audio CC0 konsisten sebelum polish; tentukan mood saat slice.

### D15 — Competitive Teardown ⬜ (riset murah, lakukan jelang Tahap 1)
- Belum pernah main & bedah langsung kompetitor di ceruk "casual island/match-3".
- **Aksi:** mainkan 3-5 game (Royal Match, Gardenscapes, 1-2 match-3 island kecil), catat: FTUE mereka, kapan special diajarkan, fail-state feel, juice, monetisasi placement. Murah, berharga, sebelum ngoding.

### D16 — Reshuffle: gratis atau makan langkah? ⬜ (putuskan SEBELUM coding core)
- Dead-board (tak ada swap valid) → auto-reshuffle. Tapi: reshuffle **gratis** atau **−1 langkah**?
- **Default disarankan: GRATIS** (anti-frustrasi; bukan salah pemain board mentok).
- **KRITIS:** solver WAJIB memodelkan keputusan ini identik dengan game, kalau tidak win-rate prediksi meleset. Masuk TurnReport sebagai action `RESHUFFLE`. Lihat dok 04 §3.9.
- **Keputusan final:** _________________ (default GRATIS bila tak ditentukan)

### D17 — Stack Analytics ⬜ (putuskan jelang Tahap 8)
- Opsi A (disarankan): **GameAnalytics** (gratis, dashboard D1/D7/retensi langsung jadi — persis kebutuhan metric gate).
- Opsi B: **Firebase** (lebih kaya tapi SDK native lebih berat untuk solo dev).
- Opsi C (minimal): thin HTTP POST JSON ke endpoint sendiri (kontrol penuh, tapi bikin dashboard sendiri).
- **Catatan:** struktur event sudah dipikir sejak Tahap 3 (dok 09 §7); pilihan vendor bisa belakangan. Hindari retrofit.

### D18 — Detail Implementasi yang Di-address SAAT Coding (deferred, iteratif)
> Meta-review (Qwen ronde 2) menilai dokumen "90% matang"; sisa 10% = detail yang wajar muncul saat coding. Item berikut **TIDAK perlu di-plan upfront** — diselesaikan saat tahap terkait, dicatat di sini agar tidak hilang dari radar:
- **Sudah ditangani di doc:** error handling+rollback (dok 04 §3.10), determinism test (§3.8), quality metrics formula + definisi "stuck" objective-focused (dok 05 §5.4), special creation rules (GDD §3.4), performance monitor (roadmap Tahap 1), adaptive run count berbasis CI (dok 05 §5.3).
- **Deferred ke tahap terkait:** core_logic_version pada level (cek saat load), screenshot/visual regression test (Tahap 3), board init "no initial match" (Tahap 1, detail saat coding), swap validation efficiency, hint system (best vs random valid), obstacle interaction order multi-layer (Tahap 4 saat rintangan dibangun), accessibility tool buta warna (Tahap 7), localization workflow (Tahap 7), thermal detection (Tahap 8), data migration & hotfix/force-update (Tahap 8/pasca-rilis), crash reporting debug workflow (Tahap 8), analytics offline queue+retry (Tahap 8).
- **Prinsip:** address iteratively; jangan over-document sebelum coding.

---

## 4. Pertanyaan Strategis (untuk dipikirkan)

1. **Apakah lu OK kalau game pertama "gagal" secara komersial?** Game pertama paling realistis sebagai investasi belajar + fondasi reusable. Mindset ini sehat untuk jangka panjang.
2. **Seberapa penting orisinalitas vs kecepatan?** Klon-dengan-identitas lebih cepat & lebih aman; orisinalitas penuh lebih lambat & berisiko tapi lebih bernilai jangka panjang.
3. **Apakah lu mau bangun 1 game besar atau beberapa game kecil?** Strategi indie modern sering "banyak taruhan kecil". Engine modular kita mendukung ini.

---

## 5. Log Keputusan (diisi seiring waktu)

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-05-31 | Engine: Godot 4.6.3 | Gratis, portable, cocok 2D, sudah terpasang |
| 2026-05-31 | Genre: match-3 hybrid-casual | Market besar, core "solved", cocok solo+AI |
| 2026-05-31 | Skala konten: generator + solver | Satu-satunya cara realistis capai ribuan level solo |
| 2026-05-31 | Tema: pulau fiksi imajinatif | Pilihan user; ruang meta luas; identitas unik |
| 2026-05-31 | Art: pragmatis — aset CC0 (boleh modif) + prosedural | No budget; utamakan gratis, lengkapi prosedural utk identitas |
| 2026-05-31 | Diferensiator utama: art generative + tema pulau | Fokus 1 hal, bukan semua sekaligus (D2 approved) |
| 2026-05-31 | Mekanik: match-3 swap klasik (bukan 1:1 Royal Match) | Solver-friendly; beda di tema/art |
| 2026-05-31 | Warna: pool 6, subset acak-berseed per level (4/5/6) | Tiap level tampil sebagian; jaga rasa santai; aksesibilitas bentuk |
| 2026-05-31 | Nyawa: 5 maks, regen 25mnt, +iklan (cap 5/hari) | Standar industri; pacing + monetisasi lembut |
| 2026-05-31 | Monetisasi: hybrid iklan-first | Mayoritas pemain non-bayar (SEA) |
| 2026-05-31 | Bahasa: ID + EN (default EN) | Pasar awal ID/SEA |
| 2026-05-31 | Komitmen: ~5 jam/hari | Timeline 4-5 bulan realistis |
| 2026-05-31 | Nama "Pelago" DITOLAK | Bentrok "Puzzle Pelago" (puzzle+pulau) di Play/Steam |
| 2026-05-31 | **Nama final: LUMISLE** | Cek Play Store bersih (no game konflik); brandable; sesuai tema |
| 2026-05-31 | **[REVIEW] Art: CC0 fondasi (tile/UI) + prosedural AKSEN** | Review: clarity/feel > cara art dibuat; low-end SEA; ROI |
| 2026-05-31 | **[REVIEW] Diferensiator: meta KOLEKSI "Lumi"** (bukan dekorasi/art prosedural) | Dekorasi jenuh; koleksi = hook + album + daily |
| 2026-05-31 | **[REVIEW] Generator: template-based + metrik kualitas** (variance/stuck/special), greedy 100-500 run, no MCTS | "Solvable ≠ fun"; generator = draft tool |
| 2026-05-31 | **[REVIEW] Hand-craft ~100 level** (bukan 50) + spot-check generated | 50 ≈ 2 jam; perlu untuk D7 |
| 2026-05-31 | **[REVIEW] Tambah fase FTUE eksplisit** (tutorial invisible, guaranteed win, 60 dtk hook) | FTUE = penentu retensi D1 |
| 2026-05-31 | **[REVIEW] Tambah comeback mechanic** (churn 7+ hari) | Retensi |
| 2026-05-31 | **[REVIEW] Soft launch Filipina/Vietnam dulu** | CPI murah; uji retensi sebelum pasar utama |
| 2026-05-31 | **[REVIEW] Timeline 5-7 bulan** (bukan 4-5) | Estimasi jujur untuk kualitas matang |
| 2026-05-31 | **[REVIEW] Pivot ke merge-2 DITOLAK** | Merge lebih kompleks dibangun untuk solo dev |
| 2026-05-31 | **[3-REVIEW] Vertical Slice jadi GATE sebelum generator** | Konvergen Qwen+GPT+DeepSeek: validasi fun dulu |
| 2026-05-31 | **[3-REVIEW] Win-rate PER-BAND** (early 85-95%, late 45-70%), bukan 30-65% global | 30% di early = uninstall massal |
| 2026-05-31 | **[3-REVIEW] Ensemble solver 5 persona + noise + near-miss** | Greedy tunggal tak korelasi dgn manusia |
| 2026-05-31 | **[3-REVIEW] Generator = ARCHETYPE (niat), dibangun setelah slice** | "Solvable ≠ fun"; generator = drafting tool |
| 2026-05-31 | **[3-REVIEW] Tile = 1 pack CC0 konsisten (recolor), prosedural BACKGROUND saja** | Hindari "frankenstein visual"; readability |
| 2026-05-31 | **[3-REVIEW] FTUE = kurikulum eksplisit** (ajarkan tiap special/obstacle) | Kurva belajar curam = churn |
| 2026-05-31 | **[3-REVIEW] Timeline ~8 bulan** (bukan 4-5) + target retensi D1≥40%/D7≥15% | Bagian "rasa" tak bisa dikompres AI |
| 2026-05-31 | **[3-REVIEW] Daftar akun Play SEKARANG + test HP low-end dari awal** | Verifikasi ID butuh lead time; GL Compatibility risiko low-end |
| 2026-05-31 | **[KEPUTUSAN USER] Tetap match-3, tetap tema pulau** (bukan pivot/Nusantara) | Passion user; AI nutup kelemahan teknis match-3 |
| 2026-05-31 | **[USER] Dev bisa coding, belum Godot** → workflow review-per-modul (dok 12) | Verifikasi logika AI; risiko kualitas turun |
| 2026-05-31 | **[DEEP-DIVE] Tambah dok 12 (Definition of Fun terukur + workflow AI)** | Gate "fun" tadinya subjektif |
| 2026-05-31 | **[DEEP-DIVE] Sync inkonsistensi dok 04/06/09/10** (skema level, nyawa, nomor tahap, renderer) | Sisa revisi yang ketinggalan |
| 2026-05-31 | **[DEEP-DIVE] Catat D12-D15** (backup, legal/pajak, audio identity, competitive teardown) | Gap yang belum dibahas, kini di radar |
| 2026-05-31 | **[TECH-REVIEW] Board = flat Array[int], logic = RefCounted (bukan Node)** | Cache locality, serialisasi, deterministik, testable |
| 2026-05-31 | **[TECH-REVIEW] TurnReport replay pattern** (ganti cascade berbasis signal) | Animasi cascade sinkron + mudah di-test/debug |
| 2026-05-31 | **[TECH-REVIEW] Determinisme: Array (bukan dict) untuk state, RNG berseed, int-only state, no signal di core** | Reproducibility solver & test |
| 2026-05-31 | **[TECH-REVIEW] Solver TETAP GDScript v1** (multi-process, BUKAN port C++/Rust) | Hindari dual-implementation; core portable utk port nanti jika perlu |
| 2026-05-31 | **[TECH-REVIEW] Background = pre-rendered sprite-sheet, BUKAN shader noise** | Shader noise berisiko di Mali-400 |
| 2026-05-31 | **[TECH-REVIEW] Atomic save + backup + checksum; .tres handcraft / JSON generated; particle+audio pooling** | Anti-corrupt; scalable; stabil low-end |
| 2026-05-31 | **[TECH-REVIEW-2/DeepSeek] MultiMeshInstance2D (1 draw call) + bit-encoding int32 + bitmap font** | Performa low-end konkret (30→60 FPS) |
| 2026-05-31 | **[TECH-REVIEW-2] PackedInt32Array (bukan Array biasa) + RNG di-inject (bukan autoload)** | Serialisasi cepat; banyak board simultan utk solver |
| 2026-05-31 | **[TECH-REVIEW-2] Adaptive ensemble + early-exit + chunked JSON levels** | Solver runtime −50-70%; load Android lebih cepat |
| 2026-05-31 | **[TECH-REVIEW-2] Schema: id string, generator_version, hand_crafted, obstacle layer** | Stabilitas data & rintangan bertumpuk |
| 2026-05-31 | **[TECH-REVIEW-2] CI build Android (GitHub Actions) dari awal** | Cegah panik export saat rilis |
| 2026-05-31 | **[TECH-REVIEW-2] D16 reshuffle (default GRATIS) + D17 analytics (GameAnalytics)** | Gap desain & vendor analytics |
| 2026-05-31 | **[TECH-REVIEW-3/Kimi] Background = pre-rendered noise TEXTURE (bukan shader procedural)** | Shader procedural bisa crash-to-desktop di Mali driver lama |
| 2026-05-31 | **[TECH-REVIEW-3] Atlas target 1024 (atau 2048 split); signal bawa data = kirim .duplicate()** | VRAM Mali-400; cegah view mutasi state core |
| 2026-05-31 | **[TECH-REVIEW-3] Urutan special eksplisit (ColorBomb>Combo>Bomb>Rocket); validasi path sebelum load** | Determinisme; crash Android tanpa stack trace |
| 2026-05-31 | **[TECH-REVIEW-3] Solver Python external DITOLAK** (sama spt C++); run count ~20-50 non-kritis | Hindari implementasi match-3  kedua yg divergen |
| 2026-05-31 | **[KONSENSUS 3 tech-review] Stop review teknis — diminishing returns, arsitektur matang** | Qwen+DeepSeek+Kimi konvergen di 3 isu yang sama (sudah teratasi) |
| 2026-05-31 | **[META-REVIEW] Tambah 4 immediate: error handling, metrics formula, determinism test, definisi "stuck"** | Murah, cegah rework; sisanya deferred (D18) |
| 2026-05-31 | **[META-REVIEW] Solver default single-process overnight (multi-process opsional); adaptive run via CI** | Multi-process makan RAM 4GB; cutoff naif = data noisy |
| 2026-05-31 | **[META-REVIEW] Konfirmasi: dokumen ~90% matang, keputusan solver TEPAT → MULAI CODING** | Sisa 10% = detail iteratif saat coding |
| 2026-05-31 | **[DOC-REVIEW] Fix inkonsistensi: dok05 §5.2 duplikat, obstacle Format A, D7 selaras D1, dok07 CPUParticles, dok04 skema→pointer ke dok05, README path, PRD FR-L03/L04/L09** | Sisa editan iteratif yang ketinggalan |
| 2026-05-31 | **[DOC-REVIEW] Gap arsitektural ditutup: Scene architecture+navigasi (dok04 §14), obstacle storage (array paralel), app lifecycle, MultiMesh limitation** | Critical gap — pengaruhi struktur kode hari 1 |
| 2026-05-31 | **[DOC-REVIEW] Task baru dok13: T0.8 scene arch, T0.9 android debug, T1.16 art pipeline, T6.7 lifecycle, T7.5 DDA + score system + test coverage** | Gap implementation plan |
| 2026-05-31 | **[GPT-REVIEW-2] Dok 14 Ruleset Spec dibuat** (kontrak resolusi board tunggal, ditulis SEBELUM core / T1.0) | Cegah core/solver/view/test "benar" beda-beda |
| 2026-05-31 | **[GPT-REVIEW-2] Objective credit dari EVENT (bukan board scan); board_hash + replay runner + golden fixtures** | Konsistensi & regresi determinisme |
| 2026-05-31 | **[GPT-REVIEW-2] Schema: ruleset_version, rng_algorithm_version, board_hash_expected** | Versioning aturan & reproducibility |
| 2026-05-31 | **[GLM-REVIEW] Ruleset Spec §3.5: double-clear (union mask sekali), special baru kebal clear, dormant→empty saat trigger** | Tutup ambiguitas resolusi simultan (cegah 2 impl "benar" beda) |
| 2026-05-31 | **[GLM-REVIEW] Ruleset Spec §4: gravity & RNG refill urut kolom kiri→kanan** | Determinisme cascade+refill |
| 2026-05-31 | **[GLM-REVIEW] ⚠️ Mali-400 (ES 2.0) DI LUAR TARGET — Godot 4 Compat butuh ES 3.0** (terverifikasi) | Floor device = ES 3.0 / HP 2016/2017+ |
| 2026-05-31 | **[GLM-REVIEW] Obstacle v1 = PackedInt32Array (encode type/hp/layer); color_subset → PackedInt32Array; skor basis ×2 int** | Cache locality solver + eliminasi float |
| 2026-05-31 | **[GLM-REVIEW] Gotcha: @export default vs loaded, ResourceLoader cache, tween leak, autoload _process, custom Resource utk entry** | Jebakan Godot tingkat implementasi |
| 2026-05-31 | **[QWEN-FINAL] MoveAction/TurnReport typed struct (dok 14 §0.1) + T1.2b** | Cegah event dict ad-hoc berbeda core/view |
| 2026-05-31 | **[QWEN-FINAL] Obstacle runtime format + konversi Format A→PackedInt32Array (dok 14 §0.2); v1 = 1 obstacle/cell** | Jembatan design-time↔runtime |
| 2026-05-31 | **[QWEN-FINAL] obstacle_base & objective_base = kontrak di Fase 0/1 (T0.7b)** | Gravity & win/lose butuh interface sebelum Fase 4 |
| 2026-05-31 | **[QWEN-FINAL] Gravity ownership: helper static → board apply (Opsi A)** | Satu tempat mutasi state (determinisme) |
| 2026-05-31 | **[QWEN-FINAL] Combo table = struktur data; core/score.gd terpisah; GameState+SceneManager API spec** | Anti regresi combo; SoC; jembatan view↔core jelas |
| 2026-05-31 | **[QWEN-FINAL] Konsistensi: playable_mask PackedInt32Array, level_definition→data/, DifficultyBand enum, JSON schema konkret, color_subset Array[int] authoring** | Hilangkan ambiguitas antar-dokumen |
| 2026-05-31 | **[QWEN-FINAL] Task baru: T4.0 entry resources, T4.1b tres→json exporter; T4.3 dipecah 3a/3b/3c; i18n CSV di T0.5** | Detail konkret sebelum coding |

| 2026-06-15 | **[GAP-FILL] Star system: 1 bintang/level binary (menang=1, bukan 1-3 stars)** | Modern casual standard (Royal Match model); simpler tracking; tidak membebani pemain dengan "perfect" |
| 2026-06-15 | **[GAP-FILL] "Lumi Burst" (remaining moves celebration)** — sisa langkah otomatis trigger special chain + skor → koin | Mekanik wajib match-3 modern (Sugar Crush/Royal Bonus); momen paling satisfying saat menang dengan efisiensi |
| 2026-06-15 | **[GAP-FILL] Lumi area structure: 3 area v1, 6 Lumi/area, biaya bintang 3-20, total 64 bintang/area** | Konkretisasi meta yang sebelumnya tidak ada angka; harus dispesifikasi sebelum implementasi Fase 7 |
| 2026-06-15 | **[GAP-FILL] Tutorial blocking: tile non-highlight di-dim α0.5 + swap salah diblokir + hint immediate** | "Tutorial invisible" yang sebelumnya tidak ada detail implementasi; field tutorial_forced_swaps ditambah ke LevelDefinition |
| 2026-06-15 | **[GAP-FILL] Hint priority: near-special > obstacle-adjacent > collect-most > random valid** | Hint yang random tidak berguna; hint yang prioritaskan special creation meningkatkan pembelajaran mekanik |
| 2026-06-15 | **[GAP-FILL] Move counter warning: ≤5=kuning pulse, ≤3=merah pulse+tick, ×1=vignette merah** | Universal di semua top match-3; tanpa ini pemain tidak sadar waktu hampir habis |
| 2026-06-15 | **[GAP-FILL] Anti-frustration timing: +5 langkah maks 2×/sesi, penawaran ke-1 free ad/80 koin, ke-2 160 koin** | Sebelumnya tidak ada limit dan tidak ada biaya yang dispesifikasi; batas perlu untuk ekonomi sehat |
| 2026-06-15 | **[GAP-FILL] Daily reward schedule: 7-hari, reset jika skip, reward D7=paling besar** | Schedule konkrit untuk implementasi Fase 7 |
| 2026-06-15 | **[GAP-FILL] Comeback reward: 5 nyawa + 150 koin + 2 booster setelah 7+ hari churn** | Detail FR-M07 yang sebelumnya hanya FR tanpa design |
| 2026-06-15 | **[GAP-FILL] Push notif: 3 jenis lokal (lives full/chest/comeback), minta permission setelah win L1** | Notifikasi sama sekali tidak ada di dok sebelumnya; critical untuk retensi |
| 2026-06-15 | **[GAP-FILL] App rating: Play In-App Review API setelah win L12, tidak kalah 3× sebelumnya** | Timing optimal: sudah invested tapi tidak frustrasi |
| 2026-06-15 | **[GAP-FILL] Screen designs: pre-level (sheet overlay), win (sequence animasi), fail ("Hampir!" + near-miss info)** | Tidak ada spec screen sebelumnya; dibutuhkan sebelum implementasi Fase 6-7 |
| 2026-06-15 | **[GAP-FILL] Level map: zigzag scroll, 3 node states, landmark per area** | Visual design level map belum dispesifikasi |
| 2026-06-15 | **[GAP-FILL] Collectible bring-down mechanic detail: non-swappable, gravity normal, delivered saat reach bottom** | Mekanik ini sudah ada di objectives tapi cara kerjanya tidak pernah dijelaskan |
| 2026-06-15 | **[GAP-FILL] Cascade juice escalation: pitch/partikel/shake table per cascade wave, cap cascade 5+** | Audio/visual escalation sebelumnya hanya "naik pitch" tanpa angka |
| 2026-06-15 | **[GAP-FILL] Haptic pattern spec: 7 momen berbeda dengan timing ms** | Haptic sebelumnya hanya "haptic saat combo/menang" |

> Update tabel ini tiap kali keputusan di bagian 3 diselesaikan.
