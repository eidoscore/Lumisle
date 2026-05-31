# 03 — Game Design Document (GDD)

> Desain detail: gimana game-nya terasa & bekerja. Turunan dari prinsip di dok 01 & requirement di dok 02.

---

## 1. Pilar Desain

1. **Memuaskan (Satisfying).** Tiap aksi punya feedback: suara "pop", animasi, partikel, getaran.
2. **Mudah dimulai, dalam saat ditekuni.** Aturan dasar dipelajari dalam 10 detik; kedalaman dari special items & combo.
3. **Tanpa frustrasi.** Kalah terasa "hampir menang", selalu ada jalan keluar (booster, +langkah, retry).
4. **Selalu ada progress.** Tiap sesi ninggalin jejak: bintang, koin, area baru, hadiah.

---

## 2. Core Loop

```
┌─────────────────────────────────────────────────────┐
│  1. Buka game → lihat ada "yang baru" (hadiah/progress) │
│  2. Pilih level berikutnya di peta                      │
│  3. Main level (match-3, 1-3 menit)                     │
│       └─ buat match → special items → combo → puas      │
│  4. Menang → animasi reward → dapat bintang + koin       │
│  5. Pakai bintang untuk meta (kumpulkan Lumi → pulau menyala)  │
│  6. (Kalau kalah) → tawaran +langkah / booster / retry   │
│  7. Nyawa berkurang saat kalah → pacing                  │
│  8. Kembali ke peta → ulangi / berhenti dengan puas      │
└─────────────────────────────────────────────────────┘
```

**Session loop (jangka pendek):** main level → reward → next.
**Daily loop (jangka menengah):** login → daily reward → habiskan nyawa → progress meta.
**Long-term loop (jangka panjang):** kumpulkan semua Lumi di satu area → buka cerita/area baru → lengkapi album koleksi.

---

## 3. Mekanik Inti (Detail)

### 3.1 Papan (Board)
- Grid 2D, ukuran per level (mis. 6x7 sampai 9x9).
- Tiap sel berisi: tile warna, atau special item, atau rintangan, atau kosong/terkunci.
- Beberapa sel bisa "non-playable" (bentuk papan tidak harus persegi).

### 3.2 Tile
- **Pool 6 warna dasar.** Tiap level hanya menampilkan **subset** (4/5/6) yang dipilih saat generate level (berseed + dipandu difficulty) — tidak selalu ke-6 muncul bersamaan. Level santai = 4 warna, menengah = 5, susah = 6 (lihat dok 11 D5).
- Subset disimpan di `LevelDefinition` (deterministik, bukan acak runtime → konsisten & bisa divalidasi solver).
- **Tiap warna punya bentuk/ikon berbeda** (aksesibilitas buta warna — wajib).
- **Art tile = aset CC0 yang jelas & terbaca** (BUKAN prosedural), demi keterbacaan 0.5 detik di layar kecil & performa Android low-end (revisi pasca-review, dok 11 D1). Palet 6 warna harmonis & konsisten.

### 3.3 Swap & Match
- Pemain geser 2 tile bersebelahan (drag/tap-tap).
- Valid jika menghasilkan ≥ 1 garis 3+ sewarna. Kalau tidak, tile balik (no penalty langkah — anti-frustrasi).
- Match → tile hilang → gravity → refill → cek cascade → ulangi sampai stabil.

### 3.4 Special Items
| Item | Cara dapat | Efek |
|---|---|---|
| **Roket** | Match 4 segaris | Hancurkan 1 baris/kolom. **Orientasi:** match horizontal → roket horizontal (hancurkan baris); match vertikal → roket vertikal (hancurkan kolom) |
| **Bom/TNT** | Match 5 bentuk **L atau T** (dua garis berpotongan) | Ledak area 3x3 (atau radius) |
| **Color Bomb** | Match 5 **segaris lurus** | Hapus semua tile 1 warna (warna yang di-swap) |
| **Propeller** (opsional) | Kombinasi khusus | Terbang ke tile target lalu ledak |

> **Aturan pembuatan (deterministik):** L vs T dibedakan dari bentuk perpotongan; 5-segaris = Color Bomb; 5-bukan-segaris (L/T) = Bom. Special **di-spawn di posisi swap terakhir pemain** (atau titik potong untuk L/T). Solver pakai aturan identik.

