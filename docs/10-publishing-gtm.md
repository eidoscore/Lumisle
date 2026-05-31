# 10 — Publishing & Go-to-Market

> Cara membawa game dari "selesai dibangun" ke "ada di Play Store & ditemukan pemain".

---

## 1. Akun & Persyaratan Google Play

| Item | Detail |
|---|---|
| **Biaya daftar** | $25 sekali bayar (seumur hidup) |
| **Jenis akun** | Personal atau Organization. Personal cukup untuk mulai |
| **Closed testing gate** | Akun personal baru: wajib **min. 12 tester selama 14 hari berturut** sebelum bisa rilis produksi. Siapkan grup tester dari awal |
| **Verifikasi developer** | Mulai **Sep 2026**, verifikasi identitas wajib. **Indonesia gelombang pertama** (bareng Brazil, Singapura, Thailand). Siapkan dokumen identitas |
| **Chargeback** | Mulai 2026, biaya chargeback transaksi mulai dibebankan ke developer |

> **Aksi awal:** daftar akun **SEKARANG** (verifikasi identitas Indonesia mulai Sep 2026 butuh lead time; proses 2-4 minggu), dan kumpulkan 12+ calon tester (teman/keluarga/komunitas) sejak Tahap 7.

---

## 2. Persiapan Store Listing (Tahap 8)

### Aset wajib
- [ ] **Ikon app** (512x512) — 3 varian untuk A/B test.
- [ ] **Feature graphic** (1024x500).
- [ ] **Screenshot** (portrait) — **jual meta "koleksi Lumi & pulau menyala"**, bukan cuma board match-3 (board polos = mirip 5000 game lain).
- [ ] **Video promo** (15-30 detik) — disarankan.
- [ ] **Judul** (≤ 30 char) — mengandung kata kunci.
- [ ] **Deskripsi singkat** (≤ 80 char) — hook utama.
- [ ] **Deskripsi panjang** — fitur, kata kunci, ajakan main.

### Konten kebijakan
- [ ] **Privacy policy** (URL publik) — wajib.
- [ ] **Data Safety form** terisi.
- [ ] **Content rating** (kuesioner IARC).
- [ ] **Target audience & content** (deklarasi usia).
- [ ] Kategori: Games > Puzzle.

---

## 3. ASO (App Store Optimization)

Karena UA berbayar mahal, **organik via ASO** adalah jalur awal utama.

| Elemen | Strategi |
|---|---|
| **Judul** | Kata kunci utama (mis. "block/match puzzle") + brand |
| **Deskripsi singkat** | Hook + benefit ("santai", "gratis", "puzzle") |
| **Ikon** | Menonjol di thumbnail, bisa dibaca kecil, A/B test |
| **Screenshot** | 3 detik pertama harus "jual" — tunjukkan inti fun + teks benefit |
| **Kata kunci** | Riset istilah yang dicari (puzzle, match 3, relaxing game, dll) |
| **Lokalisasi listing** | Minimal EN + ID; tambah bahasa pasar target |
| **Rating & review** | Minta rating di momen senang (setelah menang), bukan saat frustrasi |

> A/B testing listing (Google Play Store Listing Experiments) untuk ikon & screenshot setelah ada trafik.

---

## 4. Strategi Rilis Bertahap

```
1. Internal testing  → tim kecil (lu + beberapa orang), iterasi cepat.
2. Closed testing    → 12+ tester × 14 hari (syarat akun baru). Kumpulkan feedback & data.
3. **Soft launch (PASAR KECIL: Filipina/Vietnam/Bangladesh)** → rilis terbatas di 2-3 negara kecil. CPI murah ($0.10-0.30), kumpulkan data retensi 4-6 minggu, iterasi SEBELUM main launch. (Temuan review — langkah penting yang sebelumnya hilang.)
4. Open testing (beta) → opsional, jika ingin skala uji lebih besar.
5. Production (staged rollout) → Indonesia dulu, lalu SEA/global, bertahap (10% → 50% → 100%) untuk pantau crash & metrik.
```

> Staged rollout penting: kalau ada bug/crash di produksi, dampaknya terbatas & bisa di-halt.
> **Kenapa soft launch di pasar kecil dulu:** uji retensi nyata dengan risiko & biaya rendah, dan jaga "kesan pertama" di pasar utama (Indonesia) sampai game benar-benar terbukti.

---

## 5. Pasar & Lokalisasi

- **Pasar awal:** Indonesia + SEA (install murah, validasi cepat, "kandang" lu).
- **Bahasa:** EN (default global) + ID (pasar utama). Tambah sesuai data.
- **Harga IAP:** gunakan local pricing Play Store; sesuaikan psikologi harga per region.
- **Visual universal** supaya siap scale ke tier-1 (US/EU) jika retensi terbukti — di sanalah eCPM iklan & IAP jauh lebih tinggi.

---

## 6. User Acquisition (UA)

| Fase | Strategi |
|---|---|
| Awal (modal minim) | Organik: ASO, share ke komunitas, media sosial, teman |
| Validasi | Sedikit budget tes (mis. kampanye kecil) untuk ukur CPI vs retensi |
| Scale (jika LTV > CPI) | Baru pertimbangkan UA berbayar serius (Google App Campaigns, dll) |

> Aturan emas: **jangan scale UA sebelum retensi & monetisasi sehat.** Bayar untuk akuisisi di atas retensi buruk = bakar uang. Urutan: Fun → Retensi → Monetisasi → baru UA.

---

## 7. Pasca-Rilis (Live)

- Pantau: D1/D7 retention, fail rate per level, crash-free %, ARPDAU.
- Update berkala: tambah level (generator), perbaiki titik churn, event ringan.
- Respon review (terutama negatif) — sumber insight & memperbaiki rating.
- Kalibrasi solver dgn data fail nyata (loop dok 05 §9).

---

## 8. Checklist Kepatuhan Pra-Rilis

- [ ] Privacy policy live di URL.
- [ ] Data Safety form akurat.
- [ ] Consent iklan (UMP) jika perlu region.
- [ ] Content rating sesuai.
- [ ] Target API level memenuhi syarat Play.
- [ ] Tidak ada aset berlisensi yang melanggar (audit `ASSETS_LICENSES.md`).
- [ ] Tidak ada konten yang melanggar kebijakan Play (iklan menyesatkan, dll).
- [ ] Keystore di-backup aman (kehilangan = tak bisa update app selamanya).

---

## 9. Risiko Publishing (lihat juga dok 11)

- **Penolakan review** karena kebijakan (privacy, iklan, metadata) → siapkan dokumen rapi.
- **Closed test 14 hari** memperlambat rilis → mulai lebih awal.
- **Verifikasi developer (Sep 2026)** → urus identitas tepat waktu.
- **Pasar match-3 padat** → diferensiasi (tema/twist) & ASO kuat jadi krusial.
