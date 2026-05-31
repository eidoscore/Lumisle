# 06 — Ekonomi & Monetisasi

> Gimana game menjaga pacing (ekonomi) dan menghasilkan uang (monetisasi), tanpa bikin pemain kabur.

---

## 1. Filosofi

- **Iklan dulu, IAP belakangan.** Mayoritas pemain (apalagi di SEA) tidak bayar; nilai mereka datang dari iklan. IAP untuk minoritas yang mau.
- **Reward, bukan paksaan.** Iklan terbaik adalah yang pemain PILIH (rewarded). Hindari iklan yang bikin uninstall.
- **Anti-frustrasi tetap nomor 1.** Monetisasi tidak boleh terasa seperti "tembok bayar". Royal Match menang justru karena monetisasinya halus.

---

## 2. Mata Uang & Resource

| Resource | Dapat dari | Dipakai untuk |
|---|---|---|
| **Koin** | Menang level, hadiah harian, buka kotak, IAP | Beli booster, +langkah, beli nyawa, refill |
| **Nyawa (Lives)** | Regen waktu, hadiah, iklan, koin, IAP | Main level (−1 saat kalah) |
| **Bintang** | Menang level | Progress meta (koleksi Lumi) — BUKAN mata uang beli |
| **Booster** | Hadiah, beli pakai koin, IAP | Bantu menyelesaikan level |

> **Penting:** Bintang bukan currency yang bisa dibeli. Bintang murni dari skill/progress → menjaga rasa "pencapaian" di meta.

---

## 3. Sistem Nyawa (Lives) — DIKUNCI (dok 11 D4)

- Maksimum **5 nyawa**.
- Kalah level → **−1 nyawa**. Menang → tidak berkurang.
- Regen: **1 nyawa / 25 menit**.
- Saat habis, pemain bisa:
  - Tunggu regen (gratis).
  - Nonton **rewarded ad** → +1 nyawa. **Cap: maks 5 nyawa/hari dari iklan** (anti-abuse).
  - Bayar koin → refill.
  - IAP → refill penuh / unlimited sementara.
- **Tujuan:** pacing sehat (istirahat alami) + titik monetisasi lembut.

> Catatan: nyawa klasik bisa terasa menghukum bila terlalu ketat. Mitigasi via anti-frustrasi (tawaran +langkah sebelum benar-benar kalah) + DDA. Pantau lewat analytics: apakah nyawa jadi titik churn. Kalau ya, longgarkan (regen lebih cepat / nyawa awal lebih banyak).

---

## 4. Booster

### Pre-level (dipilih sebelum mulai)
- Mulai dengan 1 special item di papan (roket/bom/colorbomb).
- Tambah langkah awal.

### In-level (dipakai saat main)
- **Palu:** hancurkan 1 tile/rintangan.
- **Swap bebas:** tukar 2 tile mana saja.
- **+Langkah:** tambah langkah saat hampir kalah.

Sumber booster: hadiah harian, reward, beli koin, rewarded ad, IAP.

---

## 5. Monetisasi: Iklan (IAA)

### 5.1 Format & penempatan
| Format | Kapan | Aturan |
|---|---|---|
| **Rewarded video** | Pemain pilih: +nyawa, +langkah (saat hampir kalah), double reward, buka hint, klaim hadiah ekstra | Selalu opt-in. Ini prioritas #1 |
| **Interstitial** | Antar level (bukan tiap level) | Frequency cap: mis. 1 per 2-3 menit ATAU tiap 3 level. JANGAN setelah kekalahan pertama |
| **Banner** | Opsional di menu/peta (bukan saat main) | Revenue kecil; bisa di-skip kalau ganggu UX |

### 5.2 Aturan emas iklan
- **JANGAN** interstitial saat pemain baru kalah (momen sensitif → uninstall).
- **JANGAN** iklan di tengah gameplay aktif.
- Rewarded harus memberi nilai jelas & adil.
- Hormati "Remove Ads" (interstitial & banner hilang; rewarded boleh tetap opsional).

### 5.3 Mediation
- Mulai **AdMob** (paling mudah diintegrasi di Godot Android).
- Nanti pertimbangkan **AppLovin MAX** / **Unity LevelPlay** untuk eCPM lebih baik via mediation.

---

## 6. Monetisasi: IAP

| Produk | Tipe | Harga (provisional) | Catatan |
|---|---|---|---|
| **Remove Ads** | Non-consumable | ~$2.99 | Produk terlaris di casual. WAJIB ada |
| Paket koin kecil/sedang/besar | Consumable | $0.99 / $4.99 / $9.99 | Untuk yang mau progress cepat |
| Starter pack | Consumable (sekali) | ~$1.99 | Nilai tinggi, konversi pemain baru |
| Piggy bank | Consumable | variabel | Kumpulkan koin saat main, "pecah" dgn bayar |
| (v1.x) Season pass offline | Consumable berkala | ~$4.99-9.99 | Hanya jika retensi terbukti |

> Harga final disesuaikan per region (Play Store mendukung local pricing). Indonesia: pertimbangkan harga psikologis lokal.

---

## 7. Ekonomi Sehat (Prinsip Balancing)

- **Sumber koin** (faucet) vs **pengeluaran koin** (sink) harus seimbang.
  - Faucet: reward level, harian, kotak, iklan.
  - Sink: booster, +langkah, refill nyawa.
- Pemain non-bayar harus bisa maju **dengan nyaman** (sabar), pemain bayar maju **lebih cepat** (bukan "pay-to-win mutlak", karena ini puzzle solo).
- Hindari inflasi koin (terlalu banyak koin → IAP tak menarik & booster tak bernilai).
- Pantau via analytics: rata-rata koin held, frekuensi pembelian booster, titik pemain "kehabisan".

---

## 8. Etika & Kepatuhan

- **Transparan.** Harga & isi paket jelas. Tidak ada dark pattern menyesatkan.
- **Loot box:** hindari mekanik gacha/loot box berbayar acak (regulasi makin ketat & reputasi). Kalau ada elemen acak, buat transparan & tidak berbayar langsung.
- **Anak-anak:** jika rating game mencakup anak, patuhi kebijakan iklan & data untuk anak (Families Policy). Pertimbangkan rating usia saat desain.
- **Tidak menipu:** rewarded ad harus benar-benar memberi reward yang dijanjikan.

---

## 9. Metrik Monetisasi (pantau pasca-rilis)

| Metrik | Arti |
|---|---|
| ARPDAU | Avg revenue per daily active user |
| Ad impressions/DAU | Seberapa sering iklan tampil |
| Rewarded engagement rate | % pemain pakai rewarded |
| IAP conversion rate | % pemain yang beli |
| Remove Ads take rate | % beli remove ads |

> Catatan: **jangan optimasi monetisasi sebelum retensi sehat.** Monetisasi di atas retensi buruk = sia-sia. Urutan: Fun → Retensi → baru Monetisasi.
