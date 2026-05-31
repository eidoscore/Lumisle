# 12 — Definition of Fun & Workflow Kolaborasi AI

> Dua hal yang sebelumnya implisit, sekarang dibikin eksplisit:
> (A) Kriteria OBJEKTIF untuk gate "buktikan fun" (Tahap 3) — biar bisa dievaluasi jujur, bukan perasaan.
> (B) Workflow kerja sama Dev (bisa coding, belum Godot) + AI agent — biar tiap modul punya "definition of done".

---

## BAGIAN A — DEFINITION OF FUN (Quality Gate)

### A.1 Kenapa ini ada
Seluruh roadmap bertumpu pada gate Tahap 3 ("buktikan fun sebelum bangun mesin konten"). Tapi "fun" itu subjektif. Dokumen ini bikin gate-nya **terukur** supaya keputusan lanjut/stop jujur, bukan bias optimisme.

### A.2 Gate Vertical Slice — kriteria LULUS (semua harus terpenuhi)

**Uji ke minimal 5 orang non-developer** (bukan teman dekat yang sungkan jujur). Tiap orang main tanpa dijelaskan. Catat hasilnya.

| # | Kriteria | Ambang LULUS | Cara ukur |
|---|---|---|---|
| F1 | **Paham tanpa diajari** | ≥4 dari 5 orang bisa main & menang level 1 tanpa bertanya | Observasi diam (jangan bantu) |
| F2 | **Tile terbaca** | ≥4 dari 5 bisa bedakan semua warna/bentuk tile dalam <1 detik | Tanya setelah main |
| F3 | **Mau main lagi** | ≥4 dari 5 lanjut ke level berikutnya tanpa disuruh, ATAU bilang "satu lagi" | Observasi |
| F4 | **Durasi spontan** | ≥3 dari 5 main ≥10 menit tanpa diminta | Stopwatch |
| F5 | **Kalah terasa fair** | 0 dari 5 bilang "kayak dicurangi" saat kalah | Tanya saat/setelah kalah |
| F6 | **Special terasa memuaskan** | ≥4 dari 5 bereaksi positif (senyum/"wah") saat trigger special/combo | Observasi |
| F7 | **Rating niat** | Rata-rata jawaban "seberapa mau main lagi (1-10)" ≥ 7 | Kuesioner 1 pertanyaan |
| F8 | **Performa low-end** | Jalan ≥30 FPS di HP termurah yang dites, tidak crash, tidak overheat dalam 10 menit | Profiler + perangkat fisik |

### A.3 Aturan gate
- **LULUS** = semua F1-F8 terpenuhi → lanjut ke Tahap 4 (bangun konten & generator).
- **GAGAL sebagian** = iterasi slice (juice, tutorial, balancing, art tile) lalu uji ulang. Boleh iterasi beberapa ronde.
- **GAGAL berulang (3+ ronde tetap di bawah ambang)** = berhenti & evaluasi ulang fundamental (mungkin core loop / art / target salah). JANGAN lanjut bangun generator di atas core yang gagal gate.

### A.4 Catatan kejujuran
- Cari tester yang **berani jujur** (kenalan jauh, komunitas, bukan keluarga inti yang sungkan).
- Rekam (izin dulu) sesi main — bahasa tubuh sering lebih jujur dari ucapan.
- Bias terbesar solo dev: jatuh cinta sama proyek sendiri. Gate ini penangkalnya. Hormati angkanya.

### A.5 Mini-gate di tahap lain (ringkas)
- **Setelah Tahap 2 (juice):** apakah memicu special terasa enak menurut LU sendiri? (gate internal cepat, sebelum repot uji orang)
- **Setelah Tahap 5 (generator):** distribusi win-rate per-band masuk akal + near-miss rate sehat? (gate data, lihat dok 05 §5.4)
- **Setelah Tahap 7 (FTUE):** uji 5 orang baru — apakah kurikulum mulus, ada "alasan balik"?
- **Soft launch (Tahap 8):** metric gate D1≥40%, D7≥15% (lihat dok 02 §6 & dok 08 Tahap 9).

---

## BAGIAN B — WORKFLOW KOLABORASI AI + DEV

### B.1 Profil developer (penting untuk cara kerja)
- **Bisa coding** (paham logika, algoritma, struktur program) — bisa me-review & memverifikasi logika kerjaan AI.
- **Belum kenal Godot/GDScript** — perlu belajar sintaks GDScript + paradigma Godot (Node/Scene/Signal/Resource). GDScript mirip Python → kurva rendah, ~1-2 minggu sambil jalan.
- **Implikasi:** AI menulis kode, tapi **Dev wajib bisa membaca & menyetujui** tiap modul. Bukan "terima jadi buta". Ini pengaman kualitas utama.

### B.2 Pembagian peran
| Peran | Siapa |
|---|---|
| Implementasi kode (GDScript), arsitektur, generator/solver, debugging | AI agent |
| Review logika & arsitektur, setujui/tolak tiap modul, playtest "rasa", keputusan desain, tuning angka, kurasi art/audio, akun/rilis/legal | Dev (lu) |
| Menjelaskan konsep Godot/GDScript yang belum lu kenal saat muncul | AI agent |

### B.3 Cara kerja per modul (definition of done)
Tiap modul (mis. `match_detector.gd`, `board.gd`, satu rintangan) dianggap **SELESAI** jika:
1. ✅ Kode ditulis AI + diberi komentar "kenapa" pada bagian non-trivial.
2. ✅ Ada **unit test (GUT)** yang lulus untuk logika inti modul itu.
3. ✅ Lu **baca & paham** kode-nya (AI jelaskan bagian Godot-spesifik kalau perlu).
4. ✅ Tidak ada error diagnostik (compile/type).
5. ✅ Untuk modul logika: bisa dijalankan headless (tanpa scene) — buktikan via test.
6. ✅ Lu setujui ("ini sesuai maksud") ATAU minta revisi.

> Prinsip: **logika dulu + test, baru view.** Core yang sudah lulus test baru dibungkus animasi. Memudahkan lu verifikasi tanpa harus paham rendering Godot.

### B.4 Ritme kerja yang disarankan
- **Potongan kecil:** satu modul / satu fitur per siklus, jangan "semua sekaligus".
- **Test-backed:** logika selalu disertai test → lu bisa percaya tanpa baca tiap baris.
- **Checkpoint visual:** setelah modul logika lulus test, AI bikin demo kecil yang bisa lu jalankan & rasakan.
- **Git commit per modul** (saat lu minta) → mudah revert kalau salah arah.

### B.5 Yang TIDAK boleh
- AI ambil keputusan desain besar tanpa lu (warna, mekanik, ekonomi).
- Merge kode yang belum ada test untuk logika kritikal.
- "Percaya buta" — lu tetap baca & paham, sekecil apa pun.

### B.6 Belajar Godot sambil jalan (rencana ringan untuk Dev)
- Tahap 0-1: kenali Node, Scene, Signal, `_ready`/`_process`, Resource. (AI jelaskan saat muncul di kode kita.)
- Fokus baca: `board.gd` (logika murni, paling mirip coding biasa) → paling gampang buat lu verifikasi.
- Sintaks GDScript: anggap "Python dengan tipe statis opsional". Tidak perlu kursus formal; belajar dari kode proyek sendiri.

---

## Ringkasan
- **Definition of Fun (A)** = rem darurat objektif sebelum investasi besar di konten.
- **Workflow (B)** = manfaatkan kemampuan coding lu sebagai pengaman kualitas; AI cepat menulis, lu yang menyetujui.
