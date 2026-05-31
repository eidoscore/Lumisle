# 07 — Art & Audio Direction

> Bottleneck terbesar proyek ini BUKAN kode, tapi art & game feel. Dokumen ini bantu lu rencanakan aset.

---

## 1. Kenapa Dokumen Ini Penting

Logika match-3 itu "solved" (AI bisa bangun). Yang bikin game laku & terasa premium adalah **visual + suara + rasa**. Ini area di mana **lu (director) paling berperan**, dan paling sering jadi penghambat solo dev. Rencanakan dari awal.

---

## 2. Arah Visual (DIKUNCI — revisi pasca-review, lihat dok 11 D1/D2)

> **Tema: Pulau fiksi imajinatif. Strategi art: ASET CC0 sebagai fondasi (terutama tile gameplay & UI) + PROSEDURAL sebagai lapisan aksen (background, glow, partikel).**

### 2.0 Strategi Art 2 Lapis (no budget) — REVISI
**Perubahan penting (temuan review):** art prosedural diturunkan dari "identitas utama" jadi "aksen". Alasan: pemain casual tidak peduli cara art dibuat — mereka butuh **clarity, familiarity, juice**. Art prosedural berisiko terlihat dingin/tech-demo, kurang terbaca di layar kecil, dan berat di Android low-end (pasar SEA). ROI-nya kalah jauh dibanding CC0 + juice yang dipoles.

1. **Aset CC0 (FONDASI):** **tile gameplay** (wajib jelas & terbaca 0.5 detik), special items, UI, meta/Lumi, audio → dari OpenGameArt/Kenney/Ponywolf (dok 11 D7).
2. **Prosedural (AKSEN, bukan fondasi):** background pulau, efek glow "redup→bercahaya", partikel/trail, transisi → shader/noise (`FastNoiseLite`)/gradient. Murah, kasih sentuhan identitas, tapi TIDAK menyentuh keterbacaan gameplay.

> **Aturan emas:** apa pun yang harus dibaca cepat oleh pemain (tile, ikon objektif) = aset jelas, BUKAN prosedural. Prosedural hanya untuk latar & "bumbu".

### 2.0.1 Di mana ROI sebenarnya (prioritas effort)
Investasikan waktu di sini, BUKAN di shader:
- **Color grading konsisten** — palet 6 warna harmonis (mis. via coolors.co).
- **Particle effects generous** — sparkle, trail, ledakan via **`CPUParticles2D` + pooling** (GL Compatibility TIDAK support `GPUParticles2D` — lihat dok 04 §13). Alternatif murah: sprite-sheet flipbook.
- **Screen shake + haptic dengan timing tepat.**
- **Sound design memuaskan** (≈50% dari "feel").

### 2.0.2 Art style
- **Flat / clean dengan glow lembut**, estetika "gem/crystal cahaya" yang konsisten dengan tema pulau & Lumi.
- Konsisten antara aset CC0 (di-recolor agar satu palet) + aksen prosedural.

### 2.1 Prinsip
- **Bersih & terbaca.** Tile besar, kontras tinggi, mudah dibedakan sekejap (Royal Match pakai puzzle pieces besar & distinctive).
- **Ceria & ramah.** Warna hangat, bentuk membulat, ekspresif. Cocok untuk relaksasi.
- **Universal.** Hindari gaya yang cuma nyangkut di 1 region — biar bisa scale global.
- **Konsisten.** Satu palet & satu style sheet untuk seluruh game.

### 2.2 Komponen visual yang dibutuhkan
| Aset | Keterangan | Prioritas |
|---|---|---|
| Tile set (4-6 warna) | Tiap warna bentuk/ikon berbeda (aksesibilitas) | Must |
| Special items (roket, bom, colorbomb, propeller) | Versi statis + animasi | Must |
| Efek (ledakan, partikel, kilau) | Untuk juice | Must |
| Rintangan (es, box, dll) | Visual + animasi pecah | Must |
| Background papan | 1-beberapa tema | Must |
| UI kit (tombol, panel, popup, ikon) | Konsisten | Must |
| Peta level | Node level + jalur | Should |
| Meta scene (area bangun/renovasi) | Aset per area + state "sebelum/sesudah" | Should |
| Karakter/maskot | Pose & ekspresi dasar | Should |
| Ikon app & store assets | Feature graphic, screenshot | Must (rilis) |

