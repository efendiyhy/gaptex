# Gaptex

**Musik lebih nyaman. Shuffle lebih terkendali.**

**Gaptex** adalah ekstensi ringan untuk **Spotify Desktop** yang membantu menghadirkan pengalaman mendengarkan musik lebih nyaman melalui dua fitur utama: **AdBlock** dan **Anti-Reshuffle**. Gaptex dirancang sederhana, tanpa akun tambahan, tanpa langganan, dan tanpa konfigurasi yang rumit.

> **Versi:** 0.1.0 (prototipe) · **Platform utama:** Windows · **Lisensi:** MIT
>
> Gaptex masih dalam tahap pengujian. Efektivitas fitur dapat berbeda tergantung versi Spotify. Gaptex tidak memberikan akses Premium dan tidak menjamin semua iklan audio dapat diblokir.

## Fitur

| Fitur | Manfaat | Perlu diketahui |
|---|---|---|
| **AdBlock** | Berupaya mengurangi gangguan iklan dan menyembunyikan elemen iklan pada tampilan Spotify. | Penyaringan bersifat *best effort*. Sebagian iklan, khususnya iklan audio, mungkin tetap muncul. |
| **Anti-Reshuffle** | Mempertahankan pilihan mode shuffle **ON** atau **OFF** ketika statusnya berubah. | Mengunci tombol shuffle **bukan** berarti mengunci urutan playlist atau antrean lagu yang dikendalikan Spotify. |

### Keunggulan Gaptex

- **Ringan:** fitur inti berada dalam satu file ekstensi, `gaptex.js`.
- **Praktis:** pemasangan melalui installer PowerShell untuk Windows.
- **Tanpa akun baru:** gunakan akun Spotify Anda seperti biasa.
- **Privasi:** pengaturan Gaptex tersimpan secara lokal; ekstensi ini tidak mengirim telemetri ke server Gaptex.
- **Open source:** source code tersedia untuk dipelajari dan dikembangkan.

## Instalasi langsung di PowerShell (Windows)

**Persyaratan:** Spotify Desktop sudah terpasang dan sudah pernah dibuka/login (disarankan selama 60 detik untuk pemasangan pertama). Setelah itu, tutup Spotify.

1. Buka **PowerShell** di Windows, tanpa perlu hak administrator pada konfigurasi standar.
2. Salin dan jalankan **satu perintah** berikut:

   ```powershell
   irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
   ```

3. Jika komponen integrasi Spotify Desktop belum terpasang, installer meminta **izin** untuk memasangnya menggunakan Windows Package Manager (`winget`).
4. Setelah selesai, buka kembali Spotify Desktop dan akses pengaturan **Gaptex** lewat menu profil.

> Installer mengunduh `gaptex.js` langsung dari repository resmi, lalu memasangnya ke profil Windows pengguna. Gaptex **masih bergantung pada Spicetify CLI sebagai komponen teknis pihak ketiga**, yang dipasang hanya dengan persetujuan pengguna. Pengguna tidak perlu memasang Git atau Node.js. Periksa isi [skrip instalasi online](install-online.ps1) sebelum mengeksekusi kode dari internet.

**Alternatif tanpa menjalankan skrip jarak jauh:** unduh repository sebagai ZIP, ekstrak, lalu buka PowerShell di folder yang memuat `install.ps1` dan jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

> **Penting:** URL instalasi satu perintah mulai berfungsi **setelah `install-online.ps1` dan `gaptex.js` dipush ke branch `main` di GitHub**. Jika repository belum tersedia atau masih privat, pengguna akan mendapatkan error HTTP 404 atau 403.

## Cara menggunakan

Setelah Gaptex aktif, buka menu profil Spotify Desktop dan pilih:

- **Gaptex · AdBlock:** aktifkan/nonaktifkan upaya penyaringan iklan.
- **Gaptex · Anti-Reshuffle:** aktifkan/nonaktifkan penguncian status shuffle.
- **Gaptex · Shuffle yang dikunci: OFF/ON:** pilih apakah shuffle harus dipertahankan dalam keadaan mati atau menyala. Nilai awalnya **OFF**.

Pengaturan akan disimpan secara lokal. Sebagian perubahan mungkin memerlukan restart Spotify.

## Cara update

Jalankan kembali perintah satu baris di PowerShell:

```powershell
irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
```

Installer mengambil versi terkini dari branch `main`. Untuk hasil yang lebih stabil, distribusikan versi rilis dengan tag tetap.

## Cara uninstall

Buka PowerShell pada folder Gaptex dan jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Skrip menghapus ekstensi Gaptex dari konfigurasi Spotify Desktop dan menghapus file ekstensi lokalnya. **Komponen pendukung pihak ketiga tidak ikut dihapus**, karena mungkin digunakan ekstensi lain.

## Tanya jawab

**Apakah Gaptex gratis?**  
Ya. Gaptex merupakan proyek open-source dengan lisensi MIT.

**Apakah Gaptex mengaktifkan Spotify Premium?**  
Tidak. Gaptex tidak mengubah status langganan atau hak akses akun Anda.

**Apakah semua iklan pasti hilang?**  
Tidak. AdBlock beroperasi dengan pendekatan *best effort* dan mungkin tidak berfungsi pada semua versi Spotify.

**Apakah Anti-Reshuffle membuat antrean lagu tidak pernah berubah?**  
Tidak. Fitur ini mempertahankan **status shuffle ON/OFF**, bukan menyimpan atau memaksakan urutan antrean lagu tertentu.

**Mengapa Gaptex tidak muncul?**  
Pastikan installer selesai tanpa error, tutup lalu buka ulang Spotify, dan coba jalankan installer lagi. Jika instalasi komponen pendukung gagal, periksa apakah `winget` tersedia di PowerShell dan koneksi internet aktif.

**Mengapa installer gagal saat pemasangan pertama?**  
Pastikan Spotify Desktop sudah pernah dibuka dan Anda sudah login. Pada beberapa sistem, pembaruan Spotify atau perubahan API aplikasi dapat menyebabkan kegagalan kompatibilitas.

## Untuk pengembang

Kode sumber berada di [github.com/efendiyhy/gaptex](https://github.com/efendiyhy/gaptex). Pengujian kode lokal (opsional) memerlukan Node.js 18+:

```bash
npm run check
npm test
```

## Lisensi dan disclaimer

Gaptex didistribusikan dengan **[MIT License](LICENSE)** dan merupakan proyek independen yang **tidak berafiliasi dengan Spotify**. Spotify adalah merek dagang milik pemiliknya masing-masing. Penggunaan ekstensi sepenuhnya menjadi tanggung jawab pengguna dan harus mematuhi ketentuan layanan yang berlaku.

Untuk rincian arsitektur dan batasan implementasi, lihat [catatan teknis](docs/IMPLEMENTATION.md).
