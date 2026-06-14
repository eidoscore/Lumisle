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

#### 3.6.1 Anti-Frustration Timing Detail (+5 Langkah)
- **Kapan muncul:** TEPAT saat `moves_left == 0` dan objektif belum lengkap → popup "+5 Langkah?" muncul **sebelum** layar kalah. Jangan tunda animasi.
- **Biaya per penawaran:**
  - Penawaran ke-1: nonton rewarded ad (gratis) ATAU 80 koin.
  - Penawaran ke-2 (jika pemain gagal lagi dengan +5): 160 koin (tidak ada opsi iklan lagi).
  - Penawaran ke-3+: TIDAK ada penawaran lagi sesi itu (tutup popup → fail screen).
- **Maks penawaran:** 2× per level per sesi (tidak bisa terus beli langkah tanpa batas).
- **Waktu berpikir:** popup tidak punya countdown timer (jangan buru-buru pemain saat momen kritis).
- **Near-miss display:** saat popup muncul, tampilkan info singkat: "Kurang [N] lagi!" (sisa tile/obstacle) → buat pemain tahu kemenangan terasa "sangat dekat".

#### 3.6.2 Move Counter Warning System
- **≤5 langkah tersisa:** counter langkah berubah warna ke **kuning/oranye** + pulse animation setiap langkah.
- **≤3 langkah tersisa:** counter berubah **merah** + pulse lebih cepat + suara tick ringan setiap langkah.
- **Langkah terakhir (1):** screen vignette merah tipis di tepi layar (subtle, tidak menghalangi gameplay).
- Tujuan: beri urgensi tanpa panik berlebihan. Pemain harus *tahu* waktu hampir habis.

### 3.7 Dead-board & Reshuffle
- Kalau tidak ada lagi swap yang menghasilkan match → papan **otomatis diacak ulang** (animasi reshuffle).
- **Default: reshuffle GRATIS** (tidak mengurangi langkah) — board mentok bukan salah pemain (keputusan D16, dok 11).
- Solver memodelkan reshuffle identik dengan game (lihat dok 04 §3.9).

### 3.7 Hint System Design
- **Trigger:** idle (tidak ada input pemain) selama **5 detik** → hint aktif.
- **Prioritas hint** (urut, pilih satu):
  1. Move yang menciptakan **special item** (match-4/5/L/T) → prioritas tertinggi.
  2. Move yang **mengenai obstacle** objektif (clearing obstacle terdekat).
  3. Move yang memenuhi **tile objektif** terbanyak dalam satu langkah.
  4. Move valid **acak** (fallback jika tidak ada yang lebih baik).
- **Visual hint:** dua tile yang akan di-swap berkedip bergantian + glow lembut + partikel sparkle kecil. Tidak ada teks atau panah.
- **Setelah 10 detik** idle: hint lebih intens (pulse lebih cepat). Setelah 20 detik: tampilkan lagi hint (bisa pindah ke move baru jika board berubah).
- **Tutorial level (L1-L5):** hint langsung muncul **tanpa delay** di awal level, menunjuk swap pertama yang benar.
- Solver pakai logika hint yang sama (deterministik via `find_best_hint_move()` di `board.gd`).

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

### 6.0 Sistem Bintang (Star System) — DIKUNCI

**1 bintang per level, binary (menang = dapat 1 bintang; kalah = tidak dapat).**
- Bukan sistem 1-3 bintang berbasis skor (CC versi lama). Alasan: lebih sederhana, tidak membebani pemain dengan "harus perfect", konsisten dengan desain modern (Royal Match model).
- Menang level pertama kali → 1 bintang. **Replay level tidak memberi bintang ekstra** (sudah dapat 1, batas per level).
- Bintang **permanen** (tidak hilang), disimpan di save data.
- Bintang dipakai **khusus** untuk membebaskan Lumi di meta. Bukan mata uang untuk beli barang lain.
- HUD level menampilkan counter bintang total yang dimiliki (terlihat motivasi).