### 2.3 Aksesibilitas warna (WAJIB)
- Tiap tile warna HARUS punya **bentuk/ikon unik** (bukan cuma beda warna) → pemain buta warna tetap bisa main.
- Kontras teks vs background memenuhi standar keterbacaan.
- Catatan: kepatuhan aksesibilitas penuh perlu pengujian manual dengan pengguna/alat bantu.

---

## 3. Sumber Aset (Strategi Solo Dev)

Lu gak harus bikin semua dari nol. Opsi (urut dari paling hemat):

| Sumber | Pro | Kontra |
|---|---|---|
| **Aset gratis** (Kenney.nl, OpenGameArt, itch.io free) | Gratis, cepat | Generik, banyak yang pakai |
| **Asset store berbayar** (itch.io, Unity Asset Store yang portable, GraphicRiver) | Murah, kualitas ok | Perlu lisensi cek |
| **AI-generated art** (Midjourney, dll) + editing | Cepat, custom | Konsistensi & lisensi perlu hati-hati; perlu kurasi |
| **Freelancer/komisi** (Fiverr, Upwork) | Custom, profesional | Biaya, waktu |
| **Bikin sendiri** | Kontrol penuh, identitas | Butuh skill & waktu |

> **Rekomendasi:** Untuk prototipe & MVP → aset gratis/placeholder. Untuk rilis → upgrade ke aset berbayar/komisi/AI-curated yang konsisten. Jangan habiskan uang art sebelum core terbukti fun.

### 3.1 Catatan lisensi (penting)
- Cek lisensi tiap aset (CC0 paling aman; CC-BY butuh atribusi; cek penggunaan komersial).
- Simpan catatan lisensi semua aset di file terpisah (`ASSETS_LICENSES.md`) untuk audit.
- Aset AI: pahami ketentuan layanan untuk penggunaan komersial.

---

## 4. Arah Audio

### 4.1 Prinsip
- **Suara = 50% dari "rasa puas".** Match-3 hidup dari feedback audio.
- Lembut & memuaskan, tidak mengganggu (orang main untuk relaksasi).
- Bisa dimainkan tanpa suara (banyak yang main mute) — tapi dengan suara harus terasa jauh lebih enak.

### 4.2 Aset audio yang dibutuhkan
| Aset | Keterangan | Prioritas |
|---|---|---|
| SFX match (3/4/5) | Naik pitch makin besar match | Must |
| SFX special & combo | Megah, memuaskan | Must |
| SFX UI (tap, menang, kalah, koin) | Ringan | Must |
| Musik latar | Loop tenang, 1-2 track + variasi meta | Should |
| Haptic patterns | Getaran (Android) untuk combo/menang | Should |

### 4.3 Sumber audio
- Gratis: Freesound (cek lisensi), OpenGameArt, Kenney audio.
- Berbayar: Soundsnap, asset store.
- AI audio generation untuk SFX/musik (cek lisensi komersial).

---

## 5. Game Feel / Juice Checklist (lintas dok dengan GDD)

Sejak prototipe special items:
- [ ] Tile hancur: scale-down + fade + partikel.
- [ ] Special meledak: flash + shake ringan + suara megah.
- [ ] Combo: efek lebih besar + haptic.
- [ ] Tile jatuh: easing (bounce ringan) — terasa "berbobot".
- [ ] Antisipasi: special bergetar sebelum meledak.
- [ ] Menang: koin/bintang terbang ke counter, fanfare.
- [ ] Idle hint: tile berkedip setelah ~5 detik.
- [ ] Transisi layar mulus (tween).

> Juice murah secara teknis tapi mahal secara "perhatian". Ini yang membedakan game terasa amatir vs premium.

---

## 6. Tema (DIKUNCI — dok 11 D1)

**Tema final: Pulau fiksi imajinatif** dengan estetika cahaya/glow + koleksi "Lumi" (roh cahaya).

- **Meta (hook = KOLEKSI, bukan dekorasi):** pemain mengumpulkan kembali **Lumi** (roh cahaya) yang kabur saat pulau meredup; tiap Lumi yang kembali menyalakan sepotong pulau. Detail di GDD §6.1.
- **Identitas pembeda:** hook koleksi + polish/game-feel (BUKAN art prosedural — lihat revisi §2.0).
- **Cerita ringan:** maskot pemandu yang mengajak pemain menyelamatkan para Lumi & menghidupkan kembali pulau.

### Catatan produksi tema
- **Varian Lumi murah diproduksi:** beda warna/bentuk/glow dari basis yang sama (CC0 di-recolor + aksen partikel prosedural).
- State "redup → bercahaya" via aksen prosedural (glow/gradient) memudahkan progress terlihat memuaskan tanpa banyak aset manual.

