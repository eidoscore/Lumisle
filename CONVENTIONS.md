# Konvensi Kode — Lumisle

> Acuan: docs/04-tdd-arsitektur.md §11. Dipatuhi semua file GDScript.

## Penamaan
- `snake_case` untuk variabel, fungsi, file, folder.
- `PascalCase` untuk `class_name` dan tipe.
- `SCREAMING_SNAKE_CASE` untuk konstanta & enum value.
- Prefix `_` untuk fungsi/var privat (mis. `_validate_board_state`).

## Tipe
- **Static typing wajib** sebisa mungkin: `var x: int`, `func f(a: int) -> bool:`.
- Game state pakai **int** (warna, skor, posisi grid). Float HANYA untuk visual (posisi tween). Lihat dok 14 §6.
- Index `PackedInt32Array` simpan ke local var dulu: `var i := y * width + x` (lebih cepat).

## Arsitektur
- `core/` = logika murni: `extends RefCounted`, **TIDAK** `extends Node`, tanpa `get_tree()`, tanpa signal untuk cascade. Lihat dok 04 §3.
- `view/` = Node-based, hanya presentasi. Baca `TurnReport`, tidak memodifikasi state core kecuali via `resolve_swap()`.
- Randomness HANYA lewat `GameRNG` berseed. JANGAN `randi()`/`randf()` global.
- Satu file = satu tanggung jawab jelas.

## Komentar
- Fokus ke **"kenapa"**, bukan "apa". Kode yang jelas tidak butuh komentar "apa".
- Header tiap file: 1-2 baris tujuan + rujukan dok terkait.

## Signal vs TurnReport
- Cascade/resolusi board: pakai **TurnReport** (dok 14 §0.1), BUKAN signal.
- Signal hanya untuk komunikasi logic→view tingkat tinggi (mis. "level selesai").
- Signal yang membawa Array/Dictionary → kirim `.duplicate()` (pass-by-reference trap).

## Tween (view)
- Selalu simpan ref tween, `kill()` sebelum buat baru + di `_exit_tree()` (cegah leak/crash).

## i18n
- Format: CSV (`i18n/strings.en.csv`, `i18n/strings.id.csv`) via `TranslationServer`.
- Key: `snake_case` deskriptif, mis. `hud_moves_left`, `popup_win_title`.
- Default/fallback: EN.

## Test
- Core logic WAJIB unit test (GUT). View = manual test. Lihat dok 13 "Target Test Coverage".
- Tiap bug ditemukan → tambah test regresi.
- Golden fixtures (`tests/fixtures/`) = living artifact, update tiap aturan/fitur baru.

## Autoload
- Yang tak butuh frame update → `set_process(false)` di `_ready()` (overhead kumulatif low-end).