### 3.5 Combo (gabungan 2 special)
| Combo | Efek |
|---|---|
| Roket + Roket | Hancurkan 1 baris + 1 kolom (palang) |
| Roket + Bom | Palang tebal (3 baris + 3 kolom) |
| Bom + Bom | Ledakan area besar |
| Color Bomb + Roket | Ubah semua tile 1 warna jadi roket, semua meledak |
| Color Bomb + Bom | Ubah semua tile 1 warna jadi bom, semua meledak |
| Color Bomb + Color Bomb | **Bersihkan seluruh papan** + kupas 1 lapis tiap rintangan |

> Combo = momen "wow" terbesar. Animasi & suara WAJIB megah di sini.

### 3.6 Kondisi Menang/Kalah
- **Menang:** semua objektif level tercapai (dalam batas langkah).
- **Kalah:** langkah habis sebelum objektif tercapai.
- **Saat kalah:** tawarkan +5 langkah (bayar koin / nonton rewarded ad) sebelum benar-benar kalah. Anti-frustrasi.

### 3.7 Dead-board & Reshuffle
- Kalau tidak ada lagi swap yang menghasilkan match → papan **otomatis diacak ulang** (animasi reshuffle).
- **Default: reshuffle GRATIS** (tidak mengurangi langkah) — board mentok bukan salah pemain (keputusan D16, dok 11).
- Solver memodelkan reshuffle identik dengan game (lihat dok 04 §3.9).

---

## 4. Objektif Level (Variasi)

| Tipe | Deskripsi | Contoh |
|---|---|---|
| Collect | Kumpulkan N tile warna tertentu | "Kumpulkan 40 merah" |
| Clear obstacle | Hancurkan semua/N rintangan | "Pecahkan 25 es" |
| Bring down | Turunkan objek ke baris bawah | "Turunkan 3 kunci" |
| Score target | Capai skor X | "Raih 5000 poin" |
| Combo objective | Kombinasi di atas | "Pecahkan 10 es + kumpulkan 20 biru" |

Variasi objektif + rintangan + tata letak = sumber variasi ribuan level (lihat dok 05).

---

## 5. Rintangan (Obstacles)

Dibangun bertahap. Tiap rintangan = 1 modul terpisah.

| Rintangan | Mekanik | Fase |
|---|---|---|
| **Es (Ice)** | Pecah jika ada match di sel sebelah; butuh N hit | MVP |
| **Box/Crate** | Hancur jika match terjadi tepat di atasnya | MVP |
| **Collectible (kunci/permata)** | Harus diturunkan ke baris bawah | MVP |
| **Honey/Lem** | Menempel, menyebar; harus dipecah | v1.x |
| **Cake/Layered** | Berlapis, kupas tiap hit | v1.x |
| **Generator** | Memproduksi tile/rintangan tiap giliran | v1.x |
| **Locked tile** | Tidak bisa di-swap sampai dibebaskan | v1.x |

---

## 6. Meta-Progression ("Alasan Main")

### 6.1 Konsep utama: "Koleksi Roh Cahaya Pulau" (DIKUNCI — dok 11 D2)
Hook meta = **KOLEKSI**, bukan dekorasi (membedakan dari Gardenscapes/Matchington yang sudah pakai "restore a place").
- **Premis:** pulau meredup karena **roh/makhluk cahaya (Lumi)** kabur & bersembunyi. Pemain mengumpulkan mereka kembali.
- Menang level → bintang. Bintang dipakai **memikat/membebaskan Lumi** di tiap area. Tiap Lumi yang kembali = sepotong cahaya pulau menyala lagi.
- **Album/koleksi:** tiap Lumi punya entri di album (nama, sedikit lore, rarity). Mengisi album = dorongan "gotta catch 'em all" → alasan balik tiap hari.
- Tiap area pulau selesai (semua Lumi-nya terkumpul) → buka **potongan cerita** + area baru (pantai → hutan → puncak, dll).
- Efek samping visual: area yang dulu redup jadi bercahaya seiring Lumi kembali (motif "redup → bercahaya" tetap, tapi hook-nya koleksi).
- **Kenapa koleksi > dekorasi:** dekorasi sudah jenuh; koleksi memberi tujuan jangka panjang yang jelas + cocok untuk daily/event + lebih murah diproduksi (varian Lumi via palet/bentuk).

### 6.1.1 Catatan: hindari mekanik gacha berbayar
- Lumi didapat dari **progress/skill** (bintang), BUKAN loot box berbayar acak. Jaga etika & kepatuhan (dok 06 §8).

