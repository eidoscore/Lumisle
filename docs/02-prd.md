# 02 — Product Requirements Document (PRD)

> Apa yang dibangun (bukan gimana). Sumber kebenaran untuk scope & fitur.
> Format: requirement diberi ID (FR = Functional, NFR = Non-Functional) + prioritas MoSCoW (Must/Should/Could/Won't).

---

## 1. Ringkasan Produk

**Produk:** Game mobile match-3 hybrid-casual untuk Android (Google Play).
**Platform target:** Android (phone), portrait, Godot 4.6.3.
**Audiens:** Pemain casual 18-45, main untuk relaksasi/lawan bosan, sesi pendek. Awal: Indonesia/SEA.
**Model bisnis:** Free-to-play, hybrid (iklan + IAP remove ads).

---

## 2. Persona Pengguna

### Persona A — "Rina, si Pelepas Penat" (primary)
- 28 thn, kerja kantoran, main di transportasi/sebelum tidur.
- Mau: relaksasi, sesi 3-5 menit, gak mau ribet, benci iklan maksa.
- Sukses kalau: bisa langsung main, ngerasa puas tiap level, ada progress kelihatan.

### Persona B — "Andi, si Pengisi Waktu Gabut" (primary)
- 22 thn, mahasiswa, main pas nunggu/bosen.
- Mau: tantangan ringan, "satu lagi deh", hadiah harian.
- Sukses kalau: ada alasan balik tiap hari, gak stuck terlalu lama.

### Persona C — "Bu Sari, si Kolektor Santai" (secondary)
- 40 thn, suka dekorasi & cerita, main rutin di rumah.
- Mau: membangun/menghias sesuatu, narasi ringan, progress jangka panjang.
- Sukses kalau: ada meta-progression yang memuaskan (renovasi/koleksi).

---

## 3. Functional Requirements

### 3.1 Core Gameplay (Puzzle)
| ID | Requirement | Prioritas |
|---|---|---|
| FR-C01 | Papan grid (ukuran variabel per level, mis. 6x7 s/d 9x9) | Must |
| FR-C02 | Swap 2 tile bersebelahan; valid hanya jika menghasilkan match 3+ | Must |
| FR-C03 | Deteksi match horizontal & vertikal (3, 4, 5+) | Must |
| FR-C04 | Gravity (tile jatuh) + refill (tile baru dari atas) | Must |
| FR-C05 | Cascade / chain reaction (match beruntun otomatis) | Must |
| FR-C06 | Pool 6 warna; tiap level menampilkan SUBSET (4/5/6) yang dipilih saat generate (berseed, dipandu difficulty) | Must |
| FR-C07 | Deteksi "no more moves" → reshuffle papan otomatis | Must |
| FR-C08 | Hint (highlight kemungkinan match) setelah idle 5 detik, prioritas: near-special > obstacle-adjacent > random valid | Should |
| FR-C09 | Move counter warning: ≤5 langkah = kuning pulse; ≤3 = merah pulse + tick SFX; langkah terakhir = vignette merah | Must |
| FR-C10 | **Remaining Moves Celebration ("Lumi Burst"):** saat menang dengan sisa langkah, sisa langkah otomatis trigger special chain + score bonus → konversi ke koin | Must |

### 3.2 Special Items & Combo
| ID | Requirement | Prioritas |
|---|---|---|
| FR-S01 | Match-4 segaris → Roket (hancurkan baris/kolom) | Must |
| FR-S02 | Match-5 L/T atau 2x2 → Bom/TNT (ledak area) | Must |
| FR-S03 | Match-5 segaris → Color Bomb/Light Ball (hapus 1 warna) | Must |
| FR-S04 | Kombinasi 2 special item → efek gabungan | Should |
| FR-S05 | Special item ke-4 (mis. propeller) | Could |

### 3.3 Objektif & Rintangan
| ID | Requirement | Prioritas |
|---|---|---|
| FR-O01 | Objektif "kumpulkan N tile warna X" | Must |
| FR-O02 | Objektif "hancurkan N rintangan" (mis. es) | Must |
| FR-O03 | Batas langkah (move limit) per level | Must |
| FR-O04 | Kondisi menang (objektif tercapai) & kalah (langkah habis) | Must |
| FR-O05 | Rintangan dasar: Es (ice) — pecah dgn match di sebelah | Must |
| FR-O06 | Rintangan: Box/Crate (hancur kena match di atasnya) | Should |
| FR-O07 | Rintangan: item "jatuhkan ke bawah" (collect at bottom) | Should |
| FR-O08 | Rintangan lanjutan (honey/cake/generator) | Could |
| FR-O09 | 10-15 jenis rintangan total (jangka panjang) | Could |

### 3.4 Sistem Level
| ID | Requirement | Prioritas |
|---|---|---|
| FR-L01 | Level disimpan sebagai DATA (resource/JSON), bukan kode | Must |
| FR-L02 | Level loader: baca data → setup papan | Must |
| FR-L03 | **20-30 level FTUE hand-crafted** (kurikulum, dipoles) | Must |
| FR-L04 | Generator level **archetype-based** + kurva kesulitan (drafting tool) | Must |
| FR-L05 | Solver bot **ensemble** : solvability + win-rate per-band + **metrik kualitas** (near-miss, variance, stuck) | Must |
| FR-L06 | Pipeline: generate → solve → filter → **kurasi/spot-check manual** → simpan | Must |
| FR-L07 | Dynamic difficulty (bantuan halus kalau pemain kalah beruntun) | Should |
| FR-L08 | Peta level (level map) sebagai navigasi progress | Should |
| FR-L09 | Konten: **1-30 hand-crafted, 31-100 draft-assisted, 101+ generated** (bukan 50/100 murni manual) | Must |

### 3.5 Meta & Progression
| ID | Requirement | Prioritas |
|---|---|---|
| FR-M01 | Menang level → **1 bintang** (binary: menang=1, kalah=0). Replay tidak beri bintang ekstra. Bintang permanen. | Must |
| FR-M02 | Sistem progress (level keberapa, unlock berurutan) | Must |
| FR-M03 | Meta **KOLEKSI "Lumi" (roh cahaya)** pakai bintang — hook utama (lihat GDD §6.0-§6.1) | Must |
| FR-M04 | **Album/koleksi Lumi** (entri, lore singkat, progress per area). v1: 3 area × 6 Lumi = 18 Lumi total. | Must |
| FR-M05 | Cerita ringan / maskot pemandu (1-2 kalimat per area) | Should |
| FR-M06 | Daily reward: kalender 7-hari streak, reset jika skip hari, reward naik tiap hari (detail GDD §6.3.1) | Should |
| FR-M07 | **Comeback reward** (pemain kembali setelah 7+ hari): 5 nyawa + 150 koin + 2 booster (detail GDD §6.3.3) | Should |
| FR-M08 | Area pulau menyala (redup→bercahaya) seiring Lumi terkumpul | Should |
| FR-M09 | **Push notifications lokal** (3 jenis: lives full, chest ready, comeback 72h) — minta permission setelah win L1 | Should |
| FR-M10 | **App rating prompt** via Google Play In-App Review API: setelah win L12, tidak pernah gagal 3× berturut-turut | Should |
| FR-M11 | **Lumi rarity** (Common/Rare/Epic per area) — visual berbeda, lore lebih panjang, tidak mempengaruhi gameplay | Could |

### 3.5.1 FTUE (First Time User Experience) — KRITIS
| ID | Requirement | Prioritas |
|---|---|---|
| FR-F01 | Tutorial **invisible**: highlight 2 tile target (pulse+glow), tile lain di-dim (alpha 0.5), swap salah **diblokir** (tidak makan langkah), hint langsung tanpa idle delay | Must |
| FR-F02 | Level 1-3 **guaranteed win** via `spawn_pattern` + field `tutorial_forced_swaps` — board bukan random, pre-set agar menang dalam N langkah jika hint diikuti | Must |
| FR-F03 | Value proposition pulau tersampaikan dalam **60 detik pertama** (Lumi meta tease saat menang L1) | Must |
| FR-F04 | Tutorial selesai setelah L5 → flag `tutorial_complete` → input blocking dihapus | Must |
| FR-F05 | Uji FTUE ke ≥5 orang yang belum pernah lihat game (gate dok 12 F1-F8) | Should |

### 3.6 Ekonomi
| ID | Requirement | Prioritas |
|---|---|---|
| FR-E01 | Mata uang: Koin | Must |
| FR-E02 | Sistem Nyawa (lives) + regen waktu | Must |
| FR-E03 | Booster pre-level (mulai dgn power-up) | Should |
| FR-E04 | Booster in-level (mis. palu/swap) | Should |
| FR-E05 | Toko sederhana (beli koin/booster/nyawa) | Should |

### 3.7 Monetisasi
| ID | Requirement | Prioritas |
|---|---|---|
| FR-N01 | Iklan Rewarded (continue, +nyawa, double reward, hint) | Must |
| FR-N02 | Iklan Interstitial (antar level, dengan frequency cap) | Must |
| FR-N03 | IAP "Remove Ads" (hapus interstitial/banner) | Must |
| FR-N04 | IAP starter pack / paket koin | Could |
| FR-N05 | Mediation (AdMob; opsi AppLovin nanti) | Should |

### 3.7.1 Screen Design (UI)
| ID | Requirement | Prioritas |
|---|---|---|
| FR-U01 | **Pre-level screen** (overlay sheet): tampilkan level number, semua objektif + ikon, move limit, 3 slot booster pre-level, tombol Main!/Back | Must |
| FR-U02 | **Win screen**: animasi bintang → koin count-up → progress bar Lumi → Lumi reveal (jika unlock) → tombol Next Level | Must |
| FR-U03 | **Fail screen**: framing positif ("Hampir!") + info near-miss ("Kurang N tile") + Retry / Back to Map. Tanpa interstitial ad. | Must |
| FR-U04 | **Level map**: zigzag path, 3 node states (terkunci/selesai/aktif), landmark per area | Should |
| FR-U05 | Move counter warning: warna + pulse (detail GDD §3.6.2) | Must |

### 3.8 Sistem Pendukung
| ID | Requirement | Prioritas |
|---|---|---|
| FR-X01 | Save/load progress lokal (user://) | Must |
| FR-X02 | Settings (suara, musik, haptic, bahasa) | Must |
| FR-X03 | Analytics (event level start/win/fail, retensi) | Must |
| FR-X04 | Lokalisasi (minimal EN + ID) | Should |
| FR-X05 | Cloud save (Google Play Games) | Could |
| FR-X06 | Onboarding/tutorial interaktif | Must |

---

## 4. Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Performa | 60 FPS di perangkat mid-range; minimal 30 FPS di low-end |
| NFR-02 | Ukuran app | < 100 MB (idealnya < 60 MB) install awal |
| NFR-03 | Waktu load level | < 1 detik |
| NFR-04 | Kompatibilitas | Android 8.0+ (API 26+), **GPU OpenGL ES 3.0** (Godot 4 Compatibility butuh ES 3.0 → Mali-400/ES 2.0 di luar target; floor ~HP 2016/2017+), patuhi target API terbaru Play |
| NFR-05 | Offline-first | Game inti bisa dimainkan tanpa internet (iklan butuh internet) |
| NFR-06 | Battery/thermal | Tidak boros; hindari render berlebih saat idle |
| NFR-07 | Aksesibilitas | Kontras warna cukup; ada penanda non-warna (bentuk/ikon) untuk tile |
| NFR-08 | Stabilitas | Crash-free session ≥ 99% |
| NFR-09 | Privasi | Privacy policy + Data Safety form (SDK iklan kumpulkan data) |
| NFR-10 | Maintainability | Modular, logika terpisah dari view, terdokumentasi |

> **Catatan aksesibilitas (NFR-07):** match-3 sangat bergantung warna. WAJIB ada pembeda non-warna (ikon/bentuk berbeda tiap tile) untuk pemain buta warna. Validasi penuh butuh pengujian manual.

---

## 5. Scope Rilis (Versioning) — REVISI (slice-first)

### v0.1 — Prototipe core (internal)
Must dari FR-C* + FR-S01..03 + 1 level hardcoded. Tujuan: core jalan.

### v0.2 — VERTICAL SLICE (GATE) ⛔
3-5 level full-juice + FR-F01..04 (FTUE) + analytics lokal + 1 layar meta placeholder. **Tujuan: buktikan FUN.** Tidak lanjut sebelum gate lolos (uji ke orang nyata). Lihat roadmap Tahap 3.

### v0.5 — MVP (internal/closed)
+ FR-L01..03,L09 (data + 20-30 level FTUE kurikulum), FR-O01..05, FR-M01..04, FR-E01..02, FR-X01..03, FR-X06. (Generator FR-L04..06 menyusul SETELAH slice lolos.)

### v1.0 — Soft Launch → Rilis Play Store
+ FR-L04..06 (generator archetype + ensemble solver), FR-N01..03 (monetisasi), FR-M05..08 (koleksi/daily/comeback), FR-E03..05, FR-X02, FR-X04, polish & juice penuh, ASO.

### v1.x — Pasca-rilis (kalau retensi bagus)
FR-O08..09, FR-S04..05, FR-X05, LiveOps ringan (daily challenge/event lokal/season pass offline).

### Won't (v1) — eksplisit di luar scope
Multiplayer, turnamen online, server LiveOps, 3D, level editor publik.

---

## 6. Success Metrics (KPI) — REVISI pasca-3-review

| Metrik | Target | Cara ukur |
|---|---|---|
| D1 Retention | **≥ 40%** (di bawah ~35% = tidak sehat) | Analytics |
| D7 Retention | **≥ 15%** | Analytics |
| D30 Retention | ≥ 6% | Analytics |
| Avg session length | ≥ 15 menit (soft-launch gate) / 4-8 mnt per sesi | Analytics |
| Level fail rate (onboarding 1-30) | rendah (win 85-95% di early) | Analytics |
| Crash-free sessions | ≥ 99% | Crash reporting |
| Tutorial completion | ≥ 85% | Analytics |
| Ad-watch rate (yang ditawari) | ≥ 30% (soft-launch gate) | Ad report |
| IAP conversion | ≥ 1% (soft-launch gate) | IAP report |
| ARPDAU | dipantau, bukan target awal | Ad/IAP report |

> **Metric gate sebelum rilis global** (dok 08 Tahap 9): D1≥40%, D7≥15%, session≥15mnt, ad-watch≥30%, IAP≥1%. Tidak tercapai → iterasi/pivot.

---

## 7. Asumsi & Dependensi

- Lu menyediakan/menyetujui aset art & audio (atau setuju pakai aset gratis/AI-generated).
- Akun Google Play Developer ($25) didaftarkan sebelum rilis.
- Keputusan desain terbuka (dok 11) diselesaikan sebelum tahap terkait dimulai.
- AdMob (atau mediation) account disiapkan sebelum integrasi monetisasi.