### 6.1 Konsep utama: "Koleksi Roh Cahaya Pulau" (DIKUNCI — dok 11 D2)
Hook meta = **KOLEKSI**, bukan dekorasi (membedakan dari Gardenscapes/Matchington yang sudah pakai "restore a place").
- **Premis:** pulau meredup karena **roh/makhluk cahaya (Lumi)** kabur & bersembunyi. Pemain mengumpulkan mereka kembali.
- Menang level → bintang. Bintang dipakai **memikat/membebaskan Lumi** di tiap area. Tiap Lumi yang kembali = sepotong cahaya pulau menyala lagi.
- **Album/koleksi:** tiap Lumi punya entri di album (nama, sedikit lore, rarity). Mengisi album = dorongan "gotta catch 'em all" → alasan balik tiap hari.
- Tiap area pulau selesai (semua Lumi-nya terkumpul) → buka **potongan cerita** + area baru (pantai → hutan → puncak, dll).
- Efek samping visual: area yang dulu redup jadi bercahaya seiring Lumi kembali (motif "redup → bercahaya" tetap, tapi hook-nya koleksi).
- **Kenapa koleksi > dekorasi:** dekorasi sudah jenuh; koleksi memberi tujuan jangka panjang yang jelas + cocok untuk daily/event + lebih murah diproduksi (varian Lumi via palet/bentuk).

#### 6.1.1 Struktur Area & Lumi (v1 — spesifik)

**v1: 3 area, masing-masing 6 Lumi = 18 Lumi total.**

| Area | Nama | Level yang unlock | Lumi | Tema visual |
|---|---|---|---|---|
| 1 | Pesisir Lumira | Level 1-30 | 6 Lumi | Pantai, karang, laut dangkal |
| 2 | Hutan Cahaya | Level 31-70 | 6 Lumi | Hutan, jamur bercahaya, sungai |
| 3 | Puncak Bintang | Level 71-100+ | 6 Lumi | Pegunungan, langit malam, kristal |

**Biaya bintang per Lumi (tiap area):**

| Lumi ke- | Biaya bintang | Keterangan |
|---|---|---|
| 1 | 3 bintang | Hampir langsung dapat (level 3) |
| 2 | 5 bintang | Setelah ~5 level |
| 3 | 8 bintang | Mid area |
| 4 | 12 bintang | Terasa butuh effort |
| 5 | 16 bintang | Rare feel |
| 6 | 20 bintang | "Boss" area — butuh semua level di area |
| **Total/area** | **64 bintang** | ~64 level untuk selesaikan 1 area penuh |

> Angka ini bisa di-tweak berdasar playtest. Prinsip: tiap 5-8 level seharusnya ada Lumi baru, jaga momentum.

**Rarity Lumi per area:**
- 4 Lumi **Common** (warna solid, desain simpel).
- 1 Lumi **Rare** (warna dua-tone, glow lebih terang, lore lebih panjang).
- 1 Lumi **Epic** (warna gradient, animasi idle unik, lore paling dalam — "boss" Lumi area).
- Rarity tidak mempengaruhi gameplay, hanya visual & lore (jaga etika, hindari rasa pay-to-win).

**Album UI:**
- Grid 6 slot per area. Slot terkunci = silhouette abu-abu gelap dengan gembok ikon.
- Saat dibebaskan: animasi Lumi "terbang masuk" ke slot → area pulau menyala sedikit.
- Tap Lumi → lihat nama, lore singkat (2-3 kalimat), rarity badge.
- Progress bar bintang terlihat: "X / Y bintang" menuju Lumi berikutnya.

### 6.1.1 Catatan: hindari mekanik gacha berbayar
- Lumi didapat dari **progress/skill** (bintang), BUKAN loot box berbayar acak. Jaga etika & kepatuhan (dok 06 §8).

### 6.2 Cerita ringan
- Karakter pemandu (maskot) yang punya tujuan/masalah → pemain "membantu".
- Narasi tipis, disampaikan lewat dialog pendek antar-area. Bukan novel.

### 6.3 Hadiah Harian & Retensi (Detail)

#### 6.3.1 Daily Reward (Login Streak)
Kalender 7 hari bergulir. Membuka game setelah 00:00 device time = hari baru.

| Hari | Reward |
|---|---|
| 1 | 30 koin |
| 2 | 1 Nyawa |
| 3 | 60 koin + 1 booster Palu |
| 4 | 2 Nyawa |
| 5 | 100 koin |
| 6 | 1 booster Roket pre-level |
| 7 | **180 koin + 2 booster pilihan** (reward paling besar, dorong streak) |

