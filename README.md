# Gaptex

**Musik lebih nyaman. Kendali shuffle lebih konsisten.**

**Gaptex** adalah ekstensi ringan untuk **Spotify Desktop** di Windows. Gaptex berfokus pada dua fungsi: **AdBlock** (penyaringan iklan dengan pendekatan *best effort*) dan **Anti-Reshuffle** (mempertahankan pilihan shuffle ON/OFF).

**Versi:** 0.1.3 · **Status:** Prototipe · **Lisensi kode Gaptex:** MIT

> Gaptex bukan Spotify Premium, tidak mengubah status akun, dan tidak menjamin seluruh iklan audio dapat diblokir. Anti-Reshuffle hanya mempertahankan status tombol shuffle, **bukan** urutan lagu di antrean.

## Fitur

| Fitur | Deskripsi |
|---|---|
| **AdBlock** | Berupaya mengurangi tampilan iklan dan menonaktifkan pengelola iklan yang didukung versi Spotify Desktop. |
| **Anti-Reshuffle** | Mengembalikan pilihan shuffle ke ON atau OFF saat berubah, sejauh didukung Spotify. |
| **Pengaturan tersimpan** | Preferensi disimpan secara lokal pada perangkat. |
| **Ringan** | Tidak memerlukan akun Gaptex, Node.js, atau server Gaptex. |

## Instalasi cepat di Windows

**Syarat:** Windows 10/11, Spotify Desktop sudah terpasang, pernah dibuka, dan telah login. Tutup Spotify sebelum instalasi.

1. Buka **PowerShell** (tidak perlu administrator pada konfigurasi normal).
2. Tempel perintah berikut:

   ```powershell
   irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
   ```

3. Jika diminta, setujui pemasangan komponen integrasi desktop yang diperlukan. Komponen pihak ketiga memiliki lisensi tersendiri; baca [pemberitahuan dependensi](docs/THIRD_PARTY_NOTICES.md).
4. Setelah muncul **Gaptex berhasil dipasang!**, buka kembali Spotify Desktop.
5. Klik **foto profil di kanan atas** dan cari menu yang diawali `Gaptex`.

> Perintah ini mengambil installer langsung dari repository publik `efendiyhy/gaptex`. [Periksa isi installer](install-online.ps1) sebelum menjalankan kode jarak jauh. Pengguna tidak perlu mengunduh ZIP atau memasang Git.

### Instalasi menggunakan ZIP

Unduh ZIP dari halaman [GitHub Releases](https://github.com/efendiyhy/gaptex/releases), ekstrak seluruhnya, lalu buka PowerShell di folder `Gaptex` dan jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Cara menggunakan

Klik **foto profil Spotify Desktop** di pojok kanan atas, lalu cari:

- **Gaptex · AdBlock:** nyalakan atau matikan penyaringan iklan.
- **Gaptex · Anti-Reshuffle:** aktifkan penguncian status shuffle.
- **Gaptex · Shuffle yang dikunci: OFF/ON:** pilih status yang ingin dipertahankan. Default: **OFF**.

Sebagian perubahan membutuhkan restart Spotify. Hasil dapat berbeda sesuai versi Spotify dan jenis akun.

## Update

Jalankan kembali perintah instalasi PowerShell:

```powershell
irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
```

Untuk proyek produksi, versi rilis yang ditetapkan lebih disarankan daripada selalu mengambil branch `main`.

## Uninstall

Jika menggunakan paket ZIP, buka folder Gaptex di PowerShell dan jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Uninstaller hanya menghapus Gaptex; komponen integrasi bersama tetap ada karena mungkin dipakai ekstensi lain.

## Jika tidak muncul setelah instalasi

1. Tutup Spotify sepenuhnya, kemudian buka kembali.
2. Jalankan kembali installer Gaptex, lalu cek pesan berhasil/gagal.
3. Jika muncul error, buka PowerShell dan lihat 40 baris terakhir log dengan perintah berikut:

   ```powershell
   Get-Content "$env:LOCALAPPDATA\Gaptex\logs\install.log" -Tail 40
   ```

   Installer v0.1.3 menangani pesan diagnostik dari komponen integrasi tanpa langsung berhenti ketika program menulis ke *stderr*. Jika aktivasi benar-benar gagal (exit code bukan 0), penyebabnya akan tercatat di log.
4. Laporkan masalah melalui [GitHub Issues](https://github.com/efendiyhy/gaptex/issues), sertakan versi Spotify dan ringkasan pesan error. Hapus informasi pribadi dari log sebelum membagikannya.

## FAQ

**Apakah Gaptex gratis?** Ya, source code Gaptex menggunakan lisensi MIT.

**Apakah Gaptex membuka fitur Premium?** Tidak. Gaptex tidak memberikan hak langganan berbayar.

**Apakah semua iklan audio hilang?** Tidak dijamin. Fitur AdBlock masih eksperimental.

**Apakah Anti-Reshuffle menjaga urutan playlist?** Tidak. Versi ini mengunci **status shuffle**, bukan seluruh antrean lagu.

**Apakah ada pengiriman data ke server Gaptex?** Tidak ada telemetri atau akun Gaptex pada ekstensi saat ini. Spotify Desktop dan komponen pendukung tetap dapat terhubung ke layanan mereka sendiri.

## Pengembangan, lisensi, dan ketentuan

Source: [github.com/efendiyhy/gaptex](https://github.com/efendiyhy/gaptex). Kode Gaptex menggunakan [MIT License](LICENSE); komponen pihak ketiga memiliki hak cipta dan lisensi terpisah yang dijelaskan dalam [THIRD_PARTY_NOTICES](docs/THIRD_PARTY_NOTICES.md).

Gaptex adalah proyek independen, tidak berafiliasi dengan atau didukung Spotify. Gunakan sesuai ketentuan layanan yang berlaku. Fitur dan kompatibilitas masih memerlukan pengujian langsung di berbagai versi Spotify Desktop.
