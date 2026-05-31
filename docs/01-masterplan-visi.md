# 01 — Masterplan & Visi

> North star proyek. Kalau ragu soal keputusan apa pun, balik ke dokumen ini.

---

## 1. Visi (North Star)

> **"Game puzzle ringan yang jadi pilihan utama orang saat gabut atau istirahat — gampang dimulai, susah ditinggalkan, dan gak bikin frustrasi."**

Game ini bukan soal grafis wah atau gameplay kompleks. Ini soal **kenyamanan**: bisa dibuka kapan aja, dimainin 1-5 menit, ngasih rasa puas, lalu ditutup tanpa beban. Tapi ada cukup "tarikan" (progress, cerita, hadiah harian) supaya orang balik lagi besok.

---

## 2. Latar Belakang & Motivasi

- **Siapa:** Solo developer (lu) + AI agent sebagai engineer. Lu = game director / pengambil keputusan.
- **Kenapa match-3:** Genre puzzle = #2 terbesar by download, retensi & monetisasi terbukti (Royal Match ~$113 jt/bulan). Core-nya "solved problem" secara teknis → realistis buat solo+AI.
- **Kenapa hybrid-casual:** Segmen yang tumbuh paling cepat (+17-20% YoY). Match dengan motivasi pemain terbesar: lawan bosan & redakan stres.
- **Tujuan akhir lu:** Jadi publisher game di Google Play, dimulai dari 1 game yang utuh & dipoles.

---

## 3. Tujuan Proyek (Goals)

### Tujuan Utama
1. **Rilis 1 game match-3 yang utuh & dipoles** ke Google Play.
2. **Buktikan pipeline "generator + solver"** bisa memproduksi ratusan-ribuan level berkualitas.
3. **Validasi retensi** (D1 ≥ 30%, D7 ≥ 10% sebagai target sehat awal).
4. **Bangun fondasi reusable** (engine match-3 modular) yang bisa dipakai untuk game berikutnya.

### Bukan Tujuan (Non-Goals) — penting biar gak over-scope
- ❌ Menyaingi Royal Match 1:1 dalam skala/produksi.
- ❌ LiveOps online (turnamen multiplayer, server real-time) di v1.
- ❌ 4.500+ level desain manual.
- ❌ Grafis 3D / fotorealistik.
- ❌ User acquisition berbayar skala besar di awal.

---

## 4. Prinsip Desain (Non-Negotiable)

Diturunkan dari dekonstruksi Royal Match (`docs/02`):

1. **Anti-frustrasi di atas segalanya.** Tiap titik di mana pemain mau berhenti karena kesal → kasih jalan keluar, bukan hukuman.
2. **Fun dalam 10 detik pertama.** Begitu buka level, langsung ada sensasi memuaskan.
3. **Puzzle = mesin, bukan tujuan.** Selalu ada "alasan main" di luar puzzle (bangun sesuatu, cerita, hadiah).
4. **Polish > fitur.** Lebih baik sedikit fitur tapi terasa premium (animasi, suara, haptic) daripada banyak fitur hambar.
5. **Sesi pendek, satu tangan, portrait.** Desain untuk "dimainin sambil rebahan".
6. **Data > feeling.** Keputusan tuning kesulitan & retensi berbasis analytics.
7. **Scope kecil dulu.** 200 level solid > 10.000 level hambar.

---

## 5. Strategi Besar (High-Level)

### Strategi Produk
- **Validasi fun DULU (vertical slice), baru bangun mesin konten.** (Konvergen 3 review.) Urutan risiko: buktikan 3-5 level terasa hidup → hand-craft FTUE → BARU generator. Jangan bangun pabrik level di atas core yang belum terbukti.
- **MVP dulu, polish, baru scale.** Bangun core playable → buktikan fun → tambah meta → baru gandakan konten.
- **Generator-as-drafting-tool**, bukan pengganti desainer. 50 level pertama (kurikulum FTUE) hand-crafted.
- **Diferensiasi via meta KOLEKSI "Lumi" + tema pulau + polish** (bukan art prosedural). Lihat dok 11 D2.

### Strategi Teknis
- **Pisahkan Data ↔ Logika ↔ Tampilan.** Bikin tiap modul bisa dikerjain AI terpisah & diuji independen.
- **Logika headless & testable.** Board logic bisa dijalanin tanpa grafis (penting buat solver bot & unit test).

### Strategi Go-to-Market
- **Pasar awal: Indonesia/SEA** (install murah, validasi cepat).
- **Visual universal** supaya bisa scale ke tier-1 (US/EU) kalau retensi bagus.
- **Organik + ASO dulu**, UA berbayar nanti.

---

## 6. Definisi Sukses (per fase)

| Fase | Definisi sukses |
|---|---|
| **Vertical Slice (GATE)** | 3-5 level full-juice; 3+ orang non-dev bilang "satu level lagi"; tile kebaca tanpa dijelaskan; kalah terasa fair; mulus di HP low-end |
| MVP internal | 20-30 level FTUE (kurikulum), special items, meta koleksi tipis, save, analytics |
| Soft launch | Rilis terbatas (Filipina/Vietnam), ukur retensi nyata |
| Rilis global | Live di Play Store, monetisasi aktif, gated by metrik (D1≥40%, D7≥15%) |
| Sukses awal | D7 ≥ 15%, ada revenue iklan konsisten, basis pemain organik tumbuh |

> Catatan: target retensi dinaikkan (D1 ≥40%, D7 ≥15%) sesuai standar casual yang disebut reviewer — D1 di bawah ~35% umumnya pertanda game tidak sehat.

---

## 7. Filosofi Kolaborasi Lu + AI

- **AI (agent):** seluruh implementasi kode, arsitektur, generator, solver, integrasi, debugging, dokumentasi teknis.
- **Lu (director):** visi, keputusan desain, kurasi art/audio, playtest & "rasa", tuning final, urusan akun/rilis/legal.
- **Prinsip:** AI gak ambil keputusan desain besar tanpa lu. Lu gak perlu nulis kode. Pertemuannya di dokumen ini.

---

## 8. Timeline Kasar (target, bukan janji) — REVISI v2

```
Bulan 1-2   : Core + special items + juice (Tahap 0-2)
Bulan 2.5-3 : VERTICAL SLICE GATE — buktikan fun (Tahap 3) ← STOP kalau gagal
Bulan 3.5-4.5: Level data + 20-30 level FTUE kurikulum (Tahap 4)
Bulan 5-6   : Generator archetype + ensemble solver (Tahap 5, jika slice lolos)
Bulan 6-7   : Meta koleksi + ekonomi + save + FTUE (Tahap 6-7)
Bulan 7-8   : Monetisasi + polish + ASO + closed test + soft launch (Tahap 8)
Bulan 8+    : Iterasi data → rilis global, gated by metrik (Tahap 9)
```

Estimasi jujur **~8 bulan** (konvergen 3 review; 4-5 bulan dinilai terlalu optimis). Detail per-tahap + aksi paralel (daftar akun Play sekarang) ada di dok 08.
