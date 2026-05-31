# 09 — Tech Stack & Tooling

> Semua tools, library, dan pipeline yang dibutuhkan. Acuan setup teknis.

---

## 1. Engine & Bahasa

| Item | Pilihan | Catatan |
|---|---|---|
| Engine | **Godot 4.6.3 stable** | Sudah terpasang di `d:\Project\eidosMobile\Godot_v4.6.3-stable_win64\` |
| Bahasa utama | **GDScript** | Mudah dibaca AI & lu, cukup untuk 2D match-3 |
| Bahasa opsional | C# / GDExtension (C++) | HANYA jika solver butuh performa ekstra; kemungkinan tak perlu |
| Renderer | **GL Compatibility** | Paling kompatibel untuk Android low-end (OpenGL ES 3) |

> **Renderer:** untuk jangkauan perangkat Android luas, gunakan **Compatibility renderer** (OpenGL **ES 3.0**), bukan Forward+/Mobile (Vulkan). **Catatan penting:** Godot 4 Compatibility minimum **ES 3.0** → GPU **Mali-400 (ES 2.0) TIDAK didukung**. Floor device = GPU ES 3.0 (Adreno 306, Mali-T620+), umumnya HP 2016/2017+. Verifikasi di HP target sejak T0.9.

---

## 2. Version Control & CI

- **Git** + repo (GitHub/GitLab privat). Buat di Tahap 0.
- `.gitignore` Godot: abaikan `.godot/`, `export_presets.cfg` (path keystore — hati-hati), build artefak.
- **Git LFS** untuk aset besar (tekstur, audio) bila perlu.
- **CI build Android (GitHub Actions + image godot-ci) sejak awal** — jangan andalkan export manual dari editor. Reproducibility build Android = masalah paling umum solo dev. (Temuan tech review.)
- Commit hanya saat diminta. Branch baru untuk fitur besar.

> Catatan: folder engine `Godot_v4.6.3-stable_win64/` **tidak** masuk repo project (binary besar). Git-ignore.

---

## 3. Plugin & Addon Godot

| Kebutuhan | Plugin/opsi | Status |
|---|---|---|
| Unit testing | **GUT** (Godot Unit Test) | Tambah di Tahap 0 |
| Iklan AdMob | Godot AdMob plugin (Android) | Tahap 8 |
| IAP | Godot Google Play Billing plugin | Tahap 8 |
| Analytics | **GameAnalytics (disarankan, gratis, dashboard retensi siap)** / Firebase / thin-HTTP | Lokal sejak Tahap 3, produksi Tahap 8 (lihat dok 11 D17) |
| Crash reporting | Firebase Crashlytics / sejenis | Tahap 8 |
| Font | **Bitmap font (.fnt+.png)**, bukan TTF dinamis | Hindari bug render font Mali-400 (GL Compatibility) |
| Render board | **MultiMeshInstance2D** (1 draw call) | Performa low-end |
| Match-3 base (opsional) | Godot Asset Library match-3 lib (#3405) sbg referensi | Opsional |

> Plugin Android di Godot 4.x memakai sistem **Android plugin (AAR)**. Verifikasi kompatibilitas tiap plugin dgn Godot 4.6.x sebelum dipakai (ekosistem plugin kadang tertinggal versi).

---

## 4. Toolchain Build Android

Dibutuhkan saat Tahap 8 (bukan sekarang):
| Komponen | Fungsi |
|---|---|
| **JDK 17** | Build Android (Godot 4.x butuh JDK 17) |
| **Android SDK + Build Tools + Platform Tools** | Kompilasi APK/AAB |
| **Godot Export Templates** (4.6.3) | Template ekspor Android |
| **Keystore** | Signing app (simpan AMAN, jangan commit) |
| **adb** | Debug di perangkat fisik |

Output rilis: **AAB (Android App Bundle)** untuk Play Store; APK untuk testing lokal.

---

## 5. Tooling Pendukung Development

| Kebutuhan | Tool |
|---|---|
| Editor kode (di luar Godot) | VS Code / Kiro + ekstensi GDScript |
| Art editing | Aseprite (pixel) / Krita / Photoshop / Figma (UI) |
| Audio | Audacity (edit), bfxr/jsfxr (SFX retro), DAW bila perlu |
| Atlas/sprite packing | Godot built-in / TexturePacker |
| Diagram & desain | Excalidraw / draw.io |
| Manajemen tugas | (opsional) Trello/Notion/issues git |

---

## 6. Pipeline Generator/Solver (Internal Tool)

- Dijalankan via Godot **headless** (`godot --headless --script tools/forge.gd`) atau scene "Level Forge".
- Output: batch `.json` level + laporan (CSV/JSON distribusi kesulitan & winrate).
- Tidak masuk build pemain — hanya menghasilkan data level yang dipaketkan.

---

## 7. Analytics — Event yang Dilacak (minimal)

| Event | Parameter |
|---|---|
| `level_start` | level_id, attempt_no |
| `level_complete` | level_id, moves_used, moves_left, stars, time |
| `level_fail` | level_id, fail_reason, objective_remaining, moves_used |
| `tutorial_step` | step_id, completed (deteksi drop-off FTUE) |
| `booster_used` | type, level_id |
| `lumi_collected` | lumi_id, area_id |
| `ad_shown` / `ad_rewarded` | placement, type |
| `iap_purchase` | product_id, price |
| `session_start` / `session_end` | duration |
| `comeback` | days_away (pemain kembali setelah churn) |
| `meta_progress` | area_id, item_unlocked |

> Tujuan: ukur retensi (D1/D7), titik churn (level berapa berhenti), efektivitas iklan. Data ini = bahan bakar iterasi.

---

## 8. Privasi & Kepatuhan Teknis

- **Privacy Policy** (wajib, karena SDK iklan/analytics kumpulkan data). Host di URL publik.
- **Data Safety form** di Play Console (deklarasi data yang dikumpulkan).
- **Consent** (GDPR/UMP untuk iklan) bila menarget region terkait — AdMob UMP SDK.
- **Target API level** sesuai persyaratan Play terbaru saat rilis.
- ID iklan/analytics: deklarasikan penggunaan Advertising ID.

---

## 9. Lingkungan Saat Ini (verified)

- OS: Windows (win32).
- Godot 4.6.3 stable: terpasang & di PATH (`godot`), shortcut Desktop ada.
- Workspace: `d:\Project\eidosMobile\`.
- Belum terpasang (untuk Tahap 7): JDK 17, Android SDK, export templates, keystore.

---

## 10. Daftar Setup Bertahap (kapan pasang apa)

| Saat | Pasang |
|---|---|
| Tahap 0 | Git, GUT, struktur project |
| Tahap 3 (slice) | Analytics LOKAL / debug HUD (struktur event) |
| Tahap 5 | (pakai Godot headless untuk generator/solver) |
| Tahap 8 | JDK 17, Android SDK, export templates, plugin Ads/IAP/Analytics produksi, keystore |
| Paralel (sekarang) | Daftar akun Play Console + siapkan dokumen verifikasi |

> Prinsip: jangan pasang toolchain Android sekarang. Tapi **struktur event analytics dipikirkan sejak Tahap 3** (retrofit analytics ke game jadi = rewrite besar).