**Aturan streak:**
- Lewat 1 hari (tidak login) → streak **RESET ke hari 1** (bukan dilanjutkan, bukan difreeze).
- Mengapa reset: memberi urgensi untuk balik tiap hari (mekanik retensi standar industri).
- Visual: kalender mini tampil di popup saat buka game (setelah FTUE selesai, mulai level 5).
- Popup auto-dismiss setelah 3 detik atau tap anywhere.

#### 6.3.2 Kotak Hadiah Waktu
- Kotak gratis: muncul tiap **4 jam**. Harus diklaim manual (tidak auto-collect).
- Isi: 20-50 koin, atau 1 nyawa, atau 1 booster kecil (random dengan bobot).
- Maks 2 kotak antri (supaya tidak menumpuk → tetap ada alasan sering buka game).
- Notifikasi push saat kotak siap (lihat §13).

#### 6.3.3 Comeback Reward (FR-M07)
- **Trigger:** pemain tidak buka game selama **7+ hari** (cek via timestamp `last_session_end`).
- **Reward saat kembali:** popup khusus "Selamat datang kembali! Para Lumi merindukan kamu!" + 5 nyawa penuh + 150 koin + 2 booster acak.
- **Tampilan:** Lumi di popup kelihatan sedih/melambaikan tangan → setelah diklaim, mereka senang. Narasi emosional = koneksi ke meta.
- **Frekuensi:** maks 1× per 7 hari (tidak bisa trigger dua kali dalam seminggu).
- Catat event `comeback` ke analytics (lihat dok 09 §7).

---

## 7. Ekonomi (Ringkas — detail di dok 06)

- **Koin:** dari menang level, hadiah, IAP. Untuk: booster, +langkah, beli nyawa.
- **Nyawa (5 max):** −1 tiap kalah, regen ~20-30 menit/nyawa. Refill via tunggu/iklan/koin/IAP.
- **Booster:** pre-level (mulai dgn special item) & in-level (palu, swap, +langkah).

---

## 8. Kurva Pengalaman Pemain — FTUE sebagai KURIKULUM (bukan cuma "level makin susah")

### 8.0 FTUE Tutorial Mechanic Detail (cara kerjanya secara teknis)

**Tujuan:** pemain belajar tanpa popup teks. "Tutorial invisible."

**Implementasi per level tutorial (L1-L5):**

| Mekanik | Cara kerja |
|---|---|
| **Highlight swap** | Dua tile yang harus di-swap: pulse animation (scale 1.0→1.1, loop) + glow effect. Tile lain di-dim (alpha 0.5). |
| **Input blocking** | Swap yang melibatkan tile NON-highlighted: **diblokir secara code** (tidak dikonsumsi, tidak mengurangi langkah). Ini **bukan** punishment — pemain cukup tidak bisa salah. |
| **Immediate hint** | Tidak ada idle timeout di tutorial; hint muncul **1 detik** setelah level dimuat. |
| **Teks overlay minimal** | Hanya L1: satu baris teks "Geser tile warna yang sama!" (atau teks ID/EN) muncul 2 detik lalu fade. Setelahnya tidak ada teks lagi. |
| **Guaranteed-win via spawn_pattern** | Level 1-3: field `spawn_pattern` di LevelDefinition mengisi board dengan susunan yang **dipastikan menang dalam ≤ N langkah jika swap highlighted dilakukan**. Board random tidak digunakan untuk L1-L3. |
| **Tutorial flag** | `LevelDefinition.hand_crafted = true` + field baru `tutorial_forced_swaps: Array[Vector2i]` (urutan swap yang harus diperlihatkan). Board view membaca field ini untuk menentukan apa yang di-highlight per langkah. |

**Kapan tutorial selesai:** setelah L5 selesai, flag `tutorial_complete` di-set di save data → input blocking dan immediate hint dihapus dari loop → game berjalan normal.

**Hal yang DILARANG di tutorial:**
- Popup teks berulang yang memblokir layar.
- Menerangkan combo atau special sebelum pemain melihatnya terjadi.
- Level yang tidak bisa dimenangkan dengan cara yang diajarkan hint.

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

