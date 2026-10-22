# Gaptex

**Music your way. Shuffle under control.**

**Gaptex** adalah utilitas ringan untuk Spotify Desktop di Windows. Dua fiturnya adalah **AdBlock eksperimental** (penyaringan elemen iklan yang didukung) dan **Anti-Reshuffle** (menjaga pengaturan shuffle tetap ON atau OFF). Tidak memerlukan akun Gaptex, Node.js, atau server tambahan.

**Versi:** 0.1.6 · **Status:** Prototype · **Sistem:** Windows 10/11

> **Batasan:** AdBlock tidak menjamin pemblokiran iklan audio. Anti-Reshuffle hanya menjaga *status tombol shuffle*, bukan menjamin urutan queue atau membuka hak Premium. Fungsi dapat berubah setelah pembaruan Spotify.

## Instalasi langsung melalui PowerShell

Persyaratan: Spotify Desktop telah terpasang, sudah dibuka dan login setidaknya sekali. Pastikan instalasi Spotify kompatibel dengan komponen integrasi yang digunakan Gaptex.

1. Buka **Windows PowerShell** (umumnya **tanpa Run as administrator**).
2. Jalankan **satu perintah**:

   ```powershell
   irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
   ```

3. Installer akan **membersihkan tampilan PowerShell**, menampilkan **kucing ASCII** dan tulisan besar **EK INSTRUMENTATION** berwarna-warni, lalu memeriksa persyaratan dan mengaktifkan Gaptex.
4. Bila komponen integrasi desktop belum terpasang, installer meminta persetujuan dan mengarahkan ke informasi pihak ketiga. Spotify yang sedang berjalan akan ditutup otomatis saat pemasangan. **Simpan pekerjaan atau hentikan pemutaran terlebih dahulu.**
5. Setelah status berhasil, buka Spotify kembali, klik foto profil kanan atas, lalu cari menu yang diawali **Gaptex**.

Installer hanya menampilkan keberhasilan jika proses aktivasi selesai tanpa kesalahan yang terdeteksi. Jika gagal, pesan dan potongan log asli akan ditampilkan. Installer **tidak otomatis menghapus Spotify**, dan **meminta izin** sebelum langkah pemulihan backup yang dapat menimpa modifikasi lain.

**Keamanan:** perintah ini menjalankan skrip dari repository publik. Periksa [source installer](install-online.ps1) terlebih dahulu. Dependensi integrasi memiliki lisensi pihak ketiga: [informasi teknis dan hak cipta](docs/THIRD_PARTY_NOTICES.md).

## Instalasi offline (melalui ZIP)

Unduh ZIP rilis dari [Gaptex Releases](https://github.com/efendiyhy/gaptex/releases), ekstrak semuanya, buka PowerShell dalam folder hasil ekstrak, kemudian jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Fitur dan penggunaan

| Fitur | Fungsi | Batasan |
|---|---|---|
| AdBlock | Upaya mengurangi elemen iklan dan menonaktifkan pengelola iklan yang tersedia | Tidak menjamin audio ads terblokir |
| Anti-Reshuffle | Mempertahankan mode shuffle ON/OFF yang dipilih | Tidak mengunci urutan lagu pada server |
| Pengaturan lokal | Simpan status fitur di komputer | Tidak perlu akun Gaptex |

Di menu profil Spotify Desktop tersedia **Gaptex · AdBlock**, **Gaptex · Anti-Reshuffle**, dan **Gaptex · Shuffle yang dikunci: OFF/ON**.

## Update

Jalankan kembali instalasi PowerShell yang sama. Installer mengganti file Gaptex yang relevan dan menerapkan perubahan.

## Uninstall

Di folder paket Gaptex ZIP, jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Penghapusan hanya melepas Gaptex, tidak menghapus komponen integrasi yang mungkin digunakan aplikasi/ekstensi lain.

## Jika instalasi gagal

Installer **bukan** sekadar menampilkan pesan generik. Ia mencatat keluaran teknis asli, lalu mengidentifikasi beberapa masalah umum: backup lama, Spotify belum pernah login, akses folder yang tidak memadai, atau versi Spotify yang belum kompatibel.

### Jika muncul `Spotify cannot be backed up at this state`

Kondisi ini **tidak bisa diatasi dengan menutup Spotify atau mengulang `backup apply`**. Installer akan menghentikan percobaan otomatis dan menjelaskan langkah perbaikan:

1. Uninstall aplikasi **Spotify Desktop** melalui **Settings > Apps > Installed apps**. Jangan menghapus akun Spotify atau playlist.
2. Pasang versi Desktop resmi dari <https://www.spotify.com/download/windows/> (hindari versi Microsoft Store untuk kompatibilitas terbaik).
3. Buka Spotify, login, dan biarkan terbuka minimal **60 detik** agar file pengaturan dibuat.
4. Tutup Spotify, kemudian jalankan kembali installer Gaptex PowerShell. Jika masih bermasalah, jalankan `spicetify backup apply` secara manual untuk mendapatkan error yang lebih detail.

Penghapusan aplikasi Spotify bisa menyebabkan **lagu offline harus diunduh ulang**. Installer Gaptex tidak akan menghapus/menginstal ulang Spotify secara otomatis.

Baca log:

```powershell
Get-Content "$env:LOCALAPPDATA\Gaptex\logs\install.log" -Tail 60
```

Sebelum memposting log ke [GitHub Issues](https://github.com/efendiyhy/gaptex/issues), **hapus nama pengguna/path privat, token, atau data sensitif** yang mungkin tercantum. Untuk detail urutan perbaikan, lihat [dokumentasi troubleshooting](docs/TROUBLESHOOTING.md).

## Pengembangan

Source: <https://github.com/efendiyhy/gaptex>

```bash
npm run check
npm test
```

Node.js hanya diperlukan bagi pengembang untuk pengujian, bukan pengguna.

## Lisensi dan afiliasi

Kode Gaptex dilisensikan menggunakan **MIT License** (lihat [LICENSE](LICENSE)). Komponen integrasi pihak ketiga tetap mempunyai hak cipta serta lisensinya masing-masing, didokumentasikan pada [Third-party Notices](docs/THIRD_PARTY_NOTICES.md). Gaptex bukan produk resmi, disponsori, atau didukung Spotify. Penggunaan harus sesuai syarat layanan yang berlaku.
