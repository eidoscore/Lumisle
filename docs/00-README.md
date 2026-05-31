# Master Documentation — Lumisle

> Game match-3 hybrid-casual untuk Android, dikembangkan solo developer dibantu AI agent, engine Godot 4.6.3.
> Folder ini adalah "single source of truth" untuk seluruh perencanaan development.
> Status: **PLANNING** · Disusun: 31 Mei 2026 · Bahasa: Indonesia (casual).

---

## Apa ini?

Ini kumpulan dokumen perencanaan lengkap sebelum nulis kode produksi. Tujuannya supaya:
- Konsep & scope terkunci (gak melebar liar / over-scope).
- AI agent punya acuan jelas saat ngoding tiap bagian.
- Lu (sebagai game director) bisa ambil keputusan berbasis dokumen, bukan feeling.

Dokumen riset pasar & dekonstruksi Royal Match ada di folder `../../docs/` (root workspace). Folder `Lumisle/docs/` ini fokus ke **eksekusi**: apa yang dibangun, gimana, dan kapan.

---

## Peta Dokumen (urutan baca disarankan)

| # | Dokumen | Isi singkat | Untuk siapa |
|---|---|---|---|
| 00 | **README** (ini) | Navigasi & ringkasan | Semua |
| 01 | [Masterplan & Visi](01-masterplan-visi.md) | North star, tujuan, prinsip, strategi besar | Lu (director) |
| 02 | [PRD](02-prd.md) | Product requirements: fitur, scope, success metrics | Lu + AI |
| 03 | [GDD](03-gdd.md) | Game design detail: core loop, mekanik, item, meta | Lu + AI |
| 04 | [Technical Design (TDD)](04-tdd-arsitektur.md) | Arsitektur Godot, skema data, struktur kode | AI (utama) |
| 05 | [Sistem Level: Generator + Solver](05-sistem-level-generator-solver.md) | Cara produksi & validasi ribuan level | AI (utama) |
| 06 | [Ekonomi & Monetisasi](06-ekonomi-monetisasi.md) | Koin, nyawa, booster, iklan, IAP | Lu + AI |
| 07 | [Art & Audio Direction](07-art-audio-direction.md) | Gaya visual, daftar aset, sumber aset | Lu (utama) |
| 08 | [Roadmap & Milestone](08-roadmap-milestone.md) | Fase development, MVP, timeline | Lu + AI |
| 09 | [Tech Stack & Tooling](09-tech-stack-tooling.md) | Engine, plugin, analytics, build pipeline | AI (utama) |
| 10 | [Publishing & Go-to-Market](10-publishing-gtm.md) | Play Console, ASO, rilis, kepatuhan | Lu (utama) |
| 11 | [Risiko, Asumsi & Keputusan Terbuka](11-risiko-asumsi-keputusan.md) | Risiko + daftar keputusan yang nunggu lu | Lu (director) |
| 12 | [Definition of Fun & Workflow AI](12-definition-of-fun-dan-workflow.md) | Kriteria gate "fun" terukur + cara kerja Dev+AI | Lu + AI |
| 13 | [Implementation Plan](13-implementation-plan.md) | Breakdown task per fase (peta kerja koding) | Lu + AI |
| 14 | [Ruleset Spec](14-ruleset-spec.md) | Kontrak resolusi board otoritatif (urutan, special, combo, scoring) | AI (utama) + Lu |
| — | [REVIEW-PROMPT](REVIEW-PROMPT.md) | Prompt minta review AI lain — **produk/desain/bisnis** | Lu |
| — | [TECH-REVIEW-PROMPT](TECH-REVIEW-PROMPT.md) | Prompt minta review AI lain — **teknis/arsitektur/engineering** | Lu + AI |

> **Catatan revisi:** Dokumen ini sudah melalui **3 review eksternal independen** (Qwen, GPT-5.5, DeepSeek). Temuan yang konvergen sudah diterapkan: vertical-slice-first, win-rate per-band, ensemble solver, FTUE kurikulum, tile CC0 konsisten, timeline ~8 bulan. Jejak di dok 11 (log keputusan, ditandai `[REVIEW]`/`[3-REVIEW]`).

---

## Status Proyek Saat Ini

- ✅ Riset pasar selesai (`docs/01`)
- ✅ Dekonstruksi Royal Match selesai (`docs/02`)
- ✅ Godot 4.6.3 terpasang & siap (PATH + shortcut)
- ✅ Master documentation set (folder ini)
- ✅ Keputusan desain final dikunci (dok 11) — nama: **Lumisle**
- ⬜ Scaffold project Godot + prototipe Tahap 1

---

## Ringkasan Konsep (1 paragraf)

**Lumisle** adalah game puzzle **match-3** (geser-3) bergaya hybrid-casual: core puzzle yang simpel & memuaskan (special items + combo + juice), dibungkus lapisan meta **koleksi "Lumi" (roh cahaya)** — kumpulkan makhluk cahaya untuk menghidupkan kembali pulau yang meredup — supaya gak bosen. Monetisasi lewat iklan (rewarded + interstitial) + IAP "remove ads". Skala konten dicapai lewat **generator template-based + solver bot** (sebagai drafting tool, dikurasi manual), bukan desain manual murni. Target rilis: Google Play, soft launch pasar kecil → Indonesia/SEA.

> **Nama final:** Lumisle (lumen + isle). Tema: pulau fiksi imajinatif. Pembeda: hook koleksi + polish (bukan art prosedural). Dokumen sudah direvisi setelah review eksternal (lihat dok 11 §3 & §5). Detail keputusan di dok 11.

---

## Aturan Pakai Dokumen

1. Dokumen ini **hidup** — diupdate saat keputusan berubah. Jangan diperlakukan sebagai batu.
2. Kalau ada konflik antar dokumen, **PRD (02) & GDD (03) menang** untuk hal desain; **TDD (04) menang** untuk hal teknis.
3. Setiap keputusan besar yang diambil, catat di dok 11 (Keputusan Terbuka) biar ada jejak.