### 9.1 Remaining Moves Celebration — "Lumi Burst" ⭐ (WAJIB, v1)

> Ini momen paling satisfying dalam match-3. Ketika semua objektif selesai dengan sisa langkah, sisa langkah itu "dimainkan otomatis" sebagai hadiah. Royal Match menyebutnya "Royal Bonus", Candy Crush menyebutnya "Sugar Crush". **Lumisle menyebutnya "Lumi Burst".**

**Trigger:** `LevelWon` terjadi DAN `moves_left > 0`.

**Urutan Lumi Burst:**
1. Semua input diblokir (pemain hanya nonton).
2. Tampilkan teks animasi "Lumi Burst!" di tengah layar (2-3 detik).
3. Untuk setiap sisa langkah (`moves_left` kali):
   - **Konversi 1 langkah:** 1 tile acak di papan berubah jadi special item (Roket/Bom/ColorBomb — dipilih via `GameRNG`, bias ke ColorBomb makin banyak sisa langkah).
   - Special langsung meledak → cascade → score.
   - Animasi & suara penuh (sama seperti manual trigger, tapi lebih cepat — interval 0.5 detik antar step, bukan 1 detik).
4. Setelah semua sisa langkah habis → papan settle → **Win Screen** muncul.

**Mengapa penting:**
- Membuat "menang efisien" terasa menyesal (ngapain buru-buru? buang-buang bonus).
- Sebaliknya, menang dengan sisa 10+ langkah terasa sangat memuaskan (cascade panjang + skor besar).
- Mendorong pemain untuk lebih strategis (sisakan langkah lebih banyak) tanpa membuat level lebih mudah.
- Skor yang didapat dari Lumi Burst → **dikonversi ke koin** (bukan bintang) di Win Screen: skor /10 = koin bonus.

**Implementasi:** Lumi Burst adalah **extended TurnReport** — generated oleh `board.gd` setelah `LevelWon` dengan parameter `remaining_moves`, bukan logika baru. Solver tidak perlu memodelkan ini (tidak relevan untuk win-rate validation).

**Edge case:** jika `moves_left == 0` saat menang → langsung ke Win Screen (tidak ada Lumi Burst). Menang pas = tetap menang, tapi tidak ada bonus show.

### 9.2 Cascade Juice Escalation

Setiap gelombang cascade (bukan turn baru, tapi chain dalam satu turn) → juice naik:

| Cascade ke- | Suara SFX pitch | Partikel | Screen shake |
|---|---|---|---|
| 1 (base) | ×1.0 | normal | none |
| 2 | ×1.1 | +20% partikel | ×0.3 |
| 3 | ×1.2 | +50% partikel | ×0.5 |
| 4 | ×1.3 | +80% partikel | ×0.7 |
| 5+ | ×1.4 (cap) | max partikel (cap 20) | ×1.0 (cap) |

Cascade ke-3+ → tampilkan **cascade counter** pop-up di pojok ("Combo x3!") dengan animasi bounce in/out.

Match pitch escalation (dalam satu giliran, bukan cascade):
- Match-3 = pitch ×1.0
- Match-4 = pitch ×1.15 + special spawn sound
- Match-5+ = pitch ×1.3 + special spawn sound lebih megah

### 9.3 Haptic Pattern Spec (Android)
| Momen | Pattern |
|---|---|
| Match-3 normal | Short tap (50ms) |
| Match-4/special spawn | Double tap (50ms-50ms) |
| Special ledak | Strong (100ms) |
| Combo (2 special) | Strong + pulse (100ms-50ms-100ms) |
| Lumi Burst | Long vibration 200ms |
| Menang level | 3× pulse (100ms-100ms-100ms) |
| Kalah level | Long sad (150ms) |

Implementasi via `DisplayServer.vibrate_handheld()` (Godot 4).

---

## 10. Layar Utama (Screen Design)

### 10.1 Pre-Level Screen
Muncul setelah tap level di peta. **Bukan full-screen** — overlay panel dari bawah (sheet) di atas level map.

