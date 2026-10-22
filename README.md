# Gaptex — Spicetify Desktop Extension

**Gaptex v0.1.0** adalah ekstensi **satu file** untuk Spotify Desktop via [Spicetify](https://spicetify.app/). Fitur yang dibuat: **AdBlock (best effort)** dan **Anti-Reshuffle (kunci pengaturan shuffle)**. Tidak ada APK Android, server, telemetry, request jaringan eksternal, atau dependency npm untuk pengguna.

> **Status: prototype, belum diuji pada instalasi Spotify Desktop nyata.** Kompatibilitas bergantung pada versi Spotify/Spicetify. Gaptex tidak menjamin seluruh iklan audio terblokir dan tidak membuka hak Premium. Mengunci toggle shuffle tidak sama dengan menjamin urutan antrean lagu, terutama bila antrean diatur server Spotify.

## Fungsi

| Fitur | Cara kerja | Batasan |
|---|---|---|
| AdBlock | Menonaktifkan ad managers yang tersedia, mencoba override flag ads lokal, dan menyembunyikan container iklan di UI | API internal Spotify dapat berubah; audio ads mungkin tetap muncul |
| Anti-Reshuffle | Menyimpan pilihan `Shuffle OFF/ON`, lalu mengembalikan toggle ke keadaan tersebut saat berubah | Tidak memaksa server Spotify memutar lagu sesuai urutan dan bukan fitur shuffle Fisher–Yates |

## Instalasi Windows (paling mudah)

Persyaratan: Spotify **Desktop**, [Spicetify CLI](https://spicetify.app/docs/getting-started/) terpasang, dan sudah berjalan setidaknya sekali.

1. Unduh GitHub Release ZIP atau **Code → Download ZIP** lalu ekstrak.
2. Buka PowerShell **di folder hasil ekstraksi**.
3. Jalankan:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

4. Buka atau buka ulang Spotify Desktop. Klik **menu profil** dan lihat tiga menu `Gaptex`.

> Skrip pemasang bersifat lokal: hanya menyalin `gaptex.js`, menambahkan konfigurasi Spicetify, lalu menjalankan `spicetify apply`. Periksa skrip sebelum mengeksekusi. Tidak perlu administrator dalam konfigurasi Windows standar.

Jika Spicetify belum ada, lihat [petunjuk resminya](https://spicetify.app/docs/getting-started/). Untuk instalasi awal di Windows, salah satu perintah resmi adalah:

```powershell
winget install Spicetify.Spicetify
```

**Tidak perlu Node.js bagi pengguna akhir.**

## Instalasi manual (Windows)

1. Salin `gaptex.js` ke `%appdata%\spicetify\Extensions\`.
2. Jalankan:

   ```powershell
   spicetify config extensions gaptex.js
   spicetify apply
   ```

**Linux / macOS:** simpan `gaptex.js` ke `~/.config/spicetify/Extensions/`, lalu jalankan dua perintah yang sama.

## Menggunakan Gaptex

Buka menu profil Spotify:

- **Gaptex · AdBlock**: nyalakan/matikan upaya filter iklan. Dalam beberapa versi, perlu restart Spotify agar semua manajer iklan kembali normal jika dimatikan.
- **Gaptex · Anti-Reshuffle**: nyalakan/matikan penguncian toggle shuffle.
- **Gaptex · Shuffle yang dikunci: OFF/ON**: pilih nilai yang ingin dipertahankan. Mode default `OFF`, untuk mengurangi *forced shuffle*. Untuk shuffle tetap aktif, pilih `ON`; pilihan ini **tidak** mengunci urutan playlist/queue tertentu.

Preferensi disimpan di `Spicetify.LocalStorage`. Untuk debugging: buka DevTools Spotify dengan `Ctrl+Shift+I` dan cari `[Gaptex]` pada console.

## Update / uninstall

- Untuk update: ganti file `gaptex.js` di folder Extensions dengan versi baru, lalu `spicetify apply`.
- Hapus via `powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1` dari folder proyek, atau manual:

  ```powershell
  spicetify config extensions gaptex.js-
  spicetify apply
  ```

  Lalu hapus `%appdata%\spicetify\Extensions\gaptex.js` jika masih ada.

## Pemecahan masalah

| Masalah | Solusi |
|---|---|
| `spicetify` tidak dikenali | Pasang CLI resmi, buka terminal baru, cek `spicetify -v` |
| Spotify tidak berubah | `spicetify backup apply` kemudian mulai ulang Spotify |
| Gaptex tidak ada di profil | Periksa lokasi file, `spicetify config`, dan console DevTools |
| Iklan audio masih muncul | API audio ad manager tidak tersedia/tidak efektif pada versi ini; lihat console `[Gaptex]`. Belum ada jaminan. |
| Lagu tidak berurutan | Anti-Reshuffle hanya mengunci *shuffle toggle*, bukan queue atau aturan streaming. |
| Mematikan AdBlock tetapi efek masih ada | Restart Spotify agar manajer iklan yang sempat dinonaktifkan dibuat ulang |

## Untuk pengembang / push GitHub

```bash
git init
git add .
git commit -m "Initial Gaptex extension"
git branch -M main
git remote add origin https://github.com/USERNAME/gaptex.git
git push -u origin main
```

Ganti `USERNAME` dan buat repositori kosong `gaptex` di GitHub terlebih dulu, atau gunakan `gh repo create gaptex --public --source=. --remote=origin --push` bila GitHub CLI telah login. **Jangan unggah file `cli-main.zip`** — repo ini adalah implementasi terpisah.

Pengujian kode lokal (opsional, memerlukan Node.js 18+):

```bash
npm run check
npm test
```

## Kredit dan lisensi

- Implementasi Gaptex **ditulis ulang** dengan merujuk konsep API dan dokumentasi publik dari [Spicetify](https://spicetify.app/docs/development/extensions/).
- Referensi konseptual fitur pemblokiran iklan: [Adblockify oleh ririxi](https://github.com/rxri/spicetify-extensions/tree/main/adblock) (MIT). **Kode Adblockify tidak disalin/bundel.**
- `cli-main.zip` yang diberikan pengguna merupakan proyek Spicetify CLI dengan lisensi LGPL-2.1; source CLI maupun `shuffle+.js` **tidak disalin** ke paket Gaptex. Konsep pengaturan toggle dibuat mandiri; jangan menganggap Gaptex sebagai fork resmi Spicetify.
- Kode baru Gaptex: [MIT License](LICENSE). Tidak terafiliasi dengan Spotify AB atau Spicetify.

Lihat [catatan teknis](docs/IMPLEMENTATION.md) untuk batasan dan rancangan pengujian kompatibilitas.