### 6.2 Cerita ringan
- Karakter pemandu (maskot) yang punya tujuan/masalah → pemain "membantu".
- Narasi tipis, disampaikan lewat dialog pendek antar-area. Bukan novel.

### 6.3 Hadiah harian & retensi
- Daily reward (hari 1-7 streak).
- Kotak hadiah waktu (buka tiap X jam).
- (v1.x) Event lokal sederhana berbasis waktu device (tanpa server).

---

## 7. Ekonomi (Ringkas — detail di dok 06)

- **Koin:** dari menang level, hadiah, IAP. Untuk: booster, +langkah, beli nyawa.
- **Nyawa (5 max):** −1 tiap kalah, regen ~20-30 menit/nyawa. Refill via tunggu/iklan/koin/IAP.
- **Booster:** pre-level (mulai dgn special item) & in-level (palu, swap, +langkah).

---

## 8. Kurva Pengalaman Pemain — FTUE sebagai KURIKULUM (bukan cuma "level makin susah")

> Temuan KONVERGEN 3 review: 6 warna + 3 special + combo = kurva belajar curam. FTUE harus jadi **kurikulum** yang mengajarkan tiap konsep, bukan sekadar level mudah. Win-rate early WAJIB tinggi (lihat dok 05 §5.4).

| Level | Tujuan PEDAGOGIS | Warna | Target menang |
|---|---|---|---|
| 1-3 | Hanya swap dasar, board kecil, **auto-guided** (highlight swap benar). Menang <5 langkah. | 4 | 95%+ |
| 4-8 | Kenalkan **1 special per 2 level**. Beri situasi di mana special = satu-satunya cara menang (ajarkan value-nya). | 4 | 90%+ |
| 9-15 | **Combo** antar special. | 4-5 | 85-90% |
| 16-30 | **Rintangan pertama** (es, lalu box). Objektif baru. | 5 | 80-90% |
| 31-60 | Variasi meningkat, bottleneck, objective race. | 5-6 | 70-85% |
| 61-100 | Sesekali "spike" + hard near-miss. | 6 | 60-80% |
| 101+ | Generator (archetype) + ensemble solver + DDA. | subset | 45-70% |

> **Aturan emas:** pemain JANGAN ketemu mekanik baru (mis. Color Bomb) tanpa diajari dulu — kebingungan = uninstall. Tutorial **invisible** (highlight tile, bukan popup teks). Level 1-30 hand-crafted & dipoles sebagai kurikulum.

---

## 9. Game Feel / Juice (Wajib)

Checklist sensasi (diterapkan sejak prototipe special items):
- [ ] Suara unik tiap jenis match & special.
- [ ] Animasi tile hancur (scale + fade + partikel).
- [ ] Screen shake ringan saat ledakan besar.
- [ ] Haptic (getaran) saat combo/menang.
- [ ] "Juice" antisipasi: tile bergetar sebelum special meledak.
- [ ] Animasi reward menang yang memuaskan (koin terbang, bintang).
- [ ] Idle hint (tile berkedip) setelah ~5 detik diam.
- [ ] Transisi mulus antar layar (peta ↔ level ↔ meta).

---

## 10. Diferensiasi (anti "klon polos") — DIKUNCI (dok 11 D2, revisi pasca-review)

Diferensiator utama (fokus 1, bukan semua):
- **Meta KOLEKSI "Roh Cahaya (Lumi)" + tema pulau** (lihat §6.1). Hook = mengumpulkan makhluk cahaya & mengisi album, bukan dekorasi (yang sudah jenuh). Ini "elevator pitch" yang jelas: *"match-3 santai di mana kamu mengumpulkan roh cahaya untuk menghidupkan kembali pulau yang meredup."*
- **Polish & game feel** sebagai pembeda kualitas (juice, sound, haptic) — ini yang sebenarnya bikin pemain casual stay (temuan review).
- **1 signature mechanic (DITUNDA):** ditambahkan SETELAH core terbukti fun. Maks satu. Kandidat untuk dieksplorasi nanti: *color-mixing* (match 2 warna bersebelahan → tile campuran beragam efek). Jangan dibangun sebelum core fun.

> **Catatan revisi:** Art prosedural TIDAK lagi jadi diferensiator utama (temuan review: pemain casual tak peduli cara art dibuat; risiko visual dingin + berat di low-end). Prosedural turun jadi **lapisan aksen** (background, glow, partikel) — lihat dok 07. Pembeda nyata = hook koleksi + polish.