**Konten:**
- Level number + nama archetype (jika hand-crafted: nama custom; jika generated: nama archetype "Bottleneck", "Combo Playground", dll).
- Semua objektif ditampilkan dengan ikon + angka target (mis. ikon es + "×15 Es", ikon merah + "×30 Merah").
- Batas langkah (move limit): ikon kaki/langkah + angka.
- **3 slot booster pre-level** (horizontal): setiap slot bisa drag/tap untuk aktifkan booster. Booster yang dipilih akan ada di board saat mulai. Jika stok booster = 0 → slot abu-abu dengan harga koin.
- Tombol **"Main!"** (warna cerah, besar).
- Tombol **"✕"** (kembali ke peta).

**Informasi yang TIDAK ada di sini:** tips/panduan, preview board (v1), peta progress area.

### 10.2 Win Screen

**Urutan animasi (berurutan, tidak semua sekaligus):**
1. **Lumi Burst selesai** → papan fade out.
2. Panel Win muncul dari bawah (slide up).
3. **Animasi bintang** (1 bintang terbang dari pusat panel ke counter bintang total) + SFX fanfare. Durasi: 0.8 detik.
4. **Counter koin bonus** — koin dari Lumi Burst count up (0 → X) dengan suara koin.
5. **Progress Lumi** — jika bintang yang didapat sekarang mengisi bar dan membebaskan Lumi baru → **Lumi reveal animation** (Lumi muncul dari cahaya, nama muncul) + musik fanfare khusus. Ini momen paling megah.
6. Panel stabil → tampilkan tombol.

**Tombol di Win Screen:**
- **"Level Berikutnya"** (utama, besar) — langsung mulai level selanjutnya.
- **"✕"** (kembali ke peta) — kecil, pojok.
- Tidak ada tombol "Replay" (tidak perlu; replay via peta).

**Informasi:**
- "Level [N] Selesai!" header.
- Bintang yang didapat (1 bintang + animasi).
- Koin bonus dari Lumi Burst.
- Progress bar bintang → Lumi berikutnya (menunjukkan "butuh X bintang lagi untuk Lumi baru").

### 10.3 Fail Screen

**Flow:** `moves_left == 0` & objektif belum selesai → **JANGAN langsung ke fail screen.** Tampilkan dahulu intercept popup "+5 Langkah?" (§3.6.1). Jika ditolak/timeout → baru fail screen.

**Konten fail screen:**
- Header: "Hampir! 😮" (bukan "Gagal!" — anti-frustrasi, framing positif).
- Info near-miss: "Kamu butuh [N] tile [warna] lagi." atau "Tinggal [N] es yang harus dihancurkan." — buat pemain tahu kemenangan sangat dekat.
- **Tombol utama: "Coba Lagi"** (langsung restart level).
- **Tombol sekunder: "Kembali ke Peta"** (lebih kecil).
- Jika penawaran +5 langkah belum habis (masih ada 1 penawaran tersisa) → tampilkan juga tombol "+5 Langkah" di fail screen sebagai secondary CTA.

**Yang TIDAK dilakukan:** jangan tampilkan iklan interstitial setelah fail screen (per aturan dok 06 §5.2).

### 10.4 Level Map Screen

**Design:**
- Scroll vertikal (atas ke bawah = level makin tinggi angkanya), dari kiri ke kanan bergantian (zigzag path).
- Setiap node level memiliki 3 state visual:
  - **Terkunci (belum dibuka):** tile abu-abu gelap + ikon gembok.
  - **Sudah diselesaikan:** tile bercahaya + bintang kecil di pojok.
  - **Level aktif berikutnya:** tile lebih besar, pulse animation, ikon "tombol play".
- Path antar level: garis jalan/lintasan yang bercahaya progressively seiring unlock.
- **Landmark area:** di setiap awal area baru (L1, L31, L71), ada ilustrasi kecil landmark area (karang, pohon, kristal).
- Tap level yang sudah selesai → buka pre-level screen (boleh replay tapi tidak bisa dapat bintang ekstra).
- **Header:** ikon bintang total + tombol ke Meta Screen (album Lumi).

## 11. Strategi Notifikasi Push

> Notifikasi = salah satu driver retensi terkuat untuk casual game. Tapi terlalu banyak = uninstall. Prinsip: **sedikit, relevan, bernilai.**

**v1: 3 notifikasi push yang diimplementasi:**

