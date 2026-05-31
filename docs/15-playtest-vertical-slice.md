# 15 — Playtest Vertical Slice (T3.5) + Gate Evaluasi (T3.6)

> Panduan & lembar catat untuk gate WAJIB Fase 3 (dok 12 §A). Implementasi kode (T3.1-T3.4) SELESAI; T3.5 (uji ≥5 orang) & T3.6 (evaluasi) **butuh manusia** — lembar ini alatnya.

---

## A. Yang sudah siap (kode Fase 3)
- **5 level hand-crafted** (`data/level_set.gd`) — kurva L1 mudah (3 warna, tutorial) → L5 menantang (5 warna, 18 langkah).
- **FTUE** — L1 instruksi + hint panah kuning otomatis; objektif ringan (kumpul 10) = guaranteed-win realistis.
- **Meta pulau** — menang → bintang → pulau makin bercahaya (3 tahap).
- **Analytics lokal** — `user://analytics.jsonl`: session_start, level_start, move, level_complete (moves_left, stars, secs), level_fail.
- **Debug HUD** — tombol "DBG" di game (FPS, p95 frame, level, total bintang).

## B. Cara ambil data analytics dari HP
```
adb exec-out run-as com.eidoscore.lumisle cat files/analytics.jsonl > playtest_<nama>.jsonl
```
Reset sebelum sesi baru: hapus file via Settings→Apps→Lumisle→Clear data (atau biarkan, tiap sesi punya session id beda).

## C. Protokol sesi (per tester)
1. Cari tester **non-developer, berani jujur** (bukan keluarga inti). Minimal 5 orang. Minimal 1 main di **HP termurah** (F8).
2. Izin rekam (video tangan + layar kalau bisa).
3. Serahkan HP, **JANGAN dijelaskan apa-apa**. Cuma: "coba mainkan ini".
4. **Diam & observasi.** Jangan bantu walau mereka bingung (kebingungan itu DATA).
5. Stopwatch: catat berapa lama mereka main spontan.
6. Setelah mereka berhenti sendiri, baru tanya kuesioner (bagian E).

## D. Lembar observasi (isi per tester saat main)
| Tester | F1 menang L1 tanpa tanya? | F3 lanjut level tanpa disuruh? | F4 durasi main (mnt) | F5 ada keluhan "dicurangi"? | F6 reaksi positif saat clear/special? |
|--------|---------------------------|-------------------------------|----------------------|-----------------------------|----------------------------------------|
| 1      |                           |                               |                      |                             |                                        |
| 2      |                           |                               |                      |                             |                                        |
| 3      |                           |                               |                      |                             |                                        |
| 4      |                           |                               |                      |                             |                                        |
| 5      |                           |                               |                      |                             |                                        |

## E. Kuesioner singkat (setelah main)
1. (F2) "Coba sebutkan semua warna/jenis tile yang kamu lihat." → terbaca <1 detik? Y/T
2. (F7) "Dari 1-10, seberapa pengin kamu main lagi?" → angka: ___
3. Bebas: "Bagian paling membingungkan?" "Bagian paling enak?"

## F. Tabel evaluasi GATE (T3.6) — isi setelah semua tester
| # | Kriteria | Ambang LULUS | Hasil | Lulus? |
|---|----------|--------------|-------|--------|
| F1 | Paham tanpa diajari | ≥4/5 menang L1 tanpa tanya | __/5 | ⬜ |
| F2 | Tile terbaca <1 dtk | ≥4/5 | __/5 | ⬜ |
| F3 | Mau main lagi | ≥4/5 lanjut / bilang "satu lagi" | __/5 | ⬜ |
| F4 | Durasi spontan ≥10 mnt | ≥3/5 | __/5 | ⬜ |
| F5 | Kalah terasa fair | 0/5 bilang "dicurangi" | __/5 | ⬜ |
| F6 | Special memuaskan | ≥4/5 reaksi positif | __/5 | ⬜ |
| F7 | Rating niat main lagi | rata-rata ≥7 | ___ | ⬜ |
| F8 | Performa low-end | ≥30 FPS, no crash/overheat 10 mnt | FPS:__ | ⬜ |

## G. Keputusan gate (dok 12 §A.3)
- **SEMUA F1-F8 lulus** → ✅ lanjut Fase 4 (level data + kurikulum + generator).
- **Sebagian gagal** → iterasi slice (juice / tutorial / balancing / **art tile**) lalu uji ulang.
- **Gagal 3 ronde** → ⛔ stop, evaluasi fundamental (core loop / art / target).

> **Catatan jujur (penting):** art masih placeholder kotak warna. F2 (keterbacaan) & F6 (kepuasan) kemungkinan besar terdampak. Kalau gagal HANYA di F2/F6, kemungkinan besar penyebabnya art — prioritaskan ganti tile sprite sebelum ronde uji berikutnya, bukan utak-atik mekanik.

---

## H. Ringkasan hasil ronde (diisi Dev)
- Ronde ke: ___  Tanggal: ___  Jumlah tester: ___  HP low-end yang dipakai: ___
- F-yang-gagal: ___
- Akar masalah dugaan: ___
- Tindakan iterasi: ___
- Keputusan: ⬜ lanjut Fase 4  ⬜ iterasi  ⬜ stop & evaluasi