| Notif | Trigger | Teks (contoh, EN) | Timing |
|---|---|---|---|
| **Nyawa penuh** | Lives mencapai 5 dari <5 | "Your Lumis have missed you! Full hearts ready 💛" | Tepat saat nyawa ke-5 regen selesai |
| **Kotak hadiah siap** | Treasure chest ready | "A glowing gift is waiting on the island! 🎁" | Saat kotak 4 jam siap |
| **Comeback** | 3 hari tidak buka game | "The island is growing dim... Come back and save the Lumis! ✨" | Exactly 72 jam setelah `last_session_end` |

**Yang TIDAK diimplementasi v1:** notif daily reward (terlalu agresif jika combined dengan notif lain), notif per event (berlebihan).

**Permission request:** minta permission notifikasi **setelah** pemain menang level pertama (bukan saat buka pertama kali — terlalu awal, rejection rate tinggi).

**Implementasi Godot:** belum ada plugin notif push native Godot 4 yang stabil. Opsi: **Firebase Cloud Messaging via Godot Android plugin** atau **local notification plugin** (untuk nyawa penuh & kotak yang bisa dihitung dengan timestamp lokal). Local notification lebih mudah dan tidak butuh server untuk v1.

## 12. App Rating Prompt

**Timing terbaik:** setelah pemain menang level **ke-12** (sudah cukup invested, tapi tidak terlalu terlambat) **DAN** tidak pernah diminta sebelumnya.

**Syarat tambahan:** pemain tidak baru kalah 3× berturut-turut sebelumnya (jangan minta rating saat frustrasi).

**Implementasi:** pakai **Google Play In-App Review API** via plugin Android. Tidak perlu custom dialog — API native yang handle tampilan.

**Frekuensi:** maks 1× per install. Tidak pernah minta ulang (API Play sudah limit-kan ini di sisi mereka juga).

## 13. Collectible (Bring-Down) Mechanics Detail

Jenis objective `bring_down`: item khusus (kunci, kristal, dll) harus **diturunkan ke baris paling bawah** papan.

**Perilaku:**
- Item collectible diperlakukan sebagai **tile khusus** di board (non-color, tidak bisa di-match). Ia **tidak bisa di-swap** langsung.
- Item turun mengikuti gravity normal — ketika tile di bawahnya dikosongkan (oleh match atau special), item jatuh.
- **Tidak bisa di-match atau di-hapus** (kecuali oleh special yang target area-nya mengenai cell-nya — dalam kasus itu, item ter-**deliver** langsung ke bawah, bukan hancur).
- Saat mencapai **baris paling bawah** → event `ItemDelivered` → objective counter decrement → item menghilang dengan animasi sparkle.
- **Level design note:** letakkan collectible di baris atas/tengah; desain path clear-an agar pemain punya kendali untuk mengarahkan item turun.
- **Visual:** ikon unik per jenis collectible (kunci emas, kristal biru, dll). Ada "trail" saat jatuh (partikel ringan) supaya pemain mudah tracking posisinya.

## 15. Diferensiasi (anti "klon polos") — DIKUNCI (dok 11 D2, revisi pasca-review)

Diferensiator utama (fokus 1, bukan semua):
- **Meta KOLEKSI "Roh Cahaya (Lumi)" + tema pulau** (lihat §6.1). Hook = mengumpulkan makhluk cahaya & mengisi album, bukan dekorasi (yang sudah jenuh). Ini "elevator pitch" yang jelas: *"match-3 santai di mana kamu mengumpulkan roh cahaya untuk menghidupkan kembali pulau yang meredup."*
- **Polish & game feel** sebagai pembeda kualitas (juice, sound, haptic) — ini yang sebenarnya bikin pemain casual stay (temuan review).
- **1 signature mechanic (DITUNDA):** ditambahkan SETELAH core terbukti fun. Maks satu. Kandidat untuk dieksplorasi nanti: *color-mixing* (match 2 warna bersebelahan → tile campuran beragam efek). Jangan dibangun sebelum core fun.

> **Catatan revisi:** Art prosedural TIDAK lagi jadi diferensiator utama (temuan review: pemain casual tak peduli cara art dibuat; risiko visual dingin + berat di low-end). Prosedural turun jadi **lapisan aksen** (background, glow, partikel) — lihat dok 07. Pembeda nyata = hook koleksi + polish.
